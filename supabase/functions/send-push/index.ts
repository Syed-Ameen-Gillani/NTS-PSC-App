import { createClient } from 'npm:@supabase/supabase-js@2'
import { GoogleAuth } from 'npm:google-auth-library@9'

type PushJob = {
  id: string
  user_id: string
  notification_id: string | null
  title: string
  body: string
  event_type: string | null
  category: string | null
  route: string | null
  resource_id: string | null
  course_id: string | null
  expires_at: string | null
  dedupe_key: string | null
  attempts: number
}

type Device = { token: string; platform: 'android' | 'ios' }

const json = (message: string, status: number) =>
  Response.json({ message }, { status })

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json('Method not allowed', 405)
  const workerSecret = Deno.env.get('NOTIFICATION_WORKER_SECRET')
  if (!workerSecret || req.headers.get('authorization') !== `Bearer ${workerSecret}`) {
    return json('Unauthorized', 401)
  }
  const serviceAccount = readServiceAccount()
  if (!serviceAccount) return json('FCM is not configured', 503)

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
  try {
    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    const accessToken = await auth.getAccessToken()
    if (!accessToken) throw new Error('FCM access token unavailable')
    const { data, error } = await db.rpc('claim_push_batch')
    if (error) throw error
    const jobs = (data ?? []) as PushJob[]
    let sent = 0
    for (const job of jobs) {
      const result = await deliverJob(db, serviceAccount.project_id, accessToken, job)
      sent += result.sent
      const status = result.retry
        ? job.attempts >= 5 ? 'failed' : 'pending'
        : result.delivered ? 'sent' : 'skipped'
      const delaySeconds = Math.min(3600, 30 * 2 ** job.attempts)
      const { error: saveError } = await db.from('push_outbox').update({
        status,
        available_at: new Date(Date.now() + delaySeconds * 1000).toISOString(),
      }).eq('id', job.id).eq('attempts', job.attempts)
      if (saveError) throw saveError
    }
    return Response.json({ processed: jobs.length, sent })
  } catch (error) {
    console.error('Push worker failed', error instanceof Error ? error.message : 'unknown')
    return json('Notification worker failed; leased jobs can be retried', 502)
  }
})

async function deliverJob(
  db: ReturnType<typeof createClient>,
  projectId: string,
  accessToken: string,
  job: PushJob,
) {
  if (!job.notification_id || !job.event_type || !job.category || !job.route) {
    return { sent: 0, delivered: false, retry: false }
  }
  const { data: allowed, error: allowedError } = await db.rpc(
    'notification_delivery_allowed',
    { p_notification_id: job.notification_id },
  )
  if (allowedError) return { sent: 0, delivered: false, retry: true }
  if (!allowed) return { sent: 0, delivered: false, retry: false }

  const { data: devices, error: deviceError } = await db.from('push_devices')
    .select('token,platform').eq('user_id', job.user_id)
  if (deviceError) return { sent: 0, delivered: false, retry: true }
  const { count: unreadCount } = await db.from('app_notifications')
    .select('id', { count: 'exact', head: true }).eq('user_id', job.user_id)
    .is('read_at', null).lte('available_at', new Date().toISOString())

  let sent = 0
  let retry = false
  for (const device of (devices ?? []) as Device[]) {
    const { data: receipt } = await db.from('push_delivery_receipts')
      .select('outbox_id').eq('outbox_id', job.id).eq('token', device.token)
      .maybeSingle()
    if (receipt) continue
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/messages:send`,
      {
        method: 'POST',
        signal: AbortSignal.timeout(15000),
        headers: {
          authorization: `Bearer ${accessToken}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          message: buildMessage(job, device, unreadCount ?? 0),
        }),
      },
    )
    if (response.ok) {
      const { error: receiptError } = await db.from('push_delivery_receipts').insert({
        outbox_id: job.id,
        token: device.token,
      })
      if (receiptError && receiptError.code !== '23505') retry = true
      else sent++
      continue
    }
    const failure = await response.json().catch(() => ({}))
    const errorCode = failure.error?.details?.find(
      (detail: { errorCode?: string }) => detail.errorCode,
    )?.errorCode
    if (errorCode === 'UNREGISTERED' || errorCode === 'SENDER_ID_MISMATCH') {
      await db.from('push_devices').delete()
        .eq('token', device.token).eq('user_id', job.user_id)
    } else {
      retry = true
    }
  }
  return { sent, delivered: sent > 0, retry }
}

function buildMessage(job: PushJob, device: Device, unreadCount: number) {
  const data: Record<string, string> = {
    event_id: job.notification_id!,
    type: job.event_type!,
    route: job.route!,
    payload_version: '1',
  }
  if (job.resource_id) data.resource_id = job.resource_id
  if (job.course_id) data.course_id = job.course_id
  if (job.expires_at) data.expires_at = job.expires_at
  const quiet = job.category === 'promotions'
  const collapseId = job.dedupe_key ?? job.notification_id!
  return {
    token: device.token,
    notification: { title: job.title, body: job.body },
    data,
    android: {
      priority: quiet ? 'NORMAL' : 'HIGH',
      collapse_key: collapseId,
      ttl: ttl(job.expires_at),
      notification: {
        channel_id: quiet ? 'quiet_updates' : 'learning_updates',
        tag: collapseId,
        visibility: 'PRIVATE',
        notification_priority: quiet ? 'PRIORITY_DEFAULT' : 'PRIORITY_HIGH',
      },
    },
    apns: {
      headers: {
        'apns-push-type': 'alert',
        'apns-priority': quiet ? '5' : '10',
        'apns-collapse-id': collapseId.slice(0, 64),
        ...(job.expires_at
          ? { 'apns-expiration': `${Math.floor(new Date(job.expires_at).getTime() / 1000)}` }
          : {}),
      },
      payload: {
        aps: {
          sound: quiet ? undefined : 'default',
          badge: Math.min(unreadCount, 99),
          'thread-id': groupFor(job.event_type!),
        },
      },
    },
  }
}

function ttl(expiresAt: string | null) {
  if (!expiresAt) return '604800s'
  const seconds = Math.max(
    0,
    Math.floor((new Date(expiresAt).getTime() - Date.now()) / 1000),
  )
  return `${Math.min(seconds, 2419200)}s`
}

function groupFor(type: string) {
  if (type.startsWith('live_class_')) return 'live_classes'
  if (type.startsWith('assignment_')) return 'assignments'
  if (type.startsWith('quiz_')) return 'quizzes'
  if (['discussion_reply', 'direct_feedback', 'study_nudge'].includes(type)) {
    return 'messages'
  }
  return 'course_updates'
}

function readServiceAccount() {
  const raw = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')
  if (!raw) return null
  try {
    const credentials = JSON.parse(raw)
    if (!credentials.project_id || !credentials.client_email || !credentials.private_key) {
      return null
    }
    return credentials
  } catch {
    return null
  }
}

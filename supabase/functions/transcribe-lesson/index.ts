import { withSupabase } from 'npm:@supabase/server@1'
import { createClient } from 'npm:@supabase/supabase-js@2'

export default {
  fetch: withSupabase({ auth: 'user' }, async (req, ctx) => {
    if (req.method !== 'POST') return Response.json({ message: 'Method not allowed' }, { status: 405 })
    const key = Deno.env.get('DEEPGRAM_API_KEY')
    const callbackSecret = Deno.env.get('DEEPGRAM_CALLBACK_SECRET')
    if (!key || !callbackSecret) {
      return Response.json({ message: 'Urdu transcription is not configured' }, { status: 503 })
    }
    const input = await req.json().catch(() => null)
    const mediaId = input?.mediaId
    if (typeof mediaId !== 'string' || !/^[0-9a-f-]{36}$/.test(mediaId)) {
      return Response.json({ message: 'Invalid media ID' }, { status: 400 })
    }
    const { data: user } = await ctx.supabase.auth.getUser()
    if (!user.user) return Response.json({ message: 'Sign in required' }, { status: 401 })
    const { data: media } = await ctx.supabase.from('lesson_media')
      .select('id, teacher_id, object_path, status, provider_request_id')
      .eq('id', mediaId).maybeSingle()
    if (!media || media.teacher_id !== user.user.id ||
        !['transcribing', 'failed'].includes(media.status) || media.provider_request_id) {
      return Response.json({ message: 'Media is not ready for transcription' }, { status: 409 })
    }
    const projectUrl = Deno.env.get('SUPABASE_URL')!
    const service = createClient(projectUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
    const { data: signed, error: signedError } = await service.storage
      .from('lesson-videos').createSignedUrl(media.object_path, 21600)
    if (signedError || !signed) {
      return Response.json({ message: 'Video is unavailable' }, { status: 409 })
    }
    const callback = new URL(`${projectUrl}/functions/v1/lesson-transcript-callback`)
    callback.username = 'deepgram'
    callback.password = callbackSecret
    callback.searchParams.set('mediaId', mediaId)
    const providerUrl = new URL('https://api.deepgram.com/v1/listen')
    providerUrl.searchParams.set('model', 'nova-3')
    providerUrl.searchParams.set('language', 'ur')
    providerUrl.searchParams.set('smart_format', 'true')
    providerUrl.searchParams.set('callback', callback.toString())
    try {
      const result = await fetch(providerUrl, {
        method: 'POST',
        headers: { Authorization: `Token ${key}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ url: signed.signedUrl }),
      })
      if (!result.ok) throw new Error(`Provider status ${result.status}`)
      const body = await result.json()
      if (typeof body.request_id !== 'string') throw new Error('Missing request ID')
      await service.from('lesson_media').update({
        status: 'transcribing', provider_request_id: body.request_id,
        processing_error: null,
      }).eq('id', mediaId).in('status', ['transcribing', 'failed'])
      return Response.json({ status: 'transcribing' }, { status: 202 })
    } catch {
      await service.from('lesson_media').update({
        status: 'failed', processing_error: 'Provider request failed',
      }).eq('id', mediaId).is('provider_request_id', null)
      return Response.json({ message: 'Transcription request failed' }, { status: 502 })
    }
  }),
}

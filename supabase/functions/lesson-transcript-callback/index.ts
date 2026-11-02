import { createClient } from 'npm:@supabase/supabase-js@2'

type Word = { start?: number; end?: number; punctuated_word?: string; word?: string }

function segmentsFromWords(words: Word[]): Array<{ start: number; end: number; text: string }> {
  const segments: Array<{ start: number; end: number; text: string }> = []
  let batch: Word[] = []
  for (const word of words) {
    if (!Number.isFinite(word.start) || !Number.isFinite(word.end) ||
        !word.word || (word.end as number) <= (word.start as number)) continue
    batch.push(word)
    if ((word.end as number) - (batch[0].start as number) >= 8 || batch.length >= 30) {
      segments.push({ start: batch[0].start!, end: word.end!,
        text: batch.map((item) => item.punctuated_word || item.word).join(' ') })
      batch = []
    }
  }
  if (batch.length) segments.push({ start: batch[0].start!, end: batch.at(-1)!.end!,
    text: batch.map((item) => item.punctuated_word || item.word).join(' ') })
  return segments
}

export default {
  async fetch(req: Request) {
    const expected = Deno.env.get('DEEPGRAM_CALLBACK_SECRET')
    const auth = req.headers.get('authorization')
    if (!expected || !auth || auth !== `Basic ${btoa(`deepgram:${expected}`)}`) {
      return Response.json({ message: 'Unauthorized' }, { status: 401 })
    }
    if (req.method !== 'POST') return Response.json({ message: 'Method not allowed' }, { status: 405 })
    const mediaId = new URL(req.url).searchParams.get('mediaId')
    if (!mediaId || !/^[0-9a-f-]{36}$/.test(mediaId)) {
      return Response.json({ message: 'Invalid media ID' }, { status: 400 })
    }
    const body = await req.json().catch(() => null)
    const requestId = body?.metadata?.request_id
    const service = createClient(Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
    const { data: media } = await service.from('lesson_media')
      .select('status, provider_request_id').eq('id', mediaId).maybeSingle()
    if (!media || media.provider_request_id !== requestId) {
      return Response.json({ message: 'Unknown job' }, { status: 404 })
    }
    if (media.status !== 'transcribing') return Response.json({ status: media.status })
    const words = body?.results?.channels?.[0]?.alternatives?.[0]?.words
    const segments = Array.isArray(words) ? segmentsFromWords(words) : []
    await service.from('lesson_media').update(segments.length ? {
      status: 'needs_review', transcript_language: 'ur',
      transcript_segments: segments, processing_error: null,
      duration_seconds: body?.metadata?.duration ?? null,
    } : {
      status: 'failed', processing_error: 'No speech detected; add a transcript manually',
    }).eq('id', mediaId).eq('status', 'transcribing')
    return Response.json({ status: segments.length ? 'needs_review' : 'failed' })
  },
}

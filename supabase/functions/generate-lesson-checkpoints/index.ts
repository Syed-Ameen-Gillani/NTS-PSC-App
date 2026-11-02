import { withSupabase } from 'npm:@supabase/server@1'
import { createClient } from 'npm:@supabase/supabase-js@2'

const schema = {
  type: 'object', additionalProperties: false, required: ['questions'],
  properties: { questions: { type: 'array', items: {
    type: 'object', additionalProperties: false,
    required: ['source_index', 'question', 'options', 'correct_index', 'explanation'],
    properties: {
      source_index: { type: 'integer' }, question: { type: 'string' },
      options: { type: 'array', items: { type: 'string' } },
      correct_index: { type: 'integer' }, explanation: { type: 'string' },
    },
  } } },
}

type Segment = { start: number; end: number; text: string }
type Question = { source_index: number; question: string; options: string[];
  correct_index: number; explanation: string }

export default {
  fetch: withSupabase({ auth: 'user' }, async (req, ctx) => {
    if (req.method !== 'POST') return Response.json({ message: 'Method not allowed' }, { status: 405 })
    const key = Deno.env.get('GEMINI_API_KEY')
    if (!key) return Response.json({ message: 'AI is not configured' }, { status: 503 })
    const input = await req.json().catch(() => null)
    const mediaId = input?.mediaId
    if (typeof mediaId !== 'string' || !/^[0-9a-f-]{36}$/.test(mediaId)) {
      return Response.json({ message: 'Invalid media ID' }, { status: 400 })
    }
    const { data: user } = await ctx.supabase.auth.getUser()
    if (!user.user) return Response.json({ message: 'Sign in required' }, { status: 401 })
    const { data: media } = await ctx.supabase.from('lesson_media')
      .select('teacher_id, status, lesson_id, transcript_segments, duration_seconds')
      .eq('id', mediaId).maybeSingle()
    if (!media || media.teacher_id !== user.user.id || media.status !== 'needs_review') {
      return Response.json({ message: 'Reviewable transcript required' }, { status: 409 })
    }
    const segments = (media.transcript_segments as Segment[]).filter((s) =>
      Number.isFinite(s.start) && Number.isFinite(s.end) && s.end > s.start && s.text?.trim())
    const { data: lesson } = await ctx.supabase.from('lessons')
      .select('duration_seconds').eq('id', media.lesson_id).single()
    const duration = Number(media.duration_seconds) ||
      Number(lesson?.duration_seconds) || segments.at(-1)?.end || 0
    const eligible = segments.filter((s) => s.end + 5 <= duration - 10 && s.end >= 10)
    if (!eligible.length) return Response.json({ message: 'Transcript is too short' }, { status: 422 })
    const sampled = eligible.filter((_, i) => i % Math.max(1, Math.floor(eligible.length / 8)) === 0)
      .slice(0, 8)
    const prompt = sampled.map((s, index) =>
      `${index}: [${s.start}-${s.end}s] ${s.text}`).join('\n').slice(0, 12000)
    const { error: reserveError } = await ctx.supabase.rpc(
      'reserve_lesson_checkpoint_generation', { p_media_id: mediaId })
    if (reserveError) {
      return Response.json({ message: 'Daily limit reached or checks already generated' }, { status: 429 })
    }
    const model = Deno.env.get('GEMINI_QUIZ_MODEL') || 'gemini-3.1-flash-lite'
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`, {
        method: 'POST',
        headers: { 'x-goog-api-key': key, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: 'Create at most three accurate, low-stakes multiple-choice checks strictly supported by the numbered lecture transcript windows. Use the same language as the source. Each has four distinct options, one correct answer, a short explanatory feedback sentence, and the exact source_index. Do not invent facts. The teacher will review these drafts.' }] },
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: 'application/json', responseJsonSchema: schema },
        }),
      })
    if (!response.ok) return Response.json({ message: 'AI provider unavailable' }, { status: 502 })
    const result = await response.json()
    const output = (result.candidates?.[0]?.content?.parts ?? [])
      .map((part: { text?: string }) => part.text ?? '').join('')
    let questions: Question[]
    try { questions = JSON.parse(output).questions } catch {
      return Response.json({ message: 'AI returned invalid checks' }, { status: 502 })
    }
    if (!Array.isArray(questions) || !questions.length || questions.length > 3 ||
        questions.some((q) => !Number.isInteger(q.source_index) ||
          q.source_index < 0 || q.source_index >= sampled.length ||
          !q.question?.trim() || !Array.isArray(q.options) || q.options.length !== 4 ||
          q.options.some((o) => typeof o !== 'string' || !o.trim()) ||
          new Set(q.options.map((o) => o.trim().toLowerCase())).size !== 4 ||
          !Number.isInteger(q.correct_index) || q.correct_index < 0 || q.correct_index > 3 ||
          typeof q.explanation !== 'string' || !q.explanation.trim())) {
      return Response.json({ message: 'AI returned invalid checks' }, { status: 502 })
    }
    const service = createClient(Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
    const { data: existing } = await service.from('lesson_checkpoints')
      .select('timestamp_seconds').eq('media_id', mediaId)
    const occupied = (existing ?? []).map((c) => Number(c.timestamp_seconds))
    let created = 0
    for (const question of questions) {
      const source = sampled[question.source_index]
      const at = Math.ceil(source.end + 5)
      if (occupied.some((time) => Math.abs(time - at) < 20)) continue
      const { data: row, error } = await service.from('lesson_checkpoints').insert({
        media_id: mediaId, timestamp_seconds: at, question: question.question.trim(),
        options: question.options, explanation: question.explanation,
        source_start_seconds: Math.floor(source.start),
        source_end_seconds: Math.ceil(source.end), status: 'draft',
      }).select('id').single()
      if (error || !row) continue
      await service.from('lesson_checkpoint_keys').insert({
        checkpoint_id: row.id, correct_index: question.correct_index,
      })
      occupied.push(at)
      created++
    }
    return Response.json({ created })
  }),
}

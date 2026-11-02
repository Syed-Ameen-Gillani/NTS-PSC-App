import { withSupabase } from 'npm:@supabase/server@1'

const timers = new Set([5, 10, 15, 20, 30])
const difficulties = new Set(['Easy', 'Medium', 'Hard'])

const questionSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['questions'],
  properties: {
    questions: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['question', 'options', 'correct_index', 'explanation'],
        properties: {
          question: { type: 'string' },
          options: {
            type: 'array',
            items: { type: 'string' },
          },
          correct_index: { type: 'integer' },
          explanation: { type: 'string' },
        },
      },
    },
  },
}

type GeneratedQuestion = {
  question: string
  options: string[]
  correct_index: number
  explanation: string
}

function validQuestions(value: unknown, expected: number): value is GeneratedQuestion[] {
  return Array.isArray(value) && value.length === expected && value.every((item) =>
    typeof item === 'object' && item !== null &&
    typeof item.question === 'string' && item.question.trim().length > 0 &&
    Array.isArray(item.options) && item.options.length === 4 &&
    item.options.every((option: unknown) => typeof option === 'string' && option.trim().length > 0) &&
    Number.isInteger(item.correct_index) && item.correct_index >= 0 && item.correct_index < 4 &&
    typeof item.explanation === 'string'
  )
}

export default {
  fetch: withSupabase({ auth: 'user' }, async (req, ctx) => {
    if (req.method !== 'POST') {
      return Response.json({ message: 'Method not allowed' }, { status: 405 })
    }
    const geminiKey = Deno.env.get('GEMINI_API_KEY')
    const openAiKey = Deno.env.get('OPENAI_API_KEY')
    const key = geminiKey || openAiKey
    if (!key) {
      return Response.json({ message: 'AI generation is not configured' }, { status: 503 })
    }
    let input: Record<string, unknown>
    try {
      input = await req.json()
    } catch {
      return Response.json({ message: 'Invalid request body' }, { status: 400 })
    }
    const topic = typeof input.topic === 'string' ? input.topic.trim() : ''
    const difficulty = input.difficulty
    const questionCount = input.questionCount
    const durationMinutes = input.durationMinutes
    if (topic.length < 3 || topic.length > 200 ||
        typeof difficulty !== 'string' || !difficulties.has(difficulty) ||
        !Number.isInteger(questionCount) || (questionCount as number) < 1 ||
        (questionCount as number) > 10 || !timers.has(durationMinutes as number)) {
      return Response.json({ message: 'Invalid quiz settings' }, { status: 400 })
    }
    const { data: userData, error: userError } = await ctx.supabase.auth.getUser()
    if (userError || !userData.user) {
      return Response.json({ message: 'Sign in required' }, { status: 401 })
    }
    const { data: profile, error: profileError } = await ctx.supabase
      .from('profiles').select('role').eq('id', userData.user.id).single()
    if (profileError || profile?.role !== 'teacher') {
      return Response.json({ message: 'Teacher account required' }, { status: 403 })
    }

    const model = geminiKey
      ? Deno.env.get('GEMINI_QUIZ_MODEL') || 'gemini-3.1-flash-lite'
      : Deno.env.get('OPENAI_QUIZ_MODEL') || 'gpt-4.1-mini'
    const { data: requestId, error: reserveError } = await ctx.supabase.rpc(
      'reserve_ai_quiz_generation',
      {
        p_topic: topic,
        p_difficulty: difficulty,
        p_question_count: questionCount,
        p_duration_minutes: durationMinutes,
        p_model: model,
      },
    )
    if (reserveError) {
      return Response.json({ message: 'Daily limit reached or request invalid' }, { status: 429 })
    }

    try {
      const providerResponse = await fetch(geminiKey
        ? `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`
        : 'https://api.openai.com/v1/responses', {
        method: 'POST',
        headers: geminiKey
          ? { 'x-goog-api-key': key, 'Content-Type': 'application/json' }
          : { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(geminiKey
          ? {
            systemInstruction: {
              parts: [{ text: 'Create accurate multiple-choice exam practice for Pakistani NTS/PSC learners. Return distinct questions, four options each, one correct answer, and a concise explanation. Avoid unverifiable current-event claims. The teacher will review this draft before publishing.' }],
            },
            contents: [{ role: 'user', parts: [{ text: `Topic: ${topic}\nDifficulty: ${difficulty}\nQuestion count: ${questionCount}` }] }],
            generationConfig: {
              responseMimeType: 'application/json',
              responseJsonSchema: questionSchema,
            },
          }
          : {
            model,
            instructions: 'Create accurate multiple-choice exam practice for Pakistani NTS/PSC learners. Return exactly the requested number of distinct questions, four options each, one correct answer, and a concise explanation. Avoid unverifiable current-event claims. The teacher will review this draft before publishing.',
            input: `Topic: ${topic}\nDifficulty: ${difficulty}\nQuestion count: ${questionCount}`,
            text: {
              format: {
                type: 'json_schema',
                name: 'teacher_quiz_draft',
                strict: true,
                schema: questionSchema,
              },
            },
          }),
      })
      if (!providerResponse.ok) {
        const providerError = await providerResponse.json().catch(() => null)
        return Response.json({
          message: 'AI provider unavailable',
          providerStatus: providerResponse.status,
          providerReason: providerError?.error?.status ?? 'UNKNOWN',
        }, { status: 502 })
      }
      const providerResult = await providerResponse.json()
      const outputText = geminiKey
        ? (providerResult.candidates?.[0]?.content?.parts ?? [])
          .map((part: { text?: string }) => part.text ?? '').join('')
        : (providerResult.output ?? [])
          .flatMap((item: { content?: Array<{ type?: string; text?: string }> }) => item.content ?? [])
          .filter((part: { type?: string }) => part.type === 'output_text')
          .map((part: { text?: string }) => part.text ?? '')
          .join('')
      const parsed = JSON.parse(outputText)
      if (!validQuestions(parsed.questions, questionCount as number)) {
        return Response.json({ message: 'AI returned invalid questions' }, { status: 502 })
      }
      const { data: quizId, error: saveError } = await ctx.supabase.rpc(
        'create_ai_quiz_draft',
        { p_request_id: requestId, p_questions: parsed.questions },
      )
      if (saveError) {
        return Response.json({ message: 'Could not save quiz draft' }, { status: 500 })
      }
      return Response.json({ quizId })
    } catch {
      return Response.json({ message: 'AI generation failed' }, { status: 502 })
    }
  }),
}

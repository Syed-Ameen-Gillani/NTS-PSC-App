import { withSupabase } from 'npm:@supabase/server@1'
import { createClient } from 'npm:@supabase/supabase-js@2'
import { renderCertificate } from './render.ts'

export default {
  fetch: withSupabase({ auth: 'user' }, async (req, ctx) => {
    if (req.method !== 'POST') return Response.json({ message: 'Method not allowed' }, { status: 405 })
    try {
      const { courseId } = await req.json()
      if (typeof courseId !== 'string' || !/^[a-f0-9-]{36}$/i.test(courseId)) {
        return Response.json({ message: 'Invalid course' }, { status: 400 })
      }
      const { data: identity } = await ctx.supabase.auth.getUser()
      if (!identity.user) return Response.json({ message: 'Sign in required' }, { status: 401 })
      const { error: eligibilityError } = await ctx.supabase.rpc('get_my_course_eligibility')
      if (eligibilityError) throw eligibilityError
      const { data: completion, error } = await ctx.supabase.from('course_completions')
        .select('id,student_id,student_name,course_title,instructor_name,completed_at')
        .eq('course_id', courseId).eq('student_id', identity.user.id).maybeSingle()
      if (error) throw error
      if (!completion) return Response.json({ message: 'Complete all course requirements first' }, { status: 403 })
      const service = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
      const bucket = service.storage.from('course-certificates')
      const path = `${completion.student_id}/${completion.id}.pdf`
      const existing = await bucket.download(path)
      if (existing.error) {
        const bytes = await renderCertificate(completion)
        const upload = await bucket.upload(path, bytes, { contentType: 'application/pdf', upsert: false })
        if (upload.error) {
          // Concurrent requests may race; only accept a confirmed stored PDF.
          const check = await bucket.download(path)
          if (check.error) throw upload.error
        }
      }
      const { data: signed, error: signingError } = await bucket.createSignedUrl(path, 300)
      if (signingError) throw signingError
      return Response.json({ url: signed.signedUrl, completion }, {
        headers: { 'Cache-Control': 'no-store' },
      })
    } catch {
      return Response.json({ message: 'Could not prepare your certificate. Please try again.' }, { status: 503 })
    }
  }),
}

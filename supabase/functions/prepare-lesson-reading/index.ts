import { withSupabase } from 'npm:@supabase/server@1'
import { createClient } from 'npm:@supabase/supabase-js@2'
import { maxReadingBytes, prepareReading } from './reading_policy.ts'
export default {
  fetch: withSupabase({ auth: 'user' }, async (req, ctx) => {
    if (req.method !== 'POST') return Response.json({ message: 'Method not allowed' }, { status: 405 })
    const input = await req.json().catch(() => null)
    if (typeof input?.materialId !== 'string' || !/^[0-9a-f-]{36}$/i.test(input.materialId)) {
      return Response.json({ message: 'Choose a valid reading' }, { status: 400 })
    }
    // Fetch through caller RLS before any service-role download/update.
    const { data: material } = await ctx.supabase.from('curriculum_materials')
      .select('id,lesson_id,object_path,mime_type,size_bytes,reading_hash,reading_units,reading_min_ms,reading_text')
      .eq('id', input.materialId).eq('status', 'ready').maybeSingle()
    if (!material?.lesson_id) return Response.json({ message: 'Reading unavailable' }, { status: 404 })
    if (!['application/pdf', 'text/plain'].includes(material.mime_type)) {
      return Response.json({ message: 'Use a PDF or text file for a required reading' }, { status: 422 })
    }
    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
    try {
      let units = material.reading_units
      let minMs = material.reading_min_ms
      let text = material.reading_text
      if (!material.reading_hash) {
        if (material.size_bytes > maxReadingBytes) throw new Error('Reading too large')
        const { data, error } = await admin.storage.from('course-materials').download(material.object_path)
        if (error || !data || data.size > maxReadingBytes) throw new Error('Download failed')
        const bytes = new Uint8Array(await data.arrayBuffer())
        const prepared = await prepareReading(bytes, material.mime_type)
        ;({ units, minMs, text } = prepared)
        const { error: saveError } = await admin.from('curriculum_materials').update({
          reading_hash: prepared.hash, reading_units: units, reading_min_ms: minMs, reading_text: text,
        }).eq('id', material.id).eq('object_path', material.object_path)
        if (saveError) throw saveError
      }
      // Caller storage policies recheck entitlement/current-lesson access.
      const { data: signed, error } = await ctx.supabase.storage.from('course-materials')
        .createSignedUrl(material.object_path, 3600)
      if (error || !signed) return Response.json({ message: 'Reading access changed' }, { status: 403 })
      return Response.json({ units, min_ms: minMs, text, url: signed.signedUrl, pdf: material.mime_type === 'application/pdf' })
    } catch (error) {
      console.error('prepare-lesson-reading failed', {
        materialId: material.id,
        mimeType: material.mime_type,
        sizeBytes: material.size_bytes,
        error: error instanceof Error ? error.message : String(error),
      })
      return Response.json({ message: 'Could not open this reading. Ask the instructor to check the file.' }, { status: 422 })
    }
  }),
}

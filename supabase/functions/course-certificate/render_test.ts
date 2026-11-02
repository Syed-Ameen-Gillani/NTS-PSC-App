import { PDFDocument } from 'npm:pdf-lib@1.17.1'
import { renderCertificate } from './render.ts'

Deno.test('certificate contains a real single-page PDF and durable identity', async () => {
  const record = {
    id: '12345678-1234-1234-1234-123456789abc',
    student_name: 'Ayesha Khan', course_title: 'Kashmir Studies',
    instructor_name: 'Ameen Gillani', completed_at: '2026-10-25T10:00:00Z',
  }
  const bytes = await renderCertificate(record)
  const pdf = await PDFDocument.load(bytes)
  if (pdf.getPageCount()!==1 || pdf.getAuthor()!=='CBOA') throw new Error('Invalid PDF')
  await Deno.mkdir('tmp/pdfs', { recursive: true })
  await Deno.writeFile('tmp/pdfs/certificate-preview.pdf', bytes)
})

Deno.test('certificate accepts Urdu names without encoding failure', async () => {
  const bytes = await renderCertificate({
    id: '12345678-1234-1234-1234-123456789abc', student_name: 'عائشہ خان',
    course_title: 'مطالعہ کشمیر', instructor_name: 'امین گیلانی', completed_at: '2026-10-25T10:00:00Z',
  })
  const pdf = await PDFDocument.load(bytes)
  if (pdf.getPageCount()!==1) throw new Error('Invalid Urdu PDF')
  await Deno.writeFile('tmp/pdfs/certificate-urdu-preview.pdf', bytes)
})

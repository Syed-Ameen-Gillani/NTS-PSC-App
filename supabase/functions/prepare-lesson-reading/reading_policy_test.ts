import { PDFDocument } from 'npm:pdf-lib@1.17.1'
import { maxReadingBytes, prepareReading } from './reading_policy.ts'

const encode = (text: string) => new TextEncoder().encode(text)
function assert(value: boolean) { if (!value) throw new Error('Assertion failed') }
async function rejects(bytes: Uint8Array, mime = 'text/plain') {
  let failed = false
  try { await prepareReading(bytes, mime) } catch { failed = true }
  assert(failed)
}

Deno.test('actual PDF pages determine coverage and engagement', async () => {
  const pdf = await PDFDocument.create()
  pdf.addPage().drawText('First page')
  pdf.addPage().drawText('Second page')
  const result = await prepareReading(await pdf.save(), 'application/pdf')
  assert(result.units === 2 && result.minMs === 60000 && result.text === null)
  assert(/^[0-9a-f]{64}$/.test(result.hash))
})

Deno.test('text sections and minimum time handle Urdu and mixed whitespace', async () => {
  const result = await prepareReading(encode(Array(81).fill('تعلیم').join(' \n\t')), 'text/plain')
  assert(result.units === 2 && result.minMs === 24300 && result.text?.includes('تعلیم') === true)
  const short = await prepareReading(encode('One word'), 'text/plain')
  assert(short.units === 1 && short.minMs === 5000)
  assert(short.hash !== result.hash)
})

Deno.test('malformed, empty and unsupported required readings are rejected', async () => {
  await rejects(encode(' \n\t '))
  await rejects(new Uint8Array([0xff, 0xfe]))
  await rejects(encode('not a PDF'), 'application/pdf')
  await rejects(encode('document'), 'application/msword')
  await rejects(new Uint8Array(), 'application/pdf')
  await rejects(encode('<html>Storage error</html>'), 'application/pdf')
  const emptyPdf = await PDFDocument.create()
  await rejects(await emptyPdf.save({ addDefaultPage: false }), 'application/pdf')
})

Deno.test('file and text-length limits are enforced', async () => {
  await rejects(new Uint8Array(maxReadingBytes + 1))
  await rejects(encode('x'.repeat(500001)))
})

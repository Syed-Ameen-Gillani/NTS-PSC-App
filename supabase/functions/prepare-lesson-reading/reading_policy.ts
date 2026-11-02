import { PDFDocument } from 'npm:pdf-lib@1.17.1'

export const maxReadingBytes = 25 * 1024 * 1024

/** Derive completion criteria from the actual private file, never client metadata. */
export async function prepareReading(bytes: Uint8Array, mime: string) {
  if (bytes.byteLength > maxReadingBytes) throw new Error('Reading too large')
  let units: number
  let minMs: number
  let text: string | null
  if (mime === 'application/pdf') {
    // File extensions and MIME labels alone do not establish PDF content.
    const header = new TextDecoder('ascii').decode(bytes.subarray(0, 1024))
    if (!header.includes('%PDF-')) throw new Error('Invalid PDF signature')
    // Many readable PDFs carry owner/permission encryption even though they
    // require no password in a viewer. We only inspect their page count here;
    // pdfrx remains responsible for opening/decrypting the actual document.
    units = (await PDFDocument.load(bytes, { ignoreEncryption: true })).getPageCount()
    minMs = units * 30000
    text = null
  } else if (mime === 'text/plain') {
    text = new TextDecoder('utf-8', { fatal: true }).decode(bytes).trim()
    if (!text || text.length > 500000) throw new Error('Text reading is empty or too long')
    const words = text.split(/\s+/).length
    units = Math.ceil(words / 80)
    minMs = Math.max(5000, words * 300)
  } else {
    throw new Error('Unsupported required reading')
  }
  if (units < 1 || units > 5000 || minMs > 86400000) throw new Error('Reading is too long')
  const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new Uint8Array(bytes).buffer)))
    .map((b) => b.toString(16).padStart(2, '0')).join('')
  return { units, minMs, text, hash }
}

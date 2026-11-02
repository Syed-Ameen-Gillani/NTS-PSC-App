import { PDFDocument, rgb, type PDFFont } from 'npm:pdf-lib@1.17.1'
import * as fontkit from 'npm:fontkit@2.0.4'
import { latinFont, arabicFont } from './fonts.ts'

export type Completion = {
  id: string; student_name: string; course_title: string;
  instructor_name: string; completed_at: string;
}

export async function renderCertificate(record: Completion): Promise<Uint8Array> {
  const document = await PDFDocument.create()
  document.registerFontkit(fontkit)
  const latin = await document.embedFont(latinFont)
  const arabic = await document.embedFont(arabicFont)
  const page = document.addPage([842, 595])
  const blue = rgb(0.12, 0.44, 0.96)
  const ink = rgb(0.08, 0.12, 0.2)
  page.drawRectangle({ x: 26, y: 26, width: 790, height: 543, borderWidth: 1, borderColor: blue })
  page.drawRectangle({ x: 26, y: 553, width: 790, height: 16, color: blue })
  const center = (text: string, y: number, size: number, font: PDFFont = latin) => {
    const width = font.widthOfTextAtSize(text, size)
    page.drawText(text, { x: (842-width)/2, y, size, font, color: ink })
  }
  const lines = (text: string, y: number, size: number, maxLines: number) => {
    const clean = text.replace(/[\r\n\t]+/g, ' ').trim()
    const font = /[\u0600-\u06ff]/u.test(clean) ? arabic : latin
    const output: string[] = []
    let current = ''
    for (const word of clean.split(/\s+/)) {
      const candidate = current ? `${current} ${word}` : word
      if (font.widthOfTextAtSize(candidate, size)>700 && current) {
        output.push(current); current = word
      } else current = candidate
    }
    if (current) output.push(current)
    if (!output.length || output.length>maxLines || output.some(line=>font.widthOfTextAtSize(line,size)>700)) {
      throw new Error('Certificate text does not fit')
    }
    output.forEach((line,index)=>center(line,y-index*(size+8),size,font))
  }
  center('CBOA', 501, 26)
  center('CERTIFICATE OF COMPLETION', 450, 25)
  center('This certifies that', 411, 12)
  lines(record.student_name, 370, 25, 2)
  center('has completed the required lessons and assessments for', 291, 12)
  lines(record.course_title, 250, 21, 3)
  center('Instructor', 151, 10)
  lines(record.instructor_name, 130, 12, 1)
  const date = new Intl.DateTimeFormat('en-GB', {
    day: 'numeric', month: 'long', year: 'numeric', timeZone: 'Asia/Karachi',
  }).format(new Date(record.completed_at))
  center(`Completed on ${date}`, 83, 12)
  center(`Certificate ID: ${record.id}`, 49, 9)
  document.setTitle('CBOA Certificate of Completion')
  document.setAuthor('CBOA')
  document.setCreationDate(new Date(record.completed_at))
  return document.save()
}

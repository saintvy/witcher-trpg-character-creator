import type { Context } from 'hono';
import { CharacterPdfService } from '../pdf/CharacterPdfService.js';

const pdfService = new CharacterPdfService();

export async function characterPdf(c: Context) {
  let body: unknown;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: 'Invalid JSON body' }, 400);
  }

  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    return c.json({ error: 'Expected character JSON object' }, 400);
  }

  try {
    const pdfBuffer = await pdfService.generatePdfBuffer(body);
    const pdfBytes = new Uint8Array(pdfBuffer);
    return c.body(pdfBytes, 200, {
      'Content-Type': 'application/pdf',
      'Cache-Control': 'no-store',
    });
  } catch (error) {
    console.error('[pdf] generation error', error);
    return c.json({ error: 'Failed to generate PDF' }, 500);
  }
}

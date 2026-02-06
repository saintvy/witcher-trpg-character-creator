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

  const bodyObj = body as Record<string, unknown>;
  const character = bodyObj.character !== undefined ? bodyObj.character : body;
  const options = (typeof bodyObj.options === 'object' && bodyObj.options !== null ? bodyObj.options : {}) as import('../pdf/CharacterPdfService.js').PdfOptions;

  try {
    const pdfBuffer = await pdfService.generatePdfBuffer(character, options);
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

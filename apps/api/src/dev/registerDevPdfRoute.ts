import type { Hono } from 'hono';

type PdfOptions = { alchemy_style?: 'w1' | 'w2' };

type RegisterDevPdfRouteDeps = {
  asRecord: (value: unknown) => Record<string, unknown> | null;
  getUserEmail: (user: any) => string | null;
  buildPdfArtifactsFromRawCharacter: (params: {
    rawCharacter: Record<string, unknown>;
    lang: string;
    ownerEmail?: string | null;
    explicitName?: string | null;
    avatarUrl?: string | null;
    options?: PdfOptions;
  }) => Promise<{ pdfBuffer: Buffer; fileName: string }>;
  buildDownloadContentDisposition: (fileName: string) => string;
};

export function registerDevPdfRoute(
  app: Hono<any>,
  deps: RegisterDevPdfRouteDeps,
) {
  app.post('/character/pdf', async (c) => {
    const body = (await c.req.json().catch(() => ({}))) as unknown;
    const bodyRec = deps.asRecord(body);
    const rawCharacter = deps.asRecord(bodyRec?.character);
    if (!rawCharacter) {
      return c.json({ error: 'character payload is required' }, 400);
    }

    const requestedLang = (
      (typeof bodyRec?.lang === 'string' && bodyRec.lang) ||
      c.req.query('lang') ||
      c.req.header('Accept-Language')?.split(',')[0]?.split('-')[0] ||
      'en'
    )
      .trim()
      .toLowerCase();
    const lang = requestedLang || 'en';

    const optionsRec = deps.asRecord(bodyRec?.options);
    const alchemyStyle =
      optionsRec?.alchemy_style === 'w1' || optionsRec?.alchemy_style === 'w2'
        ? (optionsRec.alchemy_style as 'w1' | 'w2')
        : undefined;

    try {
      const { pdfBuffer, fileName } = await deps.buildPdfArtifactsFromRawCharacter({
        rawCharacter,
        lang,
        ownerEmail: deps.getUserEmail(c.get('authUser')),
        options: { alchemy_style: alchemyStyle },
      });

      return c.body(new Uint8Array(pdfBuffer), 200, {
        'Content-Type': 'application/pdf',
        'Cache-Control': 'no-store',
        'Content-Disposition': deps.buildDownloadContentDisposition(fileName),
      });
    } catch (error) {
      console.error('[character] pdf generation error', error);
      return c.json({ error: 'Failed to generate PDF' }, 500);
    }
  });
}

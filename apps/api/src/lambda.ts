import { handle } from 'hono/aws-lambda';

type HonoLambdaHandler = ReturnType<typeof handle>;

let cachedHandler: HonoLambdaHandler | undefined;
let initPromise: Promise<void> | undefined;

async function ensureHandler(): Promise<HonoLambdaHandler> {
  if (cachedHandler) return cachedHandler;

  if (!initPromise) {
    initPromise = (async () => {
      const { app } = await import('./app.js');
      cachedHandler = handle(app);
    })();
  }

  await initPromise;

  if (!cachedHandler) {
    throw new Error('Lambda handler initialization failed');
  }

  return cachedHandler;
}

export const handler = async (event: any, context: any) => {
  const lambdaHandler = await ensureHandler();
  return lambdaHandler(event, context);
};

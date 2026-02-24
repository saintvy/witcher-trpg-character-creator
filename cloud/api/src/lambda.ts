import { handle } from 'hono/aws-lambda';
import {
  GetSecretValueCommand,
  SecretsManagerClient,
} from '@aws-sdk/client-secrets-manager';

type HonoLambdaHandler = ReturnType<typeof handle>;

let cachedHandler: HonoLambdaHandler | undefined;
let initPromise: Promise<void> | undefined;

async function loadDbCredentialsFromSecretsManager(): Promise<void> {
  if (process.env.POSTGRES_PASSWORD) return;

  const secretArn = process.env.DB_SECRET_ARN;
  if (!secretArn) return;

  const client = new SecretsManagerClient({});
  const secret = await client.send(
    new GetSecretValueCommand({
      SecretId: secretArn,
    }),
  );

  const secretString =
    secret.SecretString ??
    (secret.SecretBinary
      ? Buffer.from(secret.SecretBinary as Uint8Array).toString('utf8')
      : undefined);

  if (!secretString) {
    throw new Error('Secrets Manager returned an empty DB secret payload');
  }

  const parsed = JSON.parse(secretString) as {
    username?: string;
    password?: string;
  };

  if (!parsed.password) {
    throw new Error('DB secret does not contain "password"');
  }

  process.env.POSTGRES_PASSWORD = parsed.password;

  if (!process.env.POSTGRES_USER && parsed.username) {
    process.env.POSTGRES_USER = parsed.username;
  }
}

async function ensureHandler(): Promise<HonoLambdaHandler> {
  if (cachedHandler) return cachedHandler;

  if (!initPromise) {
    initPromise = (async () => {
      await loadDbCredentialsFromSecretsManager();
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

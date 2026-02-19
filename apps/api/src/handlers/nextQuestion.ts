import type { Context } from 'hono';
import { getNextQuestion } from '@wcc/core';

export async function nextQuestion(c: Context) {
  try {
    const payload = await c.req.json();
    const result = await getNextQuestion(payload);
    return c.json(result);
  } catch (error) {
    console.error('[survey] next question error', error);
    return c.json({ error: 'Failed to resolve next question' }, 400);
  }
}

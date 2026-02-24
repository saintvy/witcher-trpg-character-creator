"use client";

import { getCurrentAuthIdToken } from "./auth-context";

function isHeaders(headers: HeadersInit | undefined): headers is Headers {
  return typeof Headers !== "undefined" && headers instanceof Headers;
}

export async function apiFetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  const token = getCurrentAuthIdToken();
  if (!token) {
    return fetch(input, init);
  }

  const nextInit: RequestInit = { ...init };
  const authValue = `Bearer ${token}`;

  if (isHeaders(nextInit.headers)) {
    nextInit.headers = new Headers(nextInit.headers);
    nextInit.headers.set("Authorization", authValue);
    return fetch(input, nextInit);
  }

  nextInit.headers = {
    ...(nextInit.headers ?? {}),
    Authorization: authValue,
  };

  return fetch(input, nextInit);
}


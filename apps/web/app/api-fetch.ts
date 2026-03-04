"use client";

import { ensureFreshAuthIdToken, getCurrentAuthIdToken } from "./auth-context";

export async function apiFetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  const baseRequest = new Request(input, init);
  const token = (await ensureFreshAuthIdToken(false)) ?? getCurrentAuthIdToken();
  if (!token) {
    return fetch(baseRequest);
  }

  const authValue = `Bearer ${token}`;
  const requestHeaders = new Headers(baseRequest.headers);
  requestHeaders.set("Authorization", authValue);
  const withAuth = new Request(baseRequest, { headers: requestHeaders });

  let response = await fetch(withAuth);
  if (response.status !== 401) {
    return response;
  }

  const refreshedToken = await ensureFreshAuthIdToken(true);
  if (!refreshedToken) {
    return response;
  }

  const retryRequest = new Request(baseRequest);
  const retryHeaders = new Headers(retryRequest.headers);
  retryHeaders.set("Authorization", `Bearer ${refreshedToken}`);
  const retryWithAuth = new Request(retryRequest, { headers: retryHeaders });
  response = await fetch(retryWithAuth);

  return response;
}

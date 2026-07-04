import { describe, expect, it } from "vitest";

import type { SessionFetch } from "./session-api";
import { fetchOperatorSession } from "./session-api";

const apiBaseUrl = "https://backend.example.test";

function createResponse(status: number, body: unknown, correlationId = "corr-test"): Response {
  return new Response(JSON.stringify(body), {
    headers: {
      "Content-Type": "application/json",
      "X-Correlation-ID": correlationId,
    },
    status,
  });
}

describe("fetchOperatorSession", () => {
  it("returns a validated authenticated session", async () => {
    let observedInput: RequestInfo | URL | undefined;
    let observedInit: RequestInit | undefined;

    const fetchImpl: SessionFetch = async (input, init) => {
      observedInput = input;
      observedInit = init;

      return createResponse(200, {
        capabilities: ["dashboard:view", "inventory:read"],
        displayName: "Operador Teste",
        role: "operator",
        userId: "user-123",
      });
    };

    const result = await fetchOperatorSession({
      accessToken: "valid-token",
      apiBaseUrl,
      correlationId: "corr-request",
      fetchImpl,
    });

    expect(String(observedInput)).toBe("https://backend.example.test/api/v1/session");
    expect(observedInit?.cache).toBe("no-store");
    expect(observedInit?.method).toBe("GET");

    const headers = new Headers(observedInit?.headers);

    expect(headers.get("authorization")).toBe("Bearer valid-token");
    expect(headers.get("x-correlation-id")).toBe("corr-request");
    expect(result).toEqual({
      correlationId: "corr-test",
      session: {
        capabilities: ["dashboard:view", "inventory:read"],
        displayName: "Operador Teste",
        role: "operator",
        userId: "user-123",
      },
      status: "authenticated",
    });
  });

  it("maps an empty token to an expired session without making a request", async () => {
    let requestCount = 0;

    const fetchImpl: SessionFetch = async () => {
      requestCount += 1;

      return createResponse(200, {});
    };

    const result = await fetchOperatorSession({
      accessToken: " ",
      apiBaseUrl,
      fetchImpl,
    });

    expect(requestCount).toBe(0);
    expect(result).toEqual({
      code: "AUTHENTICATION_REQUIRED",
      correlationId: null,
      status: "session-expired",
    });
  });

  it.each([
    {
      expected: {
        code: "AUTHENTICATION_REQUIRED",
        correlationId: "corr-401",
        status: "session-expired",
      },
      status: 401,
    },
    {
      expected: {
        code: "ACCESS_DENIED",
        correlationId: "corr-403",
        status: "access-denied",
      },
      status: 403,
    },
    {
      expected: {
        code: "IDENTITY_SERVICE_UNAVAILABLE",
        correlationId: "corr-503",
        status: "service-unavailable",
      },
      status: 503,
    },
  ] as const)("maps HTTP $status to a sanitized session state", async ({ expected, status }) => {
    const fetchImpl: SessionFetch = async () =>
      createResponse(status, { code: "internal-value" }, `corr-${status}`);

    await expect(
      fetchOperatorSession({
        accessToken: "token",
        apiBaseUrl,
        fetchImpl,
      }),
    ).resolves.toEqual(expected);
  });

  it("rejects an invalid successful payload", async () => {
    const fetchImpl: SessionFetch = async () =>
      createResponse(200, {
        capabilities: ["dashboard:view", 10],
        displayName: "",
        role: "operator",
        userId: "user-123",
      });

    await expect(
      fetchOperatorSession({
        accessToken: "token",
        apiBaseUrl,
        fetchImpl,
      }),
    ).resolves.toEqual({
      code: "UNEXPECTED_RESPONSE",
      correlationId: "corr-test",
      status: "unexpected-error",
    });
  });

  it("maps a transport failure to identity service unavailable", async () => {
    const fetchImpl: SessionFetch = async () => {
      throw new Error("network unavailable");
    };

    await expect(
      fetchOperatorSession({
        accessToken: "token",
        apiBaseUrl,
        fetchImpl,
      }),
    ).resolves.toEqual({
      code: "IDENTITY_SERVICE_UNAVAILABLE",
      correlationId: null,
      status: "service-unavailable",
    });
  });

  it("rejects an invalid API base URL", async () => {
    const fetchImpl: SessionFetch = async () => createResponse(200, {});

    await expect(
      fetchOperatorSession({
        accessToken: "token",
        apiBaseUrl: "not-a-valid-url",
        fetchImpl,
      }),
    ).resolves.toEqual({
      code: "UNEXPECTED_RESPONSE",
      correlationId: null,
      status: "unexpected-error",
    });
  });
});

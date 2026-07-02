import { describe, expect, it } from "vitest";

import {
  BACKEND_CONTRACT_ID,
  BACKEND_CONTRACT_SHA256,
  resolveBackendBaseUrl,
} from "../../config/backend";
import { ApiClientError, type FetchLike } from "./client";
import { getBackendHealth, HEALTH_PATH, type HealthResponse } from "./health";

const VALID_CORRELATION_ID = "3f2504e0-4f89-41d3-9a0c-0305e82c3301";

const HEALTH_PAYLOAD: HealthResponse = {
  data: {
    service: "smartbuy-backend",
    status: "ok",
    checkedAt: "2026-01-01T12:00:00.000Z",
  },
  meta: {
    correlationId: VALID_CORRELATION_ID,
  },
};

describe("typed backend API client", () => {
  it("pins the approved contract and resolves the backend origin", () => {
    expect(BACKEND_CONTRACT_ID).toBe("SBH-OPENAPI-001");
    expect(BACKEND_CONTRACT_SHA256).toBe(
      "B2875EC60B0E4C3A3871EAEF15A9924F811F098FA7E49D1974341C9F9D4E7E2B",
    );
    expect(
      resolveBackendBaseUrl({
        SMARTBUY_BACKEND_URL: " https://api.smartbuy.example/ ",
      }),
    ).toBe("https://api.smartbuy.example");
  });

  it("rejects missing or non-origin backend configuration", () => {
    expect(() => resolveBackendBaseUrl({})).toThrow("SMARTBUY_BACKEND_URL is required.");

    expect(() =>
      resolveBackendBaseUrl({
        SMARTBUY_BACKEND_URL: "https://api.smartbuy.example/base",
      }),
    ).toThrow("SMARTBUY_BACKEND_URL must contain only an HTTP(S) origin.");
  });

  it("requests and returns the typed health contract", async () => {
    const capture: {
      request?: Request;
    } = {};

    const fetchImpl: FetchLike = async (input, init) => {
      capture.request = new Request(input, init);

      return Response.json(HEALTH_PAYLOAD, {
        status: 200,
        headers: {
          "cache-control": "no-store",
          "x-correlation-id": VALID_CORRELATION_ID,
        },
      });
    };

    const result = await getBackendHealth({
      baseUrl: "http://127.0.0.1:3001",
      correlationId: VALID_CORRELATION_ID,
      fetchImpl,
    });

    const request = capture.request;

    if (!request) {
      throw new Error("The API client did not issue a request.");
    }

    expect(request.method).toBe("GET");
    expect(request.url).toBe(`http://127.0.0.1:3001${HEALTH_PATH}`);
    expect(request.cache).toBe("no-store");
    expect(request.headers.get("accept")).toBe("application/json");
    expect(request.headers.get("x-correlation-id")).toBe(VALID_CORRELATION_ID);

    expect(result.payload).toEqual(HEALTH_PAYLOAD);
    expect(result.cacheControl).toBe("no-store");
    expect(result.correlationId).toBe(VALID_CORRELATION_ID);
  });

  it("surfaces non-success responses as typed client errors", async () => {
    const fetchImpl: FetchLike = async () =>
      new Response(null, {
        status: 503,
        headers: {
          "x-correlation-id": VALID_CORRELATION_ID,
        },
      });

    let caughtError: unknown;

    try {
      await getBackendHealth({
        baseUrl: "http://127.0.0.1:3001",
        fetchImpl,
      });
    } catch (error) {
      caughtError = error;
    }

    expect(caughtError).toBeInstanceOf(ApiClientError);
    expect(caughtError).toMatchObject({
      name: "ApiClientError",
      method: "GET",
      path: HEALTH_PATH,
      status: 503,
      correlationId: VALID_CORRELATION_ID,
    });
  });
});

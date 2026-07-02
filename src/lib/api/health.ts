import { resolveBackendBaseUrl, type BackendEnvironment } from "../../config/backend";
import { createApiClient, type FetchLike } from "./client";

export const HEALTH_PATH = "/api/v1/health";

export type HealthResponse = Readonly<{
  data: Readonly<{
    service: "smartbuy-backend";
    status: "ok";
    checkedAt: string;
  }>;
  meta: Readonly<{
    correlationId: string;
  }>;
}>;

export type HealthSnapshot = Readonly<{
  cacheControl: string | null;
  correlationId: string | null;
  payload: HealthResponse;
}>;

export type GetBackendHealthOptions = Readonly<{
  baseUrl?: string;
  correlationId?: string;
  environment?: BackendEnvironment;
  fetchImpl?: FetchLike;
  signal?: AbortSignal;
}>;

export async function getBackendHealth(
  options: GetBackendHealthOptions = {},
): Promise<HealthSnapshot> {
  const baseUrl = options.baseUrl ?? resolveBackendBaseUrl(options.environment);

  const client = createApiClient({
    baseUrl,
    fetchImpl: options.fetchImpl,
  });

  const headers = new Headers();
  const correlationId = options.correlationId?.trim();

  if (correlationId) {
    headers.set("x-correlation-id", correlationId);
  }

  const response = await client.get<HealthResponse>(HEALTH_PATH, {
    headers,
    signal: options.signal,
  });

  return {
    cacheControl: response.headers.get("cache-control"),
    correlationId: response.headers.get("x-correlation-id"),
    payload: response.body,
  };
}

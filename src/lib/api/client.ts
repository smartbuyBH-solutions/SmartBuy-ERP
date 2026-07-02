export type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

export type ApiRequestOptions = Readonly<{
  headers?: HeadersInit;
  signal?: AbortSignal;
}>;

export type ApiResponse<TBody> = Readonly<{
  body: TBody;
  headers: Headers;
  status: number;
}>;

export type ApiClient = Readonly<{
  get<TBody>(path: string, options?: ApiRequestOptions): Promise<ApiResponse<TBody>>;
}>;

export class ApiClientError extends Error {
  readonly correlationId: string | null;
  readonly method: "GET";
  readonly path: string;
  readonly status: number;

  constructor(path: string, status: number, correlationId: string | null) {
    super(`GET ${path} failed with HTTP ${status}.`);

    this.name = "ApiClientError";
    this.method = "GET";
    this.path = path;
    this.status = status;
    this.correlationId = correlationId;
  }
}

function resolveApiOrigin(baseUrl: string): string {
  let url: URL;

  try {
    url = new URL(baseUrl);
  } catch {
    throw new Error("API base URL must be a valid absolute URL.");
  }

  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error("API base URL must use HTTP or HTTPS.");
  }

  if (url.username || url.password || url.pathname !== "/" || url.search || url.hash) {
    throw new Error("API base URL must contain only an HTTP(S) origin.");
  }

  return url.origin;
}

function resolveApiPath(path: string): string {
  if (!path.startsWith("/")) {
    throw new Error("API path must start with '/'.");
  }

  return path;
}

export function createApiClient(
  options: Readonly<{
    baseUrl: string;
    fetchImpl?: FetchLike;
  }>,
): ApiClient {
  const baseUrl = resolveApiOrigin(options.baseUrl);
  const fetchImpl = options.fetchImpl ?? fetch;

  return {
    async get<TBody>(
      path: string,
      requestOptions: ApiRequestOptions = {},
    ): Promise<ApiResponse<TBody>> {
      const normalizedPath = resolveApiPath(path);
      const headers = new Headers(requestOptions.headers);

      if (!headers.has("accept")) {
        headers.set("accept", "application/json");
      }

      const response = await fetchImpl(new URL(normalizedPath, `${baseUrl}/`), {
        method: "GET",
        headers,
        cache: "no-store",
        signal: requestOptions.signal,
      });

      const correlationId = response.headers.get("x-correlation-id");

      if (!response.ok) {
        throw new ApiClientError(normalizedPath, response.status, correlationId);
      }

      return {
        body: (await response.json()) as TBody,
        headers: response.headers,
        status: response.status,
      };
    },
  };
}

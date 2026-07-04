import type { OperatorSession } from "../domain/operator-session";
import type { SessionResult } from "../domain/session-result";

export type SessionFetch = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

export type FetchOperatorSessionOptions = Readonly<{
  accessToken: string;
  apiBaseUrl: string;
  correlationId?: string;
  fetchImpl?: SessionFetch;
}>;

const SESSION_PATH = "api/v1/session";

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

function parseOperatorSession(value: unknown): OperatorSession | null {
  if (!isRecord(value)) {
    return null;
  }

  const { capabilities, displayName, role, userId } = value;

  if (
    !Array.isArray(capabilities) ||
    !capabilities.every(isNonEmptyString) ||
    !isNonEmptyString(displayName) ||
    !isNonEmptyString(role) ||
    !isNonEmptyString(userId)
  ) {
    return null;
  }

  return {
    capabilities: [...capabilities],
    displayName,
    role,
    userId,
  };
}

function getCorrelationId(response: Response): string | null {
  const correlationId = response.headers.get("x-correlation-id")?.trim();

  return correlationId ? correlationId : null;
}

function buildSessionUrl(apiBaseUrl: string): string | null {
  try {
    const normalizedBaseUrl = apiBaseUrl.endsWith("/") ? apiBaseUrl : `${apiBaseUrl}/`;

    return new URL(SESSION_PATH, normalizedBaseUrl).toString();
  } catch {
    return null;
  }
}

export async function fetchOperatorSession({
  accessToken,
  apiBaseUrl,
  correlationId,
  fetchImpl = fetch,
}: FetchOperatorSessionOptions): Promise<SessionResult> {
  if (!accessToken.trim()) {
    return {
      code: "AUTHENTICATION_REQUIRED",
      correlationId: null,
      status: "session-expired",
    };
  }

  const sessionUrl = buildSessionUrl(apiBaseUrl);

  if (!sessionUrl) {
    return {
      code: "UNEXPECTED_RESPONSE",
      correlationId: null,
      status: "unexpected-error",
    };
  }

  const headers = new Headers({
    Accept: "application/json",
    Authorization: `Bearer ${accessToken}`,
  });

  if (correlationId?.trim()) {
    headers.set("X-Correlation-ID", correlationId.trim());
  }

  let response: Response;

  try {
    response = await fetchImpl(sessionUrl, {
      cache: "no-store",
      headers,
      method: "GET",
    });
  } catch {
    return {
      code: "IDENTITY_SERVICE_UNAVAILABLE",
      correlationId: null,
      status: "service-unavailable",
    };
  }

  const responseCorrelationId = getCorrelationId(response);

  if (response.status === 401) {
    return {
      code: "AUTHENTICATION_REQUIRED",
      correlationId: responseCorrelationId,
      status: "session-expired",
    };
  }

  if (response.status === 403) {
    return {
      code: "ACCESS_DENIED",
      correlationId: responseCorrelationId,
      status: "access-denied",
    };
  }

  if (response.status === 503) {
    return {
      code: "IDENTITY_SERVICE_UNAVAILABLE",
      correlationId: responseCorrelationId,
      status: "service-unavailable",
    };
  }

  if (response.status !== 200) {
    return {
      code: "UNEXPECTED_RESPONSE",
      correlationId: responseCorrelationId,
      status: "unexpected-error",
    };
  }

  let payload: unknown;

  try {
    payload = await response.json();
  } catch {
    return {
      code: "UNEXPECTED_RESPONSE",
      correlationId: responseCorrelationId,
      status: "unexpected-error",
    };
  }

  const session = parseOperatorSession(payload);

  if (!session) {
    return {
      code: "UNEXPECTED_RESPONSE",
      correlationId: responseCorrelationId,
      status: "unexpected-error",
    };
  }

  return {
    correlationId: responseCorrelationId,
    session,
    status: "authenticated",
  };
}

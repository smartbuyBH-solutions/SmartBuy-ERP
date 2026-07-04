export const SERVER_AUTH_ENVIRONMENT_KEYS = {
  backendApiUrl: "SMARTBUY_BACKEND_URL",
  supabasePublishableKey: "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
  supabaseUrl: "NEXT_PUBLIC_SUPABASE_URL",
} as const;

type RuntimeEnvironment = Readonly<Record<string, string | undefined>>;

export type ServerAuthConfig = Readonly<{
  backendApiUrl: string;
  supabasePublishableKey: string;
  supabaseUrl: string;
}>;

export type ServerAuthConfigResult =
  | Readonly<{
      config: ServerAuthConfig;
      status: "available";
    }>
  | Readonly<{
      missingOrInvalidKeys: readonly string[];
      status: "unavailable";
    }>;

function normalizeServiceUrl(value: string | undefined): string | null {
  const candidate = value?.trim();

  if (!candidate) {
    return null;
  }

  try {
    const url = new URL(candidate);
    const isHttps = url.protocol === "https:";
    const isLoopbackHttp =
      url.protocol === "http:" && ["localhost", "127.0.0.1", "[::1]"].includes(url.hostname);

    if ((!isHttps && !isLoopbackHttp) || url.username || url.password) {
      return null;
    }

    return url.toString().replace(/\/$/u, "");
  } catch {
    return null;
  }
}

function normalizePublishableKey(value: string | undefined): string | null {
  const candidate = value?.trim();

  if (!candidate) {
    return null;
  }

  const forbiddenMarkers = [["service", "role"].join("_"), ["sb", "secret", ""].join("_")];

  if (forbiddenMarkers.some((marker) => candidate.toLowerCase().includes(marker.toLowerCase()))) {
    return null;
  }

  return candidate;
}

export function readServerAuthConfig(
  environment: RuntimeEnvironment = process.env,
): ServerAuthConfigResult {
  const backendApiUrl = normalizeServiceUrl(
    environment[SERVER_AUTH_ENVIRONMENT_KEYS.backendApiUrl],
  );
  const supabasePublishableKey = normalizePublishableKey(
    environment[SERVER_AUTH_ENVIRONMENT_KEYS.supabasePublishableKey],
  );
  const supabaseUrl = normalizeServiceUrl(environment[SERVER_AUTH_ENVIRONMENT_KEYS.supabaseUrl]);

  const missingOrInvalidKeys = [
    ...(backendApiUrl ? [] : [SERVER_AUTH_ENVIRONMENT_KEYS.backendApiUrl]),
    ...(supabasePublishableKey ? [] : [SERVER_AUTH_ENVIRONMENT_KEYS.supabasePublishableKey]),
    ...(supabaseUrl ? [] : [SERVER_AUTH_ENVIRONMENT_KEYS.supabaseUrl]),
  ];

  if (
    !backendApiUrl ||
    !supabasePublishableKey ||
    !supabaseUrl ||
    missingOrInvalidKeys.length > 0
  ) {
    return {
      missingOrInvalidKeys,
      status: "unavailable",
    };
  }

  return {
    config: {
      backendApiUrl,
      supabasePublishableKey,
      supabaseUrl,
    },
    status: "available",
  };
}

import { createServerClient } from "@supabase/ssr";
import type { AuthError } from "@supabase/supabase-js";
import { cookies } from "next/headers";

import type {
  IdentityPasswordAuthenticator,
  IdentitySessionSource,
  IdentitySessionTerminator,
} from "@/modules/session/application/session-ports";

import { readServerAuthConfig, type ServerAuthConfig } from "./supabase-config";

export type ServerIdentityRuntime =
  | Readonly<{
      config: ServerAuthConfig;
      identityAuthenticator: IdentityPasswordAuthenticator;
      identitySource: IdentitySessionSource;
      identityTerminator: IdentitySessionTerminator;
      status: "available";
    }>
  | Readonly<{
      missingOrInvalidKeys: readonly string[];
      status: "configuration-unavailable";
    }>;

function classifyAuthError(error: AuthError): "service-unavailable" | "session-expired" {
  if (
    error.status === 400 ||
    error.status === 401 ||
    error.status === 403 ||
    error.status === 422
  ) {
    return "session-expired";
  }

  return "service-unavailable";
}

export async function createServerIdentityRuntime(
  environment: Readonly<Record<string, string | undefined>> = process.env,
): Promise<ServerIdentityRuntime> {
  const configuration = readServerAuthConfig(environment);

  if (configuration.status === "unavailable") {
    return {
      missingOrInvalidKeys: configuration.missingOrInvalidKeys,
      status: "configuration-unavailable",
    };
  }

  const cookieStore = await cookies();
  const supabase = createServerClient(
    configuration.config.supabaseUrl,
    configuration.config.supabasePublishableKey,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            for (const { name, options, value } of cookiesToSet) {
              cookieStore.set(name, value, options);
            }
          } catch {
            return;
          }
        },
      },
    },
  );

  const identitySource: IdentitySessionSource = {
    async getAccessToken() {
      try {
        const {
          data: { user },
          error: userError,
        } = await supabase.auth.getUser();

        if (userError) {
          return {
            status: classifyAuthError(userError),
          };
        }

        if (!user) {
          return {
            status: "session-expired",
          };
        }

        const {
          data: { session },
          error: sessionError,
        } = await supabase.auth.getSession();

        if (sessionError) {
          return {
            status: classifyAuthError(sessionError),
          };
        }

        const accessToken = session?.access_token?.trim();

        if (!accessToken) {
          return {
            status: "session-expired",
          };
        }

        return {
          accessToken,
          status: "authenticated",
        };
      } catch {
        return {
          status: "service-unavailable",
        };
      }
    },
  };

  const identityAuthenticator: IdentityPasswordAuthenticator = {
    async signInWithPassword({ email, password }) {
      try {
        const { error } = await supabase.auth.signInWithPassword({
          email,
          password,
        });

        if (!error) {
          return {
            status: "authenticated",
          };
        }

        if ([400, 401, 403, 422].includes(error.status ?? 0)) {
          return {
            status: "invalid-credentials",
          };
        }

        return {
          status: "service-unavailable",
        };
      } catch {
        return {
          status: "service-unavailable",
        };
      }
    },
  };
  const identityTerminator: IdentitySessionTerminator = {
    async signOut() {
      try {
        const { error } = await supabase.auth.signOut({
          scope: "local",
        });

        if (error) {
          return {
            status: "service-unavailable",
          };
        }

        return {
          status: "signed-out",
        };
      } catch {
        return {
          status: "service-unavailable",
        };
      }
    },
  };

  return {
    config: configuration.config,
    identityAuthenticator,
    identitySource,
    identityTerminator,
    status: "available",
  };
}

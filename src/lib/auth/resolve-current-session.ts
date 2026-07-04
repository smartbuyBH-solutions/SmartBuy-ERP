import { randomUUID } from "node:crypto";

import { createServerIdentityRuntime } from "@/lib/auth/server-client";
import {
  createHttpOperatorSessionGateway,
  resolveServerSession,
  type SessionResult,
} from "@/modules/session";

function identityUnavailable(): SessionResult {
  return {
    code: "IDENTITY_SERVICE_UNAVAILABLE",
    correlationId: null,
    status: "service-unavailable",
  };
}

export async function resolveCurrentServerSession(): Promise<SessionResult> {
  try {
    const identityRuntime = await createServerIdentityRuntime();

    if (identityRuntime.status === "configuration-unavailable") {
      return identityUnavailable();
    }

    const sessionGateway = createHttpOperatorSessionGateway({
      apiBaseUrl: identityRuntime.config.backendApiUrl,
    });

    return await resolveServerSession({
      correlationId: randomUUID(),
      identitySource: identityRuntime.identitySource,
      sessionGateway,
    });
  } catch {
    return identityUnavailable();
  }
}

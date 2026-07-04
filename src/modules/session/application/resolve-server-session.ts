import type { SessionResult } from "../domain/session-result";
import type {
  IdentitySessionSource,
  OperatorSessionGateway,
  OperatorSessionGatewayInput,
} from "./session-ports";

export type ResolveServerSessionInput = Readonly<{
  correlationId?: string;
  identitySource: IdentitySessionSource;
  sessionGateway: OperatorSessionGateway;
}>;

export async function resolveServerSession({
  correlationId,
  identitySource,
  sessionGateway,
}: ResolveServerSessionInput): Promise<SessionResult> {
  let identityResult: Awaited<ReturnType<IdentitySessionSource["getAccessToken"]>>;

  try {
    identityResult = await identitySource.getAccessToken();
  } catch {
    return {
      code: "IDENTITY_SERVICE_UNAVAILABLE",
      correlationId: null,
      status: "service-unavailable",
    };
  }

  if (identityResult.status === "session-expired") {
    return {
      code: "AUTHENTICATION_REQUIRED",
      correlationId: null,
      status: "session-expired",
    };
  }

  if (identityResult.status === "service-unavailable") {
    return {
      code: "IDENTITY_SERVICE_UNAVAILABLE",
      correlationId: null,
      status: "service-unavailable",
    };
  }

  const gatewayInput: OperatorSessionGatewayInput = correlationId?.trim()
    ? {
        accessToken: identityResult.accessToken,
        correlationId: correlationId.trim(),
      }
    : {
        accessToken: identityResult.accessToken,
      };

  try {
    return await sessionGateway.fetchSession(gatewayInput);
  } catch {
    return {
      code: "IDENTITY_SERVICE_UNAVAILABLE",
      correlationId: null,
      status: "service-unavailable",
    };
  }
}

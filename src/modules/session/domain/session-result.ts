import type { OperatorSession } from "./operator-session";

type SessionResultBase = Readonly<{
  correlationId: string | null;
}>;

export type AuthenticatedSessionResult = SessionResultBase &
  Readonly<{
    status: "authenticated";
    session: OperatorSession;
  }>;

export type SessionExpiredResult = SessionResultBase &
  Readonly<{
    status: "session-expired";
    code: "AUTHENTICATION_REQUIRED";
  }>;

export type AccessDeniedResult = SessionResultBase &
  Readonly<{
    status: "access-denied";
    code: "ACCESS_DENIED";
  }>;

export type IdentityServiceUnavailableResult = SessionResultBase &
  Readonly<{
    status: "service-unavailable";
    code: "IDENTITY_SERVICE_UNAVAILABLE";
  }>;

export type UnexpectedSessionResult = SessionResultBase &
  Readonly<{
    status: "unexpected-error";
    code: "UNEXPECTED_RESPONSE";
  }>;

export type SessionResult =
  | AuthenticatedSessionResult
  | SessionExpiredResult
  | AccessDeniedResult
  | IdentityServiceUnavailableResult
  | UnexpectedSessionResult;

import type { SessionResult } from "../domain/session-result";

export type IdentityAccessTokenResult =
  | Readonly<{
      accessToken: string;
      status: "authenticated";
    }>
  | Readonly<{
      status: "session-expired";
    }>
  | Readonly<{
      status: "service-unavailable";
    }>;

export interface IdentitySessionSource {
  getAccessToken(): Promise<IdentityAccessTokenResult>;
}

export type IdentitySignOutResult =
  | Readonly<{
      status: "signed-out";
    }>
  | Readonly<{
      status: "service-unavailable";
    }>;

export interface IdentitySessionTerminator {
  signOut(): Promise<IdentitySignOutResult>;
}

export type OperatorSessionGatewayInput = Readonly<{
  accessToken: string;
  correlationId?: string;
}>;

export interface OperatorSessionGateway {
  fetchSession(input: OperatorSessionGatewayInput): Promise<SessionResult>;
}

export type IdentityPasswordCredentials = Readonly<{
  email: string;
  password: string;
}>;

export type IdentityPasswordAuthenticationResult =
  | Readonly<{
      status: "authenticated";
    }>
  | Readonly<{
      status: "invalid-credentials";
    }>
  | Readonly<{
      status: "service-unavailable";
    }>;

export interface IdentityPasswordAuthenticator {
  signInWithPassword(
    credentials: IdentityPasswordCredentials,
  ): Promise<IdentityPasswordAuthenticationResult>;
}

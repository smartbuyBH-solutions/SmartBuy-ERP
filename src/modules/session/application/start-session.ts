import type {
  IdentityPasswordAuthenticationResult,
  IdentityPasswordAuthenticator,
} from "./session-ports";

export type StartSessionInput = Readonly<{
  authenticator: IdentityPasswordAuthenticator;
  email: string;
  password: string;
}>;

export type StartSessionResult =
  | IdentityPasswordAuthenticationResult
  | Readonly<{
      status: "invalid-input";
    }>;

export async function startSession({
  authenticator,
  email,
  password,
}: StartSessionInput): Promise<StartSessionResult> {
  const normalizedEmail = email.trim().toLowerCase();

  if (!normalizedEmail || !password) {
    return {
      status: "invalid-input",
    };
  }

  try {
    return await authenticator.signInWithPassword({
      email: normalizedEmail,
      password,
    });
  } catch {
    return {
      status: "service-unavailable",
    };
  }
}

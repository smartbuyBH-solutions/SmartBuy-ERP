import type { IdentitySessionTerminator, IdentitySignOutResult } from "./session-ports";

export type EndSessionInput = Readonly<{
  identityTerminator: IdentitySessionTerminator;
}>;

export async function endSession({
  identityTerminator,
}: EndSessionInput): Promise<IdentitySignOutResult> {
  try {
    return await identityTerminator.signOut();
  } catch {
    return {
      status: "service-unavailable",
    };
  }
}

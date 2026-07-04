import { describe, expect, it } from "vitest";

import type { IdentitySessionTerminator } from "./session-ports";
import { endSession } from "./end-session";

describe("endSession", () => {
  it("returns signed out when the identity session is cleared", async () => {
    const identityTerminator: IdentitySessionTerminator = {
      signOut: async () => ({
        status: "signed-out",
      }),
    };

    await expect(
      endSession({
        identityTerminator,
      }),
    ).resolves.toEqual({
      status: "signed-out",
    });
  });

  it("preserves the sanitized unavailable state", async () => {
    const identityTerminator: IdentitySessionTerminator = {
      signOut: async () => ({
        status: "service-unavailable",
      }),
    };

    await expect(
      endSession({
        identityTerminator,
      }),
    ).resolves.toEqual({
      status: "service-unavailable",
    });
  });

  it("fails safely when the identity adapter throws", async () => {
    const identityTerminator: IdentitySessionTerminator = {
      signOut: async () => {
        throw new Error("identity provider unavailable");
      },
    };

    await expect(
      endSession({
        identityTerminator,
      }),
    ).resolves.toEqual({
      status: "service-unavailable",
    });
  });
});

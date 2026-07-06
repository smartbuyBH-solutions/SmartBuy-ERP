import { describe, expect, it, vi } from "vitest";

import type { IdentityPasswordAuthenticator } from "./session-ports";
import { startSession } from "./start-session";

describe("startSession", () => {
  it("normalizes the e-mail and delegates authentication", async () => {
    const signInWithPassword = vi
      .fn<IdentityPasswordAuthenticator["signInWithPassword"]>()
      .mockResolvedValue({
        status: "authenticated",
      });

    await expect(
      startSession({
        authenticator: { signInWithPassword },
        email: "  OPERADOR@EXAMPLE.COM ",
        password: "senha-segura",
      }),
    ).resolves.toEqual({
      status: "authenticated",
    });

    expect(signInWithPassword).toHaveBeenCalledWith({
      email: "operador@example.com",
      password: "senha-segura",
    });
  });

  it("rejects incomplete credentials without calling the adapter", async () => {
    const signInWithPassword = vi
      .fn<IdentityPasswordAuthenticator["signInWithPassword"]>()
      .mockResolvedValue({
        status: "authenticated",
      });

    await expect(
      startSession({
        authenticator: { signInWithPassword },
        email: "",
        password: "",
      }),
    ).resolves.toEqual({
      status: "invalid-input",
    });

    expect(signInWithPassword).not.toHaveBeenCalled();
  });

  it("preserves the sanitized invalid-credentials result", async () => {
    const authenticator: IdentityPasswordAuthenticator = {
      signInWithPassword: async () => ({
        status: "invalid-credentials",
      }),
    };

    await expect(
      startSession({
        authenticator,
        email: "operador@example.com",
        password: "incorreta",
      }),
    ).resolves.toEqual({
      status: "invalid-credentials",
    });
  });

  it("fails safely when the identity adapter throws", async () => {
    const authenticator: IdentityPasswordAuthenticator = {
      signInWithPassword: async () => {
        throw new Error("identity provider unavailable");
      },
    };

    await expect(
      startSession({
        authenticator,
        email: "operador@example.com",
        password: "senha",
      }),
    ).resolves.toEqual({
      status: "service-unavailable",
    });
  });
});

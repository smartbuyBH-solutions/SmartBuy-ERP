import { describe, expect, it, vi } from "vitest";

import type { SessionResult } from "../domain/session-result";
import type { IdentitySessionSource, OperatorSessionGateway } from "./session-ports";
import { resolveServerSession } from "./resolve-server-session";

function createGateway(result: SessionResult) {
  const fetchSession = vi.fn<OperatorSessionGateway["fetchSession"]>().mockResolvedValue(result);

  return {
    fetchSession,
    gateway: {
      fetchSession,
    } satisfies OperatorSessionGateway,
  };
}

describe("resolveServerSession", () => {
  it("returns session expired without calling the backend", async () => {
    const identitySource: IdentitySessionSource = {
      getAccessToken: async () => ({
        status: "session-expired",
      }),
    };
    const { fetchSession, gateway } = createGateway({
      correlationId: "unused",
      session: {
        capabilities: [],
        displayName: "Unused",
        role: "unused",
        userId: "unused",
      },
      status: "authenticated",
    });

    await expect(
      resolveServerSession({
        identitySource,
        sessionGateway: gateway,
      }),
    ).resolves.toEqual({
      code: "AUTHENTICATION_REQUIRED",
      correlationId: null,
      status: "session-expired",
    });

    expect(fetchSession).not.toHaveBeenCalled();
  });

  it("returns service unavailable when the identity provider is unavailable", async () => {
    const identitySource: IdentitySessionSource = {
      getAccessToken: async () => ({
        status: "service-unavailable",
      }),
    };
    const { fetchSession, gateway } = createGateway({
      code: "UNEXPECTED_RESPONSE",
      correlationId: null,
      status: "unexpected-error",
    });

    await expect(
      resolveServerSession({
        identitySource,
        sessionGateway: gateway,
      }),
    ).resolves.toEqual({
      code: "IDENTITY_SERVICE_UNAVAILABLE",
      correlationId: null,
      status: "service-unavailable",
    });

    expect(fetchSession).not.toHaveBeenCalled();
  });

  it("fails safely when the identity source throws", async () => {
    const identitySource: IdentitySessionSource = {
      getAccessToken: async () => {
        throw new Error("provider unavailable");
      },
    };
    const { fetchSession, gateway } = createGateway({
      code: "UNEXPECTED_RESPONSE",
      correlationId: null,
      status: "unexpected-error",
    });

    await expect(
      resolveServerSession({
        identitySource,
        sessionGateway: gateway,
      }),
    ).resolves.toEqual({
      code: "IDENTITY_SERVICE_UNAVAILABLE",
      correlationId: null,
      status: "service-unavailable",
    });

    expect(fetchSession).not.toHaveBeenCalled();
  });

  it("delegates an authenticated bearer token to the session gateway", async () => {
    const authenticatedResult: SessionResult = {
      correlationId: "corr-response",
      session: {
        capabilities: ["dashboard.read"],
        displayName: "Operador",
        role: "operator",
        userId: "user-123",
      },
      status: "authenticated",
    };
    const identitySource: IdentitySessionSource = {
      getAccessToken: async () => ({
        accessToken: "verified-access-token",
        status: "authenticated",
      }),
    };
    const { fetchSession, gateway } = createGateway(authenticatedResult);

    await expect(
      resolveServerSession({
        correlationId: " corr-request ",
        identitySource,
        sessionGateway: gateway,
      }),
    ).resolves.toEqual(authenticatedResult);

    expect(fetchSession).toHaveBeenCalledOnce();
    expect(fetchSession).toHaveBeenCalledWith({
      accessToken: "verified-access-token",
      correlationId: "corr-request",
    });
  });

  it("preserves a sanitized denial returned by the backend", async () => {
    const identitySource: IdentitySessionSource = {
      getAccessToken: async () => ({
        accessToken: "verified-access-token",
        status: "authenticated",
      }),
    };
    const { gateway } = createGateway({
      code: "ACCESS_DENIED",
      correlationId: "corr-denied",
      status: "access-denied",
    });

    await expect(
      resolveServerSession({
        identitySource,
        sessionGateway: gateway,
      }),
    ).resolves.toEqual({
      code: "ACCESS_DENIED",
      correlationId: "corr-denied",
      status: "access-denied",
    });
  });

  it("fails safely when the session gateway throws", async () => {
    const identitySource: IdentitySessionSource = {
      getAccessToken: async () => ({
        accessToken: "verified-access-token",
        status: "authenticated",
      }),
    };
    const gateway: OperatorSessionGateway = {
      fetchSession: async () => {
        throw new Error("backend unavailable");
      },
    };

    await expect(
      resolveServerSession({
        identitySource,
        sessionGateway: gateway,
      }),
    ).resolves.toEqual({
      code: "IDENTITY_SERVICE_UNAVAILABLE",
      correlationId: null,
      status: "service-unavailable",
    });
  });
});

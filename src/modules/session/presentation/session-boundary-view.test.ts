import { describe, expect, it } from "vitest";

import type { NonAuthenticatedSessionResult } from "./session-boundary-view";
import { getSessionBoundaryView } from "./session-boundary-view";

const cases: readonly Readonly<{
  expectedTitle: string;
  result: NonAuthenticatedSessionResult;
}>[] = [
  {
    expectedTitle: "Sessão expirada",
    result: {
      code: "AUTHENTICATION_REQUIRED",
      correlationId: null,
      status: "session-expired",
    },
  },
  {
    expectedTitle: "Acesso não autorizado",
    result: {
      code: "ACCESS_DENIED",
      correlationId: "corr-denied",
      status: "access-denied",
    },
  },
  {
    expectedTitle: "Serviço de identidade indisponível",
    result: {
      code: "IDENTITY_SERVICE_UNAVAILABLE",
      correlationId: null,
      status: "service-unavailable",
    },
  },
  {
    expectedTitle: "Não foi possível validar a sessão",
    result: {
      code: "UNEXPECTED_RESPONSE",
      correlationId: "corr-unexpected",
      status: "unexpected-error",
    },
  },
];

describe("getSessionBoundaryView", () => {
  it.each(cases)(
    "maps $result.status to a controlled presentation",
    ({ expectedTitle, result }) => {
      const view = getSessionBoundaryView(result);

      expect(view.title).toBe(expectedTitle);
      expect(view.actionLabel.length).toBeGreaterThan(0);
      expect(view.description.length).toBeGreaterThan(0);
      expect(["danger", "warning"]).toContain(view.tone);
    },
  );
});

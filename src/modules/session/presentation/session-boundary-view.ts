import type { SessionResult } from "../domain/session-result";

export type NonAuthenticatedSessionResult = Exclude<
  SessionResult,
  Readonly<{
    status: "authenticated";
  }>
>;

export type SessionBoundaryView = Readonly<{
  actionLabel: string;
  description: string;
  eyebrow: string;
  title: string;
  tone: "danger" | "warning";
}>;

const sessionBoundaryViews = {
  "access-denied": {
    actionLabel: "Revalidar acesso",
    description:
      "Sua identidade foi reconhecida, mas não existe autorização explícita para acessar esta área.",
    eyebrow: "Acesso ao ERP",
    title: "Acesso não autorizado",
    tone: "danger",
  },
  "service-unavailable": {
    actionLabel: "Tentar novamente",
    description:
      "O serviço responsável pela identidade está temporariamente indisponível. Nenhuma operação foi liberada.",
    eyebrow: "Validação de identidade",
    title: "Serviço de identidade indisponível",
    tone: "warning",
  },
  "session-expired": {
    actionLabel: "Revalidar sessão",
    description:
      "A sessão não está mais válida. Refaça o fluxo corporativo de autenticação para continuar.",
    eyebrow: "Acesso ao ERP",
    title: "Sessão expirada",
    tone: "warning",
  },
  "unexpected-error": {
    actionLabel: "Tentar novamente",
    description:
      "A resposta de identidade não pôde ser validada com segurança. O acesso permaneceu bloqueado.",
    eyebrow: "Validação de identidade",
    title: "Não foi possível validar a sessão",
    tone: "danger",
  },
} as const satisfies Record<NonAuthenticatedSessionResult["status"], SessionBoundaryView>;

export function getSessionBoundaryView(result: NonAuthenticatedSessionResult): SessionBoundaryView {
  return sessionBoundaryViews[result.status];
}

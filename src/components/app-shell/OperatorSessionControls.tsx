"use client";

import { useActionState } from "react";

import { logoutAction } from "@/app/(erp)/actions";

import styles from "./AppShell.module.css";

type LogoutActionState = Awaited<ReturnType<typeof logoutAction>>;

const initialLogoutState: LogoutActionState = {
  status: "idle",
};

type OperatorSessionControlsProps = Readonly<{
  displayName: string;
  role: string;
}>;

export function OperatorSessionControls({ displayName, role }: OperatorSessionControlsProps) {
  const [state, formAction, isPending] = useActionState(logoutAction, initialLogoutState);

  return (
    <section aria-label="Sessão do operador" className={styles.operatorSession}>
      <div className={styles.operatorIdentity}>
        <span className={styles.operatorEyebrow}>Operador autenticado</span>

        <strong className={styles.operatorName}>{displayName}</strong>

        <span className={styles.operatorRole}>{role}</span>
      </div>

      <form action={formAction} className={styles.logoutForm}>
        <button
          aria-describedby={state.status === "error" ? "logout-error" : undefined}
          className={styles.logoutButton}
          disabled={isPending}
          type="submit"
        >
          {isPending ? "Encerrando..." : "Sair"}
        </button>
      </form>

      {state.status === "error" ? (
        <p className={styles.logoutError} id="logout-error" role="alert">
          Não foi possível encerrar a sessão. Tente novamente.
        </p>
      ) : null}
    </section>
  );
}

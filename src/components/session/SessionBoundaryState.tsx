import Link from "next/link";

import type { NonAuthenticatedSessionResult } from "@/modules/session/presentation/session-boundary-view";
import { getSessionBoundaryView } from "@/modules/session/presentation/session-boundary-view";

import styles from "./SessionBoundaryState.module.css";

type SessionBoundaryStateProps = Readonly<{
  result: NonAuthenticatedSessionResult;
}>;

export function SessionBoundaryState({ result }: SessionBoundaryStateProps) {
  const view = getSessionBoundaryView(result);

  return (
    <main className={styles.viewport}>
      <section
        aria-labelledby="session-boundary-title"
        aria-live="assertive"
        className={styles.card}
        data-tone={view.tone}
        role="alert"
      >
        <span aria-hidden="true" className={styles.indicator} />

        <p className={styles.eyebrow}>{view.eyebrow}</p>

        <h1 className={styles.title} id="session-boundary-title">
          {view.title}
        </h1>

        <p className={styles.description}>{view.description}</p>

        {result.correlationId ? (
          <p className={styles.supportCode}>
            Código de suporte: <code>{result.correlationId}</code>
          </p>
        ) : null}

        <Link className={styles.action} href="/">
          {view.actionLabel}
        </Link>
      </section>
    </main>
  );
}

export function SessionBoundaryLoading() {
  return (
    <main className={styles.viewport}>
      <section aria-busy="true" aria-live="polite" className={styles.card} role="status">
        <span aria-hidden="true" className={`${styles.indicator} ${styles.loadingIndicator}`} />

        <p className={styles.eyebrow}>Acesso ao ERP</p>

        <h1 className={styles.title}>Validando sessão</h1>

        <p className={styles.description}>
          Aguarde enquanto a identidade e as permissões são verificadas.
        </p>

        <span aria-hidden="true" className={styles.loadingTrack}>
          <span className={styles.loadingBar} />
        </span>
      </section>
    </main>
  );
}

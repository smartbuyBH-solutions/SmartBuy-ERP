import type { ReactNode } from "react";

import { navigationItems, selectNavigationItems } from "@/config/navigation";
import type { OperatorSession } from "@/modules/session";

import { AppNavigation } from "./AppNavigation";
import { OperatorSessionControls } from "./OperatorSessionControls";

import styles from "./AppShell.module.css";

type AppShellProps = Readonly<{
  children: ReactNode;
  session: OperatorSession;
}>;

export function AppShell({ children, session }: AppShellProps) {
  const visibleNavigationItems = selectNavigationItems(navigationItems, session.capabilities);

  return (
    <div className={styles.shell}>
      <a className={styles.skipLink} href="#conteudo-principal">
        Pular para o conteúdo
      </a>

      <header className={styles.header}>
        <div className={styles.headerInner}>
          <div className={styles.brand}>
            <span aria-hidden="true" className={styles.brandMark}>
              SB
            </span>

            <div>
              <p className={styles.brandName}>SmartBuyBH ERP</p>

              <p className={styles.brandDescription}>Pré-atendimento e apoio operacional</p>
            </div>
          </div>

          <div className={styles.headerActions}>
            <div className={styles.headerStatus}>
              <span aria-hidden="true" className={styles.statusDot} />
              Ambiente operacional
            </div>

            <OperatorSessionControls displayName={session.displayName} role={session.role} />
          </div>
        </div>
      </header>

      <div className={styles.shellBody}>
        <aside aria-label="Navegação do aplicativo" className={styles.sidebar}>
          <AppNavigation items={visibleNavigationItems} />

          <section aria-labelledby="sales-record-title" className={styles.sidebarNote}>
            <p className={styles.sidebarNoteTitle} id="sales-record-title">
              Registro final
            </p>

            <p className={styles.sidebarNoteText}>
              A conclusão da venda permanece no MercadoPhone.
            </p>
          </section>
        </aside>

        <main className={styles.mainContent} id="conteudo-principal" tabIndex={-1}>
          {children}
        </main>
      </div>
    </div>
  );
}

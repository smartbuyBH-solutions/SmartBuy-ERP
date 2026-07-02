import type { ReactNode } from "react";

import { AppNavigation } from "./AppNavigation";

import styles from "./AppShell.module.css";

type AppShellProps = Readonly<{
  children: ReactNode;
}>;

export function AppShell({ children }: AppShellProps) {
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

          <div className={styles.headerStatus}>
            <span aria-hidden="true" className={styles.statusDot} />
            Ambiente operacional
          </div>
        </div>
      </header>

      <div className={styles.shellBody}>
        <aside aria-label="Navegação do aplicativo" className={styles.sidebar}>
          <AppNavigation />

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

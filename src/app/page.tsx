import styles from "./page.module.css";

const implementationMetrics = [
  {
    label: "Fundação técnica",
    value: "Ativa",
  },
  {
    label: "Design System",
    value: "44 tokens",
  },
  {
    label: "Application Shell",
    value: "Em implantação",
  },
  {
    label: "Integrações",
    value: "Planejadas",
  },
] as const;

const plannedModules = [
  "Atendimentos e histórico comercial",
  "Orçamentos e listas",
  "Estoque e seminovos",
  "Upgrade e avaliação",
  "Entregas e pós-venda",
  "Assistência técnica",
] as const;

export default function ErpHome() {
  return (
    <div className={styles.page}>
      <section
        aria-labelledby="overview-title"
        className={styles.hero}
      >
        <div>
          <p className={styles.eyebrow}>
            Visão geral
          </p>

          <h1
            className={styles.title}
            id="overview-title"
          >
            Central operacional
          </h1>

          <p className={styles.description}>
            Acompanhe a implantação da plataforma
            de pré-atendimento da Smart Buy BH.
          </p>
        </div>

        <span className={styles.statusBadge}>
          <span
            aria-hidden="true"
            className={styles.statusDot}
          />

          Fundação ativa
        </span>
      </section>

      <section
        aria-label="Resumo da implantação"
        className="sb-dashboard-grid"
      >
        {implementationMetrics.map((metric) => (
          <article
            className="sb-panel"
            key={metric.label}
          >
            <p className={styles.metricValue}>
              {metric.value}
            </p>

            <p className={styles.metricLabel}>
              {metric.label}
            </p>
          </article>
        ))}
      </section>

      <section className="sb-parallel-grid">
        <article className="sb-panel">
          <h2 className="sb-panel-title">
            Módulos operacionais
          </h2>

          <p className={styles.panelText}>
            A navegação principal já
            está preparada. Os módulos serão
            habilitados nas próximas fases.
          </p>

          <ul className={styles.moduleList}>
            {plannedModules.map((moduleName) => (
              <li
                className={styles.moduleItem}
                key={moduleName}
              >
                <span>{moduleName}</span>

                <span className={styles.moduleStatus}>
                  Planejado
                </span>
              </li>
            ))}
          </ul>
        </article>

        <article className="sb-panel">
          <h2 className="sb-panel-title">
            MercadoPhone permanece como registro final
          </h2>

          <p className={styles.panelText}>
            O SmartBuyBH ERP organiza o pré-atendimento
            e o apoio operacional. A conclusão da venda
            continua no MercadoPhone.
          </p>

          <span className={styles.roleBadge}>
            Papel operacional definido
          </span>

          <div className={styles.nextStep}>
            <p className={styles.nextStepTitle}>
              Próxima etapa
            </p>

            <p className={styles.nextStepText}>
              Implementar os primeiros fluxos funcionais sobre
              esta fundação.
            </p>
          </div>
        </article>
      </section>
    </div>
  );
}

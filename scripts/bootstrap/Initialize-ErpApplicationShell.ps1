[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectRoot,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[0-9a-f]{7,40}$")]
    [string]$ExpectedHead
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Utf8NoBom =
    New-Object System.Text.UTF8Encoding($false)

$AcuteLowerA = [char]0x00E1
$AcuteLowerE = [char]0x00E9
$AcuteLowerO = [char]0x00F3
$AcuteLowerU = [char]0x00FA
$TildeLowerA = [char]0x00E3
$TildeLowerO = [char]0x00F5
$CedillaLowerC = [char]0x00E7
$CircumflexLowerE = [char]0x00EA

function Write-Utf8File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    $NormalizedContent =
        $Content.Trim([char[]]"`r`n") + "`n"

    [System.IO.File]::WriteAllText(
        $Path,
        $NormalizedContent,
        $Utf8NoBom
    )
}

function Normalize-Text {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    return (
        $Text.
            Replace("`r`n", "`n").
            Trim([char[]]"`n")
    )
}

function Assert-TargetsAbsent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$RelativePaths
    )

    foreach ($RelativePath in $RelativePaths) {
        if (Test-Path -LiteralPath $RelativePath) {
            throw "Operacao bloqueada: $RelativePath ja existe."
        }
    }
}

function Assert-ExactBaseline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LayoutPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PagePath
    )

    $ExpectedLayout = @"
import type { Metadata } from "next";
import type { ReactNode } from "react";

import "./globals.css";

export const metadata: Metadata = {
  title: "SmartBuyBH ERP",
  description:
    "Plataforma de pr${AcuteLowerE}-atendimento e apoio operacional da Smart Buy BH.",
};

type RootLayoutProps = Readonly<{
  children: ReactNode;
}>;

export default function RootLayout({
  children,
}: RootLayoutProps) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
"@

    $ExpectedPage = @"
export default function ErpHome() {
  return (
    <main>
      <h1>SmartBuyBH ERP</h1>
      <p>Funda${CedillaLowerC}${TildeLowerA}o t${AcuteLowerE}cnica inicializada.</p>
    </main>
  );
}
"@

    $ActualLayout =
        Normalize-Text `
            -Text (
                [System.IO.File]::ReadAllText(
                    $LayoutPath
                )
            )

    $ActualPage =
        Normalize-Text `
            -Text (
                [System.IO.File]::ReadAllText(
                    $PagePath
                )
            )

    if (
        $ActualLayout -ne
        (Normalize-Text -Text $ExpectedLayout)
    ) {
        throw "layout.tsx divergiu da baseline aprovada."
    }

    if (
        $ActualPage -ne
        (Normalize-Text -Text $ExpectedPage)
    ) {
        throw "page.tsx divergiu da baseline aprovada."
    }
}

function Write-ApplicationShellFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Root
    )

    $ApplicationShellDirectory =
        Join-Path `
            $Root `
            "src\components\app-shell"

    $ConfigDirectory =
        Join-Path `
            $Root `
            "src\config"

    [void](
        New-Item `
            -ItemType Directory `
            -Path $ApplicationShellDirectory `
            -Force
    )

    [void](
        New-Item `
            -ItemType Directory `
            -Path $ConfigDirectory `
            -Force
    )

    $NavigationTs = @"
type NavigationItemBase = Readonly<{
  id: string;
  label: string;
  shortLabel: string;
}>;

type AvailableNavigationItem =
  NavigationItemBase &
  Readonly<{
    availability: "available";
    href: string;
  }>;

type PlannedNavigationItem =
  NavigationItemBase &
  Readonly<{
    availability: "planned";
    href: null;
  }>;

export type NavigationItem =
  | AvailableNavigationItem
  | PlannedNavigationItem;

export const navigationItems = [
  {
    id: "overview",
    label: "Vis${TildeLowerA}o geral",
    shortLabel: "VG",
    availability: "available",
    href: "/",
  },
  {
    id: "lists",
    label: "Padroniza${CedillaLowerC}${TildeLowerA}o de listas",
    shortLabel: "LS",
    availability: "planned",
    href: null,
  },
  {
    id: "services",
    label: "Atendimentos",
    shortLabel: "AT",
    availability: "planned",
    href: null,
  },
  {
    id: "quotes",
    label: "Or${CedillaLowerC}amentos",
    shortLabel: "OR",
    availability: "planned",
    href: null,
  },
  {
    id: "upgrade",
    label: "Avalia${CedillaLowerC}${TildeLowerA}o para upgrade",
    shortLabel: "UP",
    availability: "planned",
    href: null,
  },
  {
    id: "preowned",
    label: "Controle de seminovos",
    shortLabel: "SE",
    availability: "planned",
    href: null,
  },
  {
    id: "deliveries",
    label: "Confirma${CedillaLowerC}${TildeLowerA}o de entrega",
    shortLabel: "EN",
    availability: "planned",
    href: null,
  },
  {
    id: "commercial-intelligence",
    label: "Intelig${CircumflexLowerE}ncia comercial",
    shortLabel: "IC",
    availability: "planned",
    href: null,
  },
  {
    id: "technical-support",
    label: "Assist${CircumflexLowerE}ncia t${AcuteLowerE}cnica",
    shortLabel: "AS",
    availability: "planned",
    href: null,
  },
] as const satisfies readonly NavigationItem[];
"@

    $AppNavigationTsx = @"
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { navigationItems } from "@/config/navigation";

import styles from "./AppShell.module.css";

export function AppNavigation() {
  const pathname = usePathname();

  return (
    <nav
      aria-label="Navega${CedillaLowerC}${TildeLowerA}o principal"
      className={styles.navigation}
    >
      <p className={styles.navigationLabel}>
        M${AcuteLowerO}dulos
      </p>

      <ul className={styles.navigationList}>
        {navigationItems.map((item) => {
          const isAvailable =
            item.availability === "available";

          const isActive =
            isAvailable &&
            pathname === item.href;

          const itemClassName = [
            styles.navigationItem,
            isActive
              ? styles.navigationItemActive
              : "",
          ]
            .filter(Boolean)
            .join(" ");

          return (
            <li key={item.id}>
              {isAvailable ? (
                <Link
                  aria-current={
                    isActive ? "page" : undefined
                  }
                  className={itemClassName}
                  href={item.href}
                >
                  <span
                    aria-hidden="true"
                    className={styles.navigationGlyph}
                  >
                    {item.shortLabel}
                  </span>

                  <span className={styles.navigationText}>
                    {item.label}
                  </span>
                </Link>
              ) : (
                <span
                  aria-disabled="true"
                  className={[
                    itemClassName,
                    styles.navigationItemDisabled,
                  ].join(" ")}
                >
                  <span
                    aria-hidden="true"
                    className={styles.navigationGlyph}
                  >
                    {item.shortLabel}
                  </span>

                  <span className={styles.navigationText}>
                    {item.label}
                  </span>

                  <span className={styles.navigationStatus}>
                    Em breve
                  </span>
                </span>
              )}
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
"@

    $AppShellTsx = @"
import type { ReactNode } from "react";

import { AppNavigation } from "./AppNavigation";

import styles from "./AppShell.module.css";

type AppShellProps = Readonly<{
  children: ReactNode;
}>;

export function AppShell({
  children,
}: AppShellProps) {
  return (
    <div className={styles.shell}>
      <a
        className={styles.skipLink}
        href="#conteudo-principal"
      >
        Pular para o conte${AcuteLowerU}do
      </a>

      <header className={styles.header}>
        <div className={styles.headerInner}>
          <div className={styles.brand}>
            <span
              aria-hidden="true"
              className={styles.brandMark}
            >
              SB
            </span>

            <div>
              <p className={styles.brandName}>
                SmartBuyBH ERP
              </p>

              <p className={styles.brandDescription}>
                Pr${AcuteLowerE}-atendimento e apoio operacional
              </p>
            </div>
          </div>

          <div className={styles.headerStatus}>
            <span
              aria-hidden="true"
              className={styles.statusDot}
            />

            Ambiente operacional
          </div>
        </div>
      </header>

      <div className={styles.shellBody}>
        <aside
          aria-label="Navega${CedillaLowerC}${TildeLowerA}o do aplicativo"
          className={styles.sidebar}
        >
          <AppNavigation />

          <section
            aria-labelledby="sales-record-title"
            className={styles.sidebarNote}
          >
            <p
              className={styles.sidebarNoteTitle}
              id="sales-record-title"
            >
              Registro final
            </p>

            <p className={styles.sidebarNoteText}>
              A conclus${TildeLowerA}o da venda permanece no
              MercadoPhone.
            </p>
          </section>
        </aside>

        <main
          className={styles.mainContent}
          id="conteudo-principal"
          tabIndex={-1}
        >
          {children}
        </main>
      </div>
    </div>
  );
}
"@

    $AppShellCss = @"
.shell {
  min-height: 100vh;
  background: var(--bg-body);
}

.skipLink {
  position: fixed;
  top: 8px;
  left: 8px;
  z-index: 100;
  padding: 8px 12px;
  color: var(--branco);
  background: var(--brand-primary);
  border-radius: var(--radius-sm);
  font-size: 0.8125rem;
  font-weight: 700;
  text-decoration: none;
  transform: translateY(-160%);
  transition: var(--transition);
}

.skipLink:focus {
  transform: translateY(0);
}

.header {
  position: sticky;
  top: 0;
  z-index: 30;
  background: var(--bg-surface);
  border-bottom: 1px solid var(--border-color);
  box-shadow: var(--shadow-sm);
}

.headerInner {
  width: 100%;
  max-width: 1500px;
  min-height: 64px;
  margin-inline: auto;
  padding: 12px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.brand {
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 12px;
}

.brandMark {
  width: 40px;
  height: 40px;
  flex: 0 0 40px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--branco);
  background: var(--brand-primary);
  border-radius: var(--radius-sm);
  font-size: 0.875rem;
  font-weight: 800;
  letter-spacing: 0.04em;
}

.brandName,
.brandDescription {
  margin: 0;
}

.brandName {
  color: var(--text-primary);
  font-size: 1rem;
  font-weight: 800;
}

.brandDescription {
  margin-top: 2px;
  color: var(--text-secondary);
  font-size: 0.75rem;
  font-weight: 500;
}

.headerStatus {
  flex: 0 0 auto;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  color: var(--text-primary);
  background: var(--neutral-light);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-full);
  font-size: 0.75rem;
  font-weight: 700;
}

.statusDot {
  width: 8px;
  height: 8px;
  border-radius: var(--radius-full);
  background: var(--success);
}

.shellBody {
  width: 100%;
  max-width: 1500px;
  min-height: calc(100vh - 65px);
  margin-inline: auto;
  display: grid;
  grid-template-columns:
    248px
    minmax(0, 1fr);
}

.sidebar {
  position: sticky;
  top: 65px;
  align-self: start;
  height: calc(100vh - 65px);
  padding: 16px;
  overflow-y: auto;
  background: var(--bg-surface);
  border-right: 1px solid var(--border-color);
}

.navigationLabel {
  margin: 0 0 8px;
  color: var(--text-tertiary);
  font-size: 0.6875rem;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.navigationList {
  margin: 0;
  padding: 0;
  display: grid;
  gap: 4px;
  list-style: none;
}

.navigationItem {
  min-height: 42px;
  padding: 7px 8px;
  display: grid;
  grid-template-columns:
    30px
    minmax(0, 1fr)
    auto;
  align-items: center;
  gap: 8px;
  color: var(--text-secondary);
  background: transparent;
  border: 1px solid transparent;
  border-radius: var(--radius-sm);
  font-size: 0.8125rem;
  font-weight: 650;
  text-decoration: none;
  transition: var(--transition);
}

a.navigationItem:hover {
  color: var(--text-primary);
  background: var(--neutral-light);
  border-color: var(--border-color);
}

.navigationItemActive {
  color: var(--text-primary);
  background: var(--neutral-light);
  border-color: var(--brand-primary);
  box-shadow: var(--shadow-sm);
}

.navigationItemDisabled {
  cursor: not-allowed;
  opacity: 0.72;
}

.navigationGlyph {
  width: 30px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--text-primary);
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-sm);
  font-size: 0.625rem;
  font-weight: 800;
  letter-spacing: 0.04em;
}

.navigationItemActive .navigationGlyph {
  color: var(--branco);
  background: var(--brand-primary);
  border-color: var(--brand-primary);
}

.navigationText {
  min-width: 0;
  line-height: 1.25;
}

.navigationStatus {
  padding: 2px 6px;
  color: var(--text-tertiary);
  background: var(--neutral-light);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-full);
  font-size: 0.625rem;
  font-weight: 700;
  white-space: nowrap;
}

.sidebarNote {
  margin-top: 16px;
  padding: 12px;
  background: var(--info-light);
  border: 1px solid var(--info);
  border-radius: var(--radius-md);
}

.sidebarNoteTitle,
.sidebarNoteText {
  margin: 0;
}

.sidebarNoteTitle {
  color: var(--text-primary);
  font-size: 0.75rem;
  font-weight: 800;
}

.sidebarNoteText {
  margin-top: 4px;
  color: var(--text-secondary);
  font-size: 0.75rem;
  line-height: 1.45;
}

.mainContent {
  min-width: 0;
  padding: 16px;
}

.mainContent:focus {
  outline: none;
}

@media (max-width: 900px) {
  .shellBody {
    grid-template-columns: minmax(0, 1fr);
  }

  .sidebar {
    position: static;
    height: auto;
    border-right: 0;
    border-bottom: 1px solid var(--border-color);
  }

  .navigationList {
    grid-template-columns:
      repeat(9, minmax(180px, 1fr));
    overflow-x: auto;
    padding-bottom: 4px;
  }

  .sidebarNote {
    display: none;
  }
}

@media (max-width: 640px) {
  .headerInner {
    min-height: auto;
    align-items: flex-start;
    flex-direction: column;
    gap: 10px;
  }

  .headerStatus {
    align-self: stretch;
    justify-content: center;
  }

  .sidebar,
  .mainContent {
    padding: 12px;
  }

  .navigationList {
    grid-template-columns:
      repeat(9, minmax(168px, 1fr));
  }
}

@media (prefers-reduced-motion: reduce) {
  .skipLink,
  .navigationItem {
    transition: none;
  }
}
"@

    $PageCss = @"
.page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.hero {
  padding: 16px;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-sm);
}

.eyebrow,
.title,
.description {
  margin: 0;
}

.eyebrow {
  color: var(--text-secondary);
  font-size: 0.6875rem;
  font-weight: 800;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.title {
  margin-top: 4px;
  color: var(--text-primary);
  font-size: clamp(1.375rem, 2vw, 1.75rem);
  font-weight: 800;
  line-height: 1.2;
}

.description {
  max-width: 720px;
  margin-top: 6px;
  color: var(--text-secondary);
  font-size: 0.875rem;
}

.statusBadge {
  flex: 0 0 auto;
  padding: 6px 10px;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: var(--success-dark);
  background: var(--success-light);
  border: 1px solid var(--success);
  border-radius: var(--radius-full);
  font-size: 0.75rem;
  font-weight: 800;
}

.statusDot {
  width: 8px;
  height: 8px;
  border-radius: var(--radius-full);
  background: var(--success);
}

.metricValue,
.metricLabel {
  margin: 0;
}

.metricValue {
  color: var(--text-primary);
  font-size: 1.25rem;
  font-weight: 800;
}

.metricLabel {
  margin-top: 4px;
  color: var(--text-secondary);
  font-size: 0.75rem;
  font-weight: 600;
}

.panelText {
  margin: 8px 0 0;
  color: var(--text-secondary);
  font-size: 0.8125rem;
}

.moduleList {
  margin: 12px 0 0;
  padding: 0;
  display: grid;
  gap: 8px;
  list-style: none;
}

.moduleItem {
  padding: 8px 10px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  color: var(--text-primary);
  background: var(--neutral-light);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-sm);
  font-size: 0.8125rem;
  font-weight: 650;
}

.moduleStatus {
  color: var(--text-tertiary);
  font-size: 0.6875rem;
  font-weight: 700;
  white-space: nowrap;
}

.roleBadge {
  margin-top: 12px;
  padding: 6px 10px;
  display: inline-flex;
  color: var(--info);
  background: var(--info-light);
  border: 1px solid var(--info);
  border-radius: var(--radius-full);
  font-size: 0.75rem;
  font-weight: 800;
}

.nextStep {
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid var(--border-color);
}

.nextStepTitle,
.nextStepText {
  margin: 0;
}

.nextStepTitle {
  color: var(--text-primary);
  font-size: 0.8125rem;
  font-weight: 800;
}

.nextStepText {
  margin-top: 4px;
  color: var(--text-secondary);
  font-size: 0.8125rem;
}

@media (max-width: 640px) {
  .hero {
    flex-direction: column;
  }

  .statusBadge {
    align-self: stretch;
    justify-content: center;
  }
}
"@

    $LayoutTsx = @"
import type { Metadata } from "next";
import type { ReactNode } from "react";

import { AppShell } from "@/components/app-shell/AppShell";

import "./globals.css";

export const metadata: Metadata = {
  title: "SmartBuyBH ERP",
  description:
    "Plataforma de pr${AcuteLowerE}-atendimento e apoio operacional da Smart Buy BH.",
};

type RootLayoutProps = Readonly<{
  children: ReactNode;
}>;

export default function RootLayout({
  children,
}: RootLayoutProps) {
  return (
    <html lang="pt-BR">
      <body>
        <AppShell>{children}</AppShell>
      </body>
    </html>
  );
}
"@

    $PageTsx = @"
import styles from "./page.module.css";

const implementationMetrics = [
  {
    label: "Funda${CedillaLowerC}${TildeLowerA}o t${AcuteLowerE}cnica",
    value: "Ativa",
  },
  {
    label: "Design System",
    value: "44 tokens",
  },
  {
    label: "Application Shell",
    value: "Em implanta${CedillaLowerC}${TildeLowerA}o",
  },
  {
    label: "Integra${CedillaLowerC}${TildeLowerO}es",
    value: "Planejadas",
  },
] as const;

const plannedModules = [
  "Atendimentos e hist${AcuteLowerO}rico comercial",
  "Or${CedillaLowerC}amentos e listas",
  "Estoque e seminovos",
  "Upgrade e avalia${CedillaLowerC}${TildeLowerA}o",
  "Entregas e p${AcuteLowerO}s-venda",
  "Assist${CircumflexLowerE}ncia t${AcuteLowerE}cnica",
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
            Vis${TildeLowerA}o geral
          </p>

          <h1
            className={styles.title}
            id="overview-title"
          >
            Central operacional
          </h1>

          <p className={styles.description}>
            Acompanhe a implanta${CedillaLowerC}${TildeLowerA}o da plataforma
            de pr${AcuteLowerE}-atendimento da Smart Buy BH.
          </p>
        </div>

        <span className={styles.statusBadge}>
          <span
            aria-hidden="true"
            className={styles.statusDot}
          />

          Funda${CedillaLowerC}${TildeLowerA}o ativa
        </span>
      </section>

      <section
        aria-label="Resumo da implanta${CedillaLowerC}${TildeLowerA}o"
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
            M${AcuteLowerO}dulos operacionais
          </h2>

          <p className={styles.panelText}>
            A navega${CedillaLowerC}${TildeLowerA}o principal j${AcuteLowerA}
            est${AcuteLowerA} preparada. Os m${AcuteLowerO}dulos ser${TildeLowerA}o
            habilitados nas pr${AcuteLowerO}ximas fases.
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
            O SmartBuyBH ERP organiza o pr${AcuteLowerE}-atendimento
            e o apoio operacional. A conclus${TildeLowerA}o da venda
            continua no MercadoPhone.
          </p>

          <span className={styles.roleBadge}>
            Papel operacional definido
          </span>

          <div className={styles.nextStep}>
            <p className={styles.nextStepTitle}>
              Pr${AcuteLowerO}xima etapa
            </p>

            <p className={styles.nextStepText}>
              Implementar os primeiros fluxos funcionais sobre
              esta funda${CedillaLowerC}${TildeLowerA}o.
            </p>
          </div>
        </article>
      </section>
    </div>
  );
}
"@

    $Files = [ordered]@{
        "src\config\navigation.ts" =
            $NavigationTs

        "src\components\app-shell\AppNavigation.tsx" =
            $AppNavigationTsx

        "src\components\app-shell\AppShell.tsx" =
            $AppShellTsx

        "src\components\app-shell\AppShell.module.css" =
            $AppShellCss

        "src\app\page.module.css" =
            $PageCss

        "src\app\layout.tsx" =
            $LayoutTsx

        "src\app\page.tsx" =
            $PageTsx
    }

    foreach ($RelativePath in $Files.Keys) {
        Write-Utf8File `
            -Path (Join-Path $Root $RelativePath) `
            -Content $Files[$RelativePath]
    }
}

$ResolvedRoot = (
    Resolve-Path -LiteralPath $ProjectRoot
).Path

Set-Location -LiteralPath $ResolvedRoot

$ModulePath = Join-Path `
    $ResolvedRoot `
    "scripts\lib\DependencyGuards.psm1"

if (-not (Test-Path -LiteralPath $ModulePath -PathType Leaf)) {
    throw "Modulo DependencyGuards nao encontrado."
}

Import-Module `
    $ModulePath `
    -Force

$ResolvedRoot = Assert-GitRepositoryReady `
    -ProjectRoot $ResolvedRoot `
    -ExpectedHead $ExpectedHead `
    -RequireClean

$LayoutPath =
    Join-Path $ResolvedRoot "src\app\layout.tsx"

$PagePath =
    Join-Path $ResolvedRoot "src\app\page.tsx"

foreach (
    $RequiredPath in
    @(
        $LayoutPath,
        $PagePath,
        (
            Join-Path `
                $ResolvedRoot `
                "src\styles\tokens.css"
        ),
        (
            Join-Path `
                $ResolvedRoot `
                "src\styles\theme.css"
        ),
        (
            Join-Path `
                $ResolvedRoot `
                "src\styles\utilities.css"
        )
    )
) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "Arquivo obrigatorio ausente: $RequiredPath"
    }
}

$NewShellFiles = @(
    "src\config\navigation.ts",
    "src\components\app-shell\AppNavigation.tsx",
    "src\components\app-shell\AppShell.tsx",
    "src\components\app-shell\AppShell.module.css",
    "src\app\page.module.css"
)

Assert-TargetsAbsent `
    -RelativePaths $NewShellFiles

Assert-ExactBaseline `
    -LayoutPath $LayoutPath `
    -PagePath $PagePath

Write-Host "========================================"
Write-Host "CRIANDO APPLICATION SHELL"
Write-Host "========================================"

Write-ApplicationShellFiles `
    -Root $ResolvedRoot

$ExpectedChanges = @{
    "src/app/layout.tsx" =
        " M"

    "src/app/page.tsx" =
        " M"

    "src/app/page.module.css" =
        "??"

    "src/components/app-shell/AppNavigation.tsx" =
        "??"

    "src/components/app-shell/AppShell.module.css" =
        "??"

    "src/components/app-shell/AppShell.tsx" =
        "??"

    "src/config/navigation.ts" =
        "??"
}

$ChangedEntries = @(
    git status --porcelain=v1 -uall |
        ForEach-Object {
            [PSCustomObject]@{
                Code =
                    $_.Substring(0, 2)

                Path =
                    $_.
                        Substring(3).
                        Trim().
                        Replace("\", "/")
            }
        }
)

if ($ChangedEntries.Count -ne $ExpectedChanges.Count) {
    Write-Host "Estado atual:"
    git status --short

    throw "Quantidade inesperada de alteracoes."
}

foreach ($Entry in $ChangedEntries) {
    if (-not $ExpectedChanges.ContainsKey($Entry.Path)) {
        throw "Arquivo fora do escopo: $($Entry.Path)"
    }

    $ExpectedCode =
        $ExpectedChanges[$Entry.Path]

    if ($Entry.Code -ne $ExpectedCode) {
        throw (
            "Status divergente para {0}: esperado '{1}', encontrado '{2}'." -f
            $Entry.Path,
            $ExpectedCode,
            $Entry.Code
        )
    }
}

foreach ($RelativePath in $ExpectedChanges.Keys) {
    if (-not (Test-Path -LiteralPath $RelativePath -PathType Leaf)) {
        throw "Arquivo esperado ausente: $RelativePath"
    }
}

Write-Host ""
Write-Host "[ARQUIVOS ALTERADOS]"

$ChangedEntries |
    Sort-Object Path |
    ForEach-Object {
        Write-Host $_.Path
    }

[PSCustomObject]@{
    ProjectRoot =
        $ResolvedRoot

    ChangedFiles =
        $ChangedEntries.Count

    CommitCreated =
        $false

    ExternalUiDependencies =
        0

    Result =
        "READY_FOR_APPLICATION_SHELL_VALIDATION"
} |
    Format-List

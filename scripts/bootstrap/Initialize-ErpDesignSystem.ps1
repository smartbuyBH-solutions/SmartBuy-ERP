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

function Assert-TargetAbsent {
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

function Assert-GlobalCssReady {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $ExpectedContent = @"
@import "tailwindcss";

* {
  box-sizing: border-box;
}

html,
body {
  min-height: 100%;
}

body {
  margin: 0;
}
"@

    $ActualContent =
        [System.IO.File]::ReadAllText($Path).
            Replace("`r`n", "`n").
            Trim([char[]]"`n")

    $NormalizedExpected =
        $ExpectedContent.
            Replace("`r`n", "`n").
            Trim([char[]]"`n")

    if ($ActualContent -ne $NormalizedExpected) {
        throw "globals.css divergiu da baseline aprovada."
    }
}

function Write-DesignSystemFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Root
    )

    $StylesDirectory =
        Join-Path $Root "src\styles"

    [void](
        New-Item `
            -ItemType Directory `
            -Path $StylesDirectory `
            -Force
    )

    $TokensCss = @"
/*
 * Smart Buy BH ERP
 * B2E High-Density Design Baseline
 * Canonical design tokens
 */

:root {
  color-scheme: light;

  --bg-body: #f8fafc;
  --bg-surface: #ffffff;
  --brand-primary: #000000;
  --brand-hover: #333333;
  --accent-color: #2563eb;
  --border-color: #e2e8f0;

  --cor-principal-1: #386057;
  --cor-principal-1-light: #4a7c6e;
  --cor-principal-1-dark: #2a4a42;
  --cor-principal-2: #e5e1c4;
  --cor-principal-2-light: #f4f0e3;
  --cor-principal-2-dark: #d4cfb8;
  --cor-secundaria: #041413;
  --branco: #ffffff;

  --text-primary: #0f172a;
  --text-secondary: #64748b;
  --text-tertiary: #94a3b8;

  --success: #10b981;
  --success-light: #d1fae5;
  --warning: #f59e0b;
  --warning-light: #fef3c7;
  --danger: #ef4444;
  --danger-light: #fee2e2;
  --premium: #8b5cf6;
  --premium-light: #ede9fe;
  --info: #3b82f6;
  --info-light: #eff6ff;

  --success-color: var(--success);
  --success-dark: #059669;
  --warning-color: var(--warning);
  --warning-dark: #d97706;
  --error-color: var(--danger);
  --error-dark: #dc2626;
  --neutral-light: #f3f4f6;
  --neutral-medium: #d1d5db;
  --neutral-dark: #374151;

  --radius-sm: 6px;
  --radius-md: 10px;
  --radius-lg: 16px;
  --radius-full: 9999px;

  --shadow-sm:
    0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-md:
    0 4px 6px -1px rgba(0, 0, 0, 0.05),
    0 2px 4px -1px rgba(0, 0, 0, 0.03);
  --shadow-lg:
    0 10px 15px -3px rgba(0, 0, 0, 0.05),
    0 4px 6px -2px rgba(0, 0, 0, 0.03);

  --transition:
    all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}
"@

    $ThemeCss = @"
/*
 * Global operational theme.
 * External institutional modules require separate governance approval.
 */

*,
*::before,
*::after {
  box-sizing: border-box;
}

html,
body {
  min-height: 100%;
}

html {
  background: var(--bg-body);
}

body {
  margin: 0;
  background: var(--bg-body);
  color: var(--text-primary);
  font-family:
    -apple-system,
    BlinkMacSystemFont,
    "SF Pro Display",
    "Segoe UI",
    Roboto,
    sans-serif;
  line-height: 1.4;
  -webkit-font-smoothing: antialiased;
}

button,
input,
select,
textarea {
  font: inherit;
}

button:disabled {
  cursor: not-allowed;
}

a {
  color: inherit;
}

input:focus-visible,
select:focus-visible,
textarea:focus-visible {
  outline: none;
  border-color: var(--brand-primary);
  background: var(--bg-surface);
  box-shadow:
    0 0 0 3px rgba(0, 0, 0, 0.05);
}

button:focus-visible,
a:focus-visible {
  outline: 2px solid var(--brand-primary);
  outline-offset: 2px;
}
"@

    $UtilitiesCss = @"
/*
 * Canonical high-density layout primitives.
 */

.sb-container {
  width: 100%;
  max-width: 1500px;
  margin-inline: auto;
  padding: 16px;
}

.sb-stack {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.sb-panel {
  padding: 16px;
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-sm);
  transition: var(--transition);
}

.sb-panel:hover {
  border-color: var(--brand-primary);
  box-shadow: var(--shadow-md);
  transform: translateY(-1px);
}

.sb-panel-title {
  margin: 0;
  color: var(--text-primary);
  font-size: 1rem;
  font-weight: 700;
}

.sb-dashboard-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.sb-parallel-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.sb-form-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.sb-direct-stack {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.sb-table-scroll {
  width: 100%;
  overflow-x: auto;
  border-radius: var(--radius-md);
}

.sb-monospace-input {
  font-family:
    "SFMono-Regular",
    Consolas,
    monospace;
  font-size: 0.8125rem;
}

@media (max-width: 1100px) {
  .sb-dashboard-grid {
    grid-template-columns:
      repeat(2, minmax(0, 1fr));
  }

  .sb-form-grid {
    grid-template-columns:
      repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 900px) {
  .sb-parallel-grid,
  .sb-form-grid {
    grid-template-columns: minmax(0, 1fr);
  }
}

@media (max-width: 640px) {
  .sb-dashboard-grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
"@

    $GlobalsCss = @"
@import "tailwindcss";
@import "../styles/tokens.css";
@import "../styles/theme.css";
@import "../styles/utilities.css";
"@

    $Files = [ordered]@{
        "src\styles\tokens.css" =
            $TokensCss

        "src\styles\theme.css" =
            $ThemeCss

        "src\styles\utilities.css" =
            $UtilitiesCss

        "src\app\globals.css" =
            $GlobalsCss
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

$GlobalsPath =
    Join-Path $ResolvedRoot "src\app\globals.css"

if (-not (Test-Path -LiteralPath $GlobalsPath -PathType Leaf)) {
    throw "globals.css nao encontrado."
}

$NewStyleFiles = @(
    "src\styles\tokens.css",
    "src\styles\theme.css",
    "src\styles\utilities.css"
)

Assert-TargetAbsent `
    -RelativePaths $NewStyleFiles

Assert-GlobalCssReady `
    -Path $GlobalsPath

Write-Host "========================================"
Write-Host "CRIANDO FUNDACAO DO DESIGN SYSTEM"
Write-Host "========================================"

Write-DesignSystemFiles `
    -Root $ResolvedRoot

$ExpectedChanges = @(
    "src/app/globals.css",
    "src/styles/theme.css",
    "src/styles/tokens.css",
    "src/styles/utilities.css"
)

$ChangedFiles = @(
    git status --porcelain=v1 -uall |
        ForEach-Object {
            $_.Substring(3).Trim().Replace("\", "/")
        } |
        Sort-Object
)

$ScopeDifference = @(
    Compare-Object `
        -ReferenceObject (
            $ExpectedChanges |
                Sort-Object
        ) `
        -DifferenceObject $ChangedFiles
)

if ($ScopeDifference.Count -ne 0) {
    Write-Host "Diferencas encontradas:"
    $ScopeDifference |
        Format-Table -AutoSize

    throw "O escopo da fundacao visual foi excedido."
}

foreach ($RelativePath in $ExpectedChanges) {
    if (-not (Test-Path -LiteralPath $RelativePath -PathType Leaf)) {
        throw "Arquivo esperado ausente: $RelativePath"
    }
}

Write-Host ""
Write-Host "[ARQUIVOS ALTERADOS]"

$ChangedFiles |
    ForEach-Object {
        Write-Host $_
    }

[PSCustomObject]@{
    ProjectRoot =
        $ResolvedRoot

    ChangedFiles =
        $ChangedFiles.Count

    CommitCreated =
        $false

    Result =
        "READY_FOR_DESIGN_SYSTEM_VALIDATION"
} |
    Format-List

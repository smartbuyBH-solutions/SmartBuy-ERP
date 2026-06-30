[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectRoot,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[0-9a-fA-F]{7,40}$")]
    [string]$ExpectedHead,

    [ValidateRange(1, 65535)]
    [int]$Port = 3000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Actual,

        [Parameter(Mandatory = $true)]
        [object]$Expected,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if ($Actual -ne $Expected) {
        throw "$Description divergente. Esperado: $Expected. Encontrado: $Actual."
    }
}

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    throw "Diretorio do projeto nao encontrado: $ProjectRoot"
}

$ResolvedProjectRoot = (
    Resolve-Path -LiteralPath $ProjectRoot
).Path

Assert-Equal `
    -Actual (Split-Path -Leaf $ResolvedProjectRoot) `
    -Expected "SmartBuy-ERP" `
    -Description "Nome do diretorio do projeto"

Set-Location -LiteralPath $ResolvedProjectRoot

if (-not (Test-Path -LiteralPath ".git" -PathType Container)) {
    throw "Repositorio Git nao encontrado."
}

$CurrentHead = (git rev-parse --short HEAD).Trim()

Assert-Equal `
    -Actual $CurrentHead `
    -Expected $ExpectedHead `
    -Description "Commit atual"

$PendingChanges = @(git status --porcelain)

if ($PendingChanges.Count -ne 0) {
    Write-Host "Alteracoes pendentes:"
    git status --short

    throw "O repositorio precisa estar limpo antes da instalacao."
}

$PreflightPath = Join-Path `
    $ResolvedProjectRoot `
    "scripts\validation\Test-BootstrapPreflight.ps1"

if (-not (Test-Path -LiteralPath $PreflightPath -PathType Leaf)) {
    throw "Script de preflight nao encontrado."
}

Write-Host "========================================"
Write-Host "EXECUTANDO PREFLIGHT"
Write-Host "========================================"

& $PreflightPath `
    -ProjectRoot $ResolvedProjectRoot `
    -ExpectedHead $CurrentHead `
    -Port $Port

$PackagePath = Join-Path `
    $ResolvedProjectRoot `
    "package.json"

$PackageBefore = Get-Content -LiteralPath $PackagePath -Raw |
    ConvertFrom-Json

Assert-Equal `
    -Actual $PackageBefore.name `
    -Expected "smartbuy-erp" `
    -Description "Nome do pacote"

if ($null -ne $PackageBefore.dependencies) {
    throw "Operacao bloqueada: dependencies ja existe no package.json."
}

if ($null -ne $PackageBefore.devDependencies) {
    throw "Operacao bloqueada: devDependencies ja existe no package.json."
}

Write-Host "========================================"
Write-Host "INSTALANDO DEPENDENCIAS DE PRODUCAO"
Write-Host "========================================"

pnpm add `
    next@16.2.9 `
    react@19.2.7 `
    react-dom@19.2.7 `
    --save-exact

if ($LASTEXITCODE -ne 0) {
    Write-Host "Estado atual apos a falha:"
    git status --short

    throw "Falha na instalacao das dependencias de producao."
}

Write-Host "========================================"
Write-Host "VALIDANDO PACKAGE.JSON"
Write-Host "========================================"

$PackageAfter = Get-Content -LiteralPath $PackagePath -Raw |
    ConvertFrom-Json

$ExpectedDependencies = [ordered]@{
    next        = "16.2.9"
    react       = "19.2.7"
    "react-dom" = "19.2.7"
}

foreach ($DependencyName in $ExpectedDependencies.Keys) {
    $ExpectedVersion =
        $ExpectedDependencies[$DependencyName]

    $InstalledVersion =
        $PackageAfter.dependencies.$DependencyName

    Write-Host "$DependencyName = $InstalledVersion"

    Assert-Equal `
        -Actual $InstalledVersion `
        -Expected $ExpectedVersion `
        -Description "Versao de $DependencyName"
}

if ($null -ne $PackageAfter.devDependencies) {
    throw "Operacao bloqueada: devDependencies foi alterado nesta etapa."
}

Write-Host "========================================"
Write-Host "VALIDANDO LOCKFILE CONGELADO"
Write-Host "========================================"

pnpm install `
    --frozen-lockfile `
    --ignore-scripts

if ($LASTEXITCODE -ne 0) {
    throw "Falha na validacao do lockfile congelado."
}

Write-Host "========================================"
Write-Host "VALIDANDO DEPENDENCIAS RECONHECIDAS"
Write-Host "========================================"

pnpm list --depth 0

if ($LASTEXITCODE -ne 0) {
    throw "Falha ao consultar as dependencias instaladas."
}

Write-Host "========================================"
Write-Host "CONSULTANDO BUILDS IGNORADOS"
Write-Host "========================================"

pnpm ignored-builds

if ($LASTEXITCODE -ne 0) {
    throw "Falha ao consultar scripts de build ignorados."
}

Write-Host "========================================"
Write-Host "VALIDANDO ESCOPO DAS ALTERACOES"
Write-Host "========================================"

$AllowedChanges = @(
    "package.json",
    "pnpm-lock.yaml"
)

$CurrentChanges = @(
    git status --porcelain=v1 -uall |
        ForEach-Object {
            $_.Substring(3).Trim().Replace("\", "/")
        }
)

$UnexpectedChanges = @(
    $CurrentChanges |
        Where-Object {
            $_ -notin $AllowedChanges
        }
)

if ($UnexpectedChanges.Count -ne 0) {
    Write-Host "Alteracoes inesperadas:"
    $UnexpectedChanges

    throw "O escopo autorizado da instalacao foi excedido."
}

foreach ($RequiredChange in $AllowedChanges) {
    if ($RequiredChange -notin $CurrentChanges) {
        throw "Alteracao obrigatoria ausente: $RequiredChange"
    }
}

Write-Host "========================================"
Write-Host "INSTALACAO CONCLUIDA PARA INSPECAO"
Write-Host "========================================"

[PSCustomObject]@{
    ProjectRoot         = $ResolvedProjectRoot
    GitHead             = $CurrentHead
    NextVersion         = $PackageAfter.dependencies.next
    ReactVersion        = $PackageAfter.dependencies.react
    ReactDomVersion     = $PackageAfter.dependencies.'react-dom'
    ChangedFiles        = $CurrentChanges -join ", "
    CommitCreated       = $false
    Result              = "READY_FOR_VALIDATION"
} |
    Format-List
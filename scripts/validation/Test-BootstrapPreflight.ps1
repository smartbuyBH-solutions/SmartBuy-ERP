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
    throw "O repositorio precisa estar limpo."
}

$RequiredFiles = @(
    ".node-version",
    ".npmrc",
    "package.json",
    "pnpm-lock.yaml"
)

foreach ($RequiredFile in $RequiredFiles) {
    if (-not (Test-Path -LiteralPath $RequiredFile -PathType Leaf)) {
        throw "Arquivo obrigatorio ausente: $RequiredFile"
    }
}

$Package = Get-Content -LiteralPath "package.json" -Raw |
    ConvertFrom-Json

Assert-Equal `
    -Actual $Package.name `
    -Expected "smartbuy-erp" `
    -Description "Nome do pacote"

Assert-Equal `
    -Actual $Package.packageManager `
    -Expected "pnpm@10.14.0" `
    -Description "Gerenciador de pacotes"

Assert-Equal `
    -Actual $Package.engines.node `
    -Expected "22.18.0" `
    -Description "Versao do Node.js no package.json"

Assert-Equal `
    -Actual $Package.engines.pnpm `
    -Expected "10.14.0" `
    -Description "Versao do pnpm no package.json"

$InstalledNodeVersion = (& node --version).Trim().TrimStart("v")
$InstalledPnpmVersion = (& pnpm --version).Trim()

Assert-Equal `
    -Actual $InstalledNodeVersion `
    -Expected "22.18.0" `
    -Description "Node.js instalado"

Assert-Equal `
    -Actual $InstalledPnpmVersion `
    -Expected "10.14.0" `
    -Description "pnpm instalado"

$PortState = Get-NetTCPConnection `
    -LocalPort $Port `
    -State Listen `
    -ErrorAction SilentlyContinue

if ($null -ne $PortState) {
    $PortState |
        Select-Object LocalAddress, LocalPort, OwningProcess |
        Format-Table -AutoSize

    throw "A porta $Port esta em uso."
}

$UnexpectedBootstrapArtifacts = @(
    "next.config.ts",
    "tsconfig.json",
    "eslint.config.mjs",
    "next-env.d.ts",
    "src",
    ".next",
    "node_modules"
) |
    Where-Object {
        Test-Path -LiteralPath $_
    }

if (@($UnexpectedBootstrapArtifacts).Count -ne 0) {
    Write-Host "Artefatos inesperados encontrados:"
    $UnexpectedBootstrapArtifacts
    throw "O ERP nao esta no estado inicial esperado."
}

Write-Host "Consultando o registro npm..."

$RegistryResponse = pnpm view next@16.2.9 version --json

if ($LASTEXITCODE -ne 0) {
    throw "O registro npm nao respondeu corretamente."
}

$RegistryVersion = (
    $RegistryResponse |
        ConvertFrom-Json
)

Assert-Equal `
    -Actual $RegistryVersion `
    -Expected "16.2.9" `
    -Description "Versao do Next.js no registro"

[PSCustomObject]@{
    ProjectRoot       = $ResolvedProjectRoot
    GitHead           = $CurrentHead
    GitClean          = $true
    NodeVersion       = $InstalledNodeVersion
    PnpmVersion       = $InstalledPnpmVersion
    Port              = $Port
    PortAvailable     = $true
    NpmRegistry       = "available"
    NextVersion       = $RegistryVersion
    BootstrapArtifacts = "absent"
    Result            = "APPROVED"
} |
    Format-List
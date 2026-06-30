[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectRoot,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[0-9a-fA-F]{7,40}$")]
    [string]$ExpectedHead
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ModulePath = Join-Path `
    $PSScriptRoot `
    "..\lib\DependencyGuards.psm1"

Import-Module `
    (Resolve-Path -LiteralPath $ModulePath).Path `
    -Force

$ProductionDependencies = [ordered]@{
    next        = "16.2.9"
    react       = "19.2.7"
    "react-dom" = "19.2.7"
}

$DevelopmentDependencies = [ordered]@{
    typescript           = "5.9.3"
    eslint               = "9.39.4"
    "eslint-config-next" = "16.2.9"
    "@types/node"        = "22.20.0"
    "@types/react"       = "19.2.17"
    "@types/react-dom"   = "19.2.3"
}

function Assert-InitialState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedRoot,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$ExpectedProduction
    )

    $Package = Get-ProjectPackage `
        -ProjectRoot $ResolvedRoot

    Assert-Equal `
        -Actual $Package.name `
        -Expected "smartbuy-erp" `
        -Description "Nome do pacote"

    Assert-Equal `
        -Actual $Package.packageManager `
        -Expected "pnpm@10.14.0" `
        -Description "Gerenciador de pacotes"

    Assert-ExactDependencySet `
        -Package $Package `
        -PropertyName "dependencies" `
        -Expected $ExpectedProduction

    Assert-PropertyAbsent `
        -InputObject $Package `
        -PropertyName "devDependencies"

    if (
        -not (
            Test-Path `
                -LiteralPath (Join-Path $ResolvedRoot "node_modules") `
                -PathType Container
        )
    ) {
        throw "node_modules nao encontrado."
    }

    if (
        -not (
            Test-Path `
                -LiteralPath (Join-Path $ResolvedRoot "pnpm-lock.yaml") `
                -PathType Leaf
        )
    ) {
        throw "pnpm-lock.yaml nao encontrado."
    }

    git -C $ResolvedRoot check-ignore --quiet "node_modules"

    if ($LASTEXITCODE -ne 0) {
        throw "node_modules nao esta protegido pelo .gitignore."
    }
}

function Assert-NpmRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedRoot
    )

    Push-Location -LiteralPath $ResolvedRoot

    try {
        $RegistryResponse =
            & pnpm view typescript@5.9.3 version --json

        $RegistryExitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    if ($RegistryExitCode -ne 0) {
        throw "O registro npm nao respondeu corretamente."
    }

    $RegistryVersion = (
        $RegistryResponse |
            ConvertFrom-Json
    )

    Assert-Equal `
        -Actual $RegistryVersion `
        -Expected "5.9.3" `
        -Description "Versao do TypeScript no registro"
}

function Install-DevelopmentPackages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedRoot
    )

    Invoke-PnpmChecked `
        -ProjectRoot $ResolvedRoot `
        -Arguments @(
            "add",
            "--save-dev",
            "typescript@5.9.3",
            "eslint@9.39.4",
            "eslint-config-next@16.2.9",
            "@types/node@22.20.0",
            "@types/react@19.2.17",
            "@types/react-dom@19.2.3",
            "--save-exact"
        ) `
        -FailureMessage "Falha na instalacao das dependencias de desenvolvimento."
}

function Assert-InstalledState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedRoot,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$ExpectedProduction,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$ExpectedDevelopment
    )

    $Package = Get-ProjectPackage `
        -ProjectRoot $ResolvedRoot

    Assert-ExactDependencySet `
        -Package $Package `
        -PropertyName "dependencies" `
        -Expected $ExpectedProduction

    Assert-ExactDependencySet `
        -Package $Package `
        -PropertyName "devDependencies" `
        -Expected $ExpectedDevelopment

    Invoke-PnpmChecked `
        -ProjectRoot $ResolvedRoot `
        -Arguments @(
            "install",
            "--frozen-lockfile",
            "--ignore-scripts"
        ) `
        -FailureMessage "Falha na validacao do lockfile congelado."

    Invoke-PnpmChecked `
        -ProjectRoot $ResolvedRoot `
        -Arguments @("list", "--depth", "0") `
        -FailureMessage "Falha ao consultar as dependencias."

    Invoke-PnpmChecked `
        -ProjectRoot $ResolvedRoot `
        -Arguments @("ignored-builds") `
        -FailureMessage "Falha ao consultar scripts de build ignorados."

    $ChangedFiles = @(
        Assert-OnlyExpectedChanges `
            -ProjectRoot $ResolvedRoot `
            -ExpectedFiles @(
                "package.json",
                "pnpm-lock.yaml"
            )
    )

    [PSCustomObject]@{
        ProjectRoot       = $ResolvedRoot
        TypeScriptVersion =
            $Package.devDependencies.typescript
        EslintVersion     =
            $Package.devDependencies.eslint
        ChangedFiles      = $ChangedFiles -join ", "
        CommitCreated     = $false
        Result            = "READY_FOR_VALIDATION"
    } |
        Format-List
}

function Invoke-DevelopmentDependencyInstallation {
    [CmdletBinding()]
    param()

    $ResolvedRoot = Assert-GitRepositoryReady `
        -ProjectRoot $ProjectRoot `
        -ExpectedHead $ExpectedHead `
        -RequireClean

    Write-Host "========================================"
    Write-Host "VALIDANDO ESTADO INICIAL"
    Write-Host "========================================"

    Assert-InitialState `
        -ResolvedRoot $ResolvedRoot `
        -ExpectedProduction $ProductionDependencies

    Write-Host "========================================"
    Write-Host "VALIDANDO REGISTRO NPM"
    Write-Host "========================================"

    Assert-NpmRegistry `
        -ResolvedRoot $ResolvedRoot

    Write-Host "========================================"
    Write-Host "INSTALANDO DEVDEPENDENCIES"
    Write-Host "========================================"

    Install-DevelopmentPackages `
        -ResolvedRoot $ResolvedRoot

    Write-Host "========================================"
    Write-Host "VALIDANDO INSTALACAO"
    Write-Host "========================================"

    Assert-InstalledState `
        -ResolvedRoot $ResolvedRoot `
        -ExpectedProduction $ProductionDependencies `
        -ExpectedDevelopment $DevelopmentDependencies
}

Invoke-DevelopmentDependencyInstallation
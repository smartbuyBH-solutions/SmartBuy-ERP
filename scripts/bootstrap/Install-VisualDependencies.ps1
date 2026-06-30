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

$InitialDevelopmentDependencies = [ordered]@{
    typescript           = "5.9.3"
    eslint               = "9.39.4"
    "eslint-config-next" = "16.2.9"
    "@types/node"        = "22.20.0"
    "@types/react"       = "19.2.17"
    "@types/react-dom"   = "19.2.3"
}

$FinalDevelopmentDependencies = [ordered]@{
    typescript                = "5.9.3"
    eslint                    = "9.39.4"
    "eslint-config-next"      = "16.2.9"
    "@types/node"             = "22.20.0"
    "@types/react"            = "19.2.17"
    "@types/react-dom"        = "19.2.3"
    tailwindcss               = "4.3.2"
    "@tailwindcss/postcss"    = "4.3.2"
    postcss                   = "8.5.16"
}

function Assert-VisualInitialState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedRoot
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
        -Expected $ProductionDependencies

    Assert-ExactDependencySet `
        -Package $Package `
        -PropertyName "devDependencies" `
        -Expected $InitialDevelopmentDependencies

    $NodeModulesPath = Join-Path `
        $ResolvedRoot `
        "node_modules"

    $LockfilePath = Join-Path `
        $ResolvedRoot `
        "pnpm-lock.yaml"

    if (
        -not (
            Test-Path `
                -LiteralPath $NodeModulesPath `
                -PathType Container
        )
    ) {
        throw "node_modules nao encontrado."
    }

    if (
        -not (
            Test-Path `
                -LiteralPath $LockfilePath `
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

function Install-VisualPackages {
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
            "tailwindcss@4.3.2",
            "@tailwindcss/postcss@4.3.2",
            "postcss@8.5.16",
            "--save-exact"
        ) `
        -FailureMessage "Falha na instalacao das dependencias visuais."
}

function Assert-VisualInstalledState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedRoot
    )

    $Package = Get-ProjectPackage `
        -ProjectRoot $ResolvedRoot

    Assert-ExactDependencySet `
        -Package $Package `
        -PropertyName "dependencies" `
        -Expected $ProductionDependencies

    Assert-ExactDependencySet `
        -Package $Package `
        -PropertyName "devDependencies" `
        -Expected $FinalDevelopmentDependencies

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
        -Arguments @(
            "list",
            "--depth",
            "0"
        ) `
        -FailureMessage "Falha ao consultar as dependencias."

    Invoke-PnpmChecked `
        -ProjectRoot $ResolvedRoot `
        -Arguments @(
            "ignored-builds"
        ) `
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
        ProjectRoot      = $ResolvedRoot
        TailwindVersion  =
            $Package.devDependencies.tailwindcss
        PluginVersion    =
            $Package.devDependencies.'@tailwindcss/postcss'
        PostcssVersion   =
            $Package.devDependencies.postcss
        ChangedFiles     = $ChangedFiles -join ", "
        CommitCreated    = $false
        Result           = "READY_FOR_VALIDATION"
    } |
        Format-List
}

function Invoke-VisualDependencyInstallation {
    [CmdletBinding()]
    param()

    $ResolvedRoot = Assert-GitRepositoryReady `
        -ProjectRoot $ProjectRoot `
        -ExpectedHead $ExpectedHead `
        -RequireClean

    Write-Host "========================================"
    Write-Host "VALIDANDO ESTADO INICIAL"
    Write-Host "========================================"

    Assert-VisualInitialState `
        -ResolvedRoot $ResolvedRoot

    Write-Host "========================================"
    Write-Host "INSTALANDO DEPENDENCIAS VISUAIS"
    Write-Host "========================================"

    Install-VisualPackages `
        -ResolvedRoot $ResolvedRoot

    Write-Host "========================================"
    Write-Host "VALIDANDO INSTALACAO VISUAL"
    Write-Host "========================================"

    Assert-VisualInstalledState `
        -ResolvedRoot $ResolvedRoot
}

Invoke-VisualDependencyInstallation
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Equal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Actual,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Expected,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description
    )

    if ($Actual -ne $Expected) {
        throw "$Description divergente. Esperado: $Expected. Encontrado: $Actual."
    }
}

function Assert-GitRepositoryReady {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [ValidatePattern("^[0-9a-fA-F]{7,40}$")]
        [string]$ExpectedHead,

        [switch]$RequireClean
    )

    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
        throw "Diretorio do projeto nao encontrado: $ProjectRoot"
    }

    $ResolvedRoot = (
        Resolve-Path -LiteralPath $ProjectRoot
    ).Path

    if ((Split-Path -Leaf $ResolvedRoot) -ne "SmartBuy-ERP") {
        throw "Diretorio de projeto inesperado: $ResolvedRoot"
    }

    if (
        -not (
            Test-Path `
                -LiteralPath (Join-Path $ResolvedRoot ".git") `
                -PathType Container
        )
    ) {
        throw "Repositorio Git nao encontrado."
    }

    $CurrentHead = (
        git -C $ResolvedRoot rev-parse --short HEAD
    ).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao consultar o commit atual."
    }

    Assert-Equal `
        -Actual $CurrentHead `
        -Expected $ExpectedHead `
        -Description "Commit atual"

    if ($RequireClean) {
        $PendingChanges = @(
            git -C $ResolvedRoot status --porcelain
        )

        if ($PendingChanges.Count -ne 0) {
            Write-Host "Alteracoes pendentes:"
            git -C $ResolvedRoot status --short

            throw "O repositorio precisa estar limpo."
        }
    }

    return $ResolvedRoot
}

function Get-ProjectPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProjectRoot
    )

    $PackagePath = Join-Path $ProjectRoot "package.json"

    if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf)) {
        throw "package.json nao encontrado."
    }

    return (
        Get-Content -LiteralPath $PackagePath -Raw |
            ConvertFrom-Json
    )
}

function Assert-PropertyAbsent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PropertyName
    )

    if (
        $InputObject.PSObject.Properties.Name -contains
        $PropertyName
    ) {
        throw "Propriedade inesperada encontrada: $PropertyName"
    }
}

function Assert-ExactDependencySet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Package,

        [Parameter(Mandatory = $true)]
        [ValidateSet("dependencies", "devDependencies")]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Expected
    )

    $ContainerProperty =
        $Package.PSObject.Properties[$PropertyName]

    if ($null -eq $ContainerProperty) {
        throw "Propriedade obrigatoria ausente: $PropertyName"
    }

    $DependencyContainer = $ContainerProperty.Value
    $ActualNames = @(
        $DependencyContainer.PSObject.Properties.Name
    )

    foreach ($DependencyName in $Expected.Keys) {
        $DependencyProperty =
            $DependencyContainer.PSObject.Properties[$DependencyName]

        if ($null -eq $DependencyProperty) {
            throw "Dependencia obrigatoria ausente: $DependencyName"
        }

        Assert-Equal `
            -Actual ([string]$DependencyProperty.Value) `
            -Expected ([string]$Expected[$DependencyName]) `
            -Description "Versao de $DependencyName"
    }

    $UnexpectedNames = @(
        $ActualNames |
            Where-Object {
                $_ -notin $Expected.Keys
            }
    )

    if ($UnexpectedNames.Count -ne 0) {
        Write-Host "Dependencias inesperadas:"
        $UnexpectedNames

        throw "O conjunto $PropertyName possui itens fora do escopo."
    }
}

function Invoke-PnpmChecked {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FailureMessage
    )

    Push-Location -LiteralPath $ProjectRoot

    try {
        & pnpm @Arguments
        $CommandExitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    if ($CommandExitCode -ne 0) {
        throw $FailureMessage
    }
}

function Get-GitChangedFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProjectRoot
    )

    return @(
        git -C $ProjectRoot status --porcelain=v1 -uall |
            ForEach-Object {
                $_.Substring(3).Trim().Replace("\", "/")
            }
    )
}

function Assert-OnlyExpectedChanges {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string[]]$ExpectedFiles
    )

    $ActualFiles = @(
        Get-GitChangedFiles -ProjectRoot $ProjectRoot
    )

    $UnexpectedFiles = @(
        $ActualFiles |
            Where-Object {
                $_ -notin $ExpectedFiles
            }
    )

    if ($UnexpectedFiles.Count -ne 0) {
        Write-Host "Alteracoes inesperadas:"
        $UnexpectedFiles

        throw "O escopo autorizado foi excedido."
    }

    foreach ($ExpectedFile in $ExpectedFiles) {
        if ($ExpectedFile -notin $ActualFiles) {
            throw "Alteracao obrigatoria ausente: $ExpectedFile"
        }
    }

    return $ActualFiles
}

Export-ModuleMember -Function @(
    "Assert-Equal",
    "Assert-GitRepositoryReady",
    "Get-ProjectPackage",
    "Assert-PropertyAbsent",
    "Assert-ExactDependencySet",
    "Invoke-PnpmChecked",
    "Get-GitChangedFiles",
    "Assert-OnlyExpectedChanges"
)
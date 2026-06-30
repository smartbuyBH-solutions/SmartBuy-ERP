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

function Assert-ScriptsEmpty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Package
    )

    $ScriptsProperty =
        $Package.PSObject.Properties["scripts"]

    if ($null -eq $ScriptsProperty) {
        return
    }

    if ($null -eq $ScriptsProperty.Value) {
        return
    }

    $ScriptProperties = @(
        $ScriptsProperty.Value.PSObject.Properties |
            Where-Object {
                $null -ne $_ -and
                -not [string]::IsNullOrWhiteSpace(
                    [string]$_.Name
                )
            }
    )

    if ($ScriptProperties.Count -ne 0) {
        throw "Operacao bloqueada: package.json ja possui scripts."
    }
}

function Set-ProjectScripts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Package,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackagePath
    )

    $Scripts = [ordered]@{
        dev =
            "next dev --hostname 127.0.0.1 --port 3000"

        build =
            "next build"

        start =
            "next start --hostname 127.0.0.1 --port 3000"

        lint =
            "eslint ."

        typecheck =
            "next typegen && tsc --noEmit"

        check =
            "pnpm run typecheck && pnpm run lint && pnpm run build"
    }

    $Package |
        Add-Member `
            -NotePropertyName "scripts" `
            -NotePropertyValue $Scripts `
            -Force

    $PackageJson = $Package |
        ConvertTo-Json -Depth 20

    Write-Utf8File `
        -Path $PackagePath `
        -Content $PackageJson
}

function Ensure-GeneratedFilesAreIgnored {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GitIgnorePath
    )

    $RequiredRules = @(
        ".next/",
        "out/",
        "next-env.d.ts",
        "*.tsbuildinfo"
    )

    $CurrentContent =
        [System.IO.File]::ReadAllText(
            $GitIgnorePath
        )

    $CurrentRules = @(
        $CurrentContent -split "\r?\n" |
            ForEach-Object {
                $_.Trim()
            }
    )

    $MissingRules = @(
        $RequiredRules |
            Where-Object {
                $_ -notin $CurrentRules
            }
    )

    if ($MissingRules.Count -eq 0) {
        Write-Host "Arquivos gerados ja estao protegidos."
        return
    }

    $UpdatedContent =
        $CurrentContent.TrimEnd([char[]]"`r`n") +
        "`n`n# Next.js e TypeScript gerados`n" +
        ($MissingRules -join "`n") +
        "`n"

    Write-Utf8File `
        -Path $GitIgnorePath `
        -Content $UpdatedContent

    Write-Host "Politica de arquivos gerados atualizada."
}

function Write-TechnicalScaffold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Root
    )

    $NextConfig = @"
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  poweredByHeader: false,
  reactStrictMode: true,
};

export default nextConfig;
"@

    $TsConfig = @"
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": false,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "forceConsistentCasingInFileNames": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": [
    "next-env.d.ts",
    ".next/types/**/*.ts",
    "**/*.ts",
    "**/*.tsx"
  ],
  "exclude": ["node_modules"]
}
"@

    $EslintConfig = @"
import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTypeScript from "eslint-config-next/typescript";

export default defineConfig([
  ...nextVitals,
  ...nextTypeScript,
  globalIgnores([
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
  ]),
]);
"@

    $PostcssConfig = @"
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
"@

    $Layout = @"
import type { Metadata } from "next";
import type { ReactNode } from "react";

import "./globals.css";

export const metadata: Metadata = {
  title: "SmartBuyBH ERP",
  description:
    "Plataforma de pré-atendimento e apoio operacional da Smart Buy BH.",
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

    $Page = @"
export default function ErpHome() {
  return (
    <main>
      <h1>SmartBuyBH ERP</h1>
      <p>Fundação técnica inicializada.</p>
    </main>
  );
}
"@

    $GlobalCss = @"
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

    New-Item `
        -ItemType Directory `
        -Path (Join-Path $Root "src\app") `
        -Force |
        Out-Null

    $Files = [ordered]@{
        "next.config.ts" =
            $NextConfig

        "tsconfig.json" =
            $TsConfig

        "eslint.config.mjs" =
            $EslintConfig

        "postcss.config.mjs" =
            $PostcssConfig

        "src\app\layout.tsx" =
            $Layout

        "src\app\page.tsx" =
            $Page

        "src\app\globals.css" =
            $GlobalCss
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

$PackagePath =
    Join-Path $ResolvedRoot "package.json"

$GitIgnorePath =
    Join-Path $ResolvedRoot ".gitignore"

$TargetFiles = @(
    "next.config.ts",
    "tsconfig.json",
    "eslint.config.mjs",
    "postcss.config.mjs",
    "src\app\layout.tsx",
    "src\app\page.tsx",
    "src\app\globals.css"
)

Assert-TargetsAbsent `
    -RelativePaths $TargetFiles

if (
    (Test-Path -LiteralPath "app") -or
    (Test-Path -LiteralPath "src\app")
) {
    throw "Operacao bloqueada: diretorio de aplicacao ja existe."
}

$Package = Get-ProjectPackage `
    -ProjectRoot $ResolvedRoot

Assert-Equal `
    -Actual $Package.name `
    -Expected "smartbuy-erp" `
    -Description "Nome do pacote"

Assert-ScriptsEmpty `
    -Package $Package

$ExpectedProductionDependencies = [ordered]@{
    next =
        "16.2.9"

    react =
        "19.2.7"

    "react-dom" =
        "19.2.7"
}

$ExpectedDevelopmentDependencies = [ordered]@{
    typescript =
        "5.9.3"

    eslint =
        "9.39.4"

    "eslint-config-next" =
        "16.2.9"

    "@types/node" =
        "22.20.0"

    "@types/react" =
        "19.2.17"

    "@types/react-dom" =
        "19.2.3"

    tailwindcss =
        "4.3.2"

    "@tailwindcss/postcss" =
        "4.3.2"

    postcss =
        "8.5.16"
}

Assert-ExactDependencySet `
    -Package $Package `
    -PropertyName "dependencies" `
    -Expected $ExpectedProductionDependencies

Assert-ExactDependencySet `
    -Package $Package `
    -PropertyName "devDependencies" `
    -Expected $ExpectedDevelopmentDependencies

Write-Host "========================================"
Write-Host "CONFIGURANDO SCRIPTS"
Write-Host "========================================"

Set-ProjectScripts `
    -Package $Package `
    -PackagePath $PackagePath

Write-Host "`n========================================"
Write-Host "PROTEGENDO ARQUIVOS GERADOS"
Write-Host "========================================"

Ensure-GeneratedFilesAreIgnored `
    -GitIgnorePath $GitIgnorePath

Write-Host "`n========================================"
Write-Host "CRIANDO SCAFFOLD TECNICO"
Write-Host "========================================"

Write-TechnicalScaffold `
    -Root $ResolvedRoot

foreach ($TargetFile in $TargetFiles) {
    if (-not (Test-Path -LiteralPath $TargetFile -PathType Leaf)) {
        throw "Falha ao criar $TargetFile."
    }
}

Write-Host "`n========================================"
Write-Host "RESULTADO"
Write-Host "========================================"

$ChangedFiles = @(
    git status --porcelain=v1 -uall |
        ForEach-Object {
            $_.Substring(3).Trim().Replace("\", "/")
        }
)

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
        "READY_FOR_ERP_SCAFFOLD_VALIDATION"
} |
    Format-List

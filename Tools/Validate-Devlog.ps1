[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$Date = (Get-Date).ToString('yyyy-MM-dd')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$articlePath = Join-Path $repoRoot "docs\devlog\$Date.html"
$devlogIndexPath = Join-Path $repoRoot 'docs\devlog\index.html'
$topPath = Join-Path $repoRoot 'docs\index.html'

$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$Message) {
    $script:failures.Add($Message)
    Write-Host "[FAIL] $Message"
}

function Add-Pass([string]$Message) {
    Write-Host "[PASS] $Message"
}

Write-Host "[DevlogValidate] Date: $Date"
Write-Host "[DevlogValidate] Repo: $repoRoot"

if (-not (Test-Path -LiteralPath $articlePath -PathType Leaf)) {
    Add-Failure "Article not found: docs/devlog/$Date.html"
} else {
    Add-Pass "Article exists"

    $article = Get-Content -LiteralPath $articlePath -Raw -Encoding UTF8

    if ($article -match '__[A-Z0-9_]+__') {
        Add-Failure 'Article still contains a placeholder token.'
    } else {
        Add-Pass 'No placeholder token remains in article'
    }

    $titleMatch = [regex]::Match($article, '<h1>(?<title>.*?)</h1>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $articleTitle = $null
    if ($titleMatch.Success) {
        $articleTitle = [System.Net.WebUtility]::HtmlDecode(($titleMatch.Groups['title'].Value -replace '<[^>]+>', '').Trim())
        Add-Pass "Article title found: $articleTitle"
    } else {
        Add-Failure 'Article <h1> title not found.'
    }

    $imageMatch = [regex]::Match($article, '<img\s+[^>]*src="(?<src>[^"]+)"[^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $imageMatch.Success) {
        Add-Failure 'Article image tag not found.'
    } else {
        $imageSrc = $imageMatch.Groups['src'].Value
        if ($imageSrc -match '^(https?:|data:)') {
            Add-Failure "Article image must be a local site asset: $imageSrc"
        } else {
            $articleDir = Split-Path -Parent $articlePath
            $imagePath = [System.IO.Path]::GetFullPath((Join-Path $articleDir $imageSrc))
            if (-not $imagePath.StartsWith($repoRoot.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
                Add-Failure "Image path escapes repository: $imageSrc"
            } elseif (-not (Test-Path -LiteralPath $imagePath -PathType Leaf)) {
                Add-Failure "Image file not found: $imageSrc"
            } else {
                $imageInfo = Get-Item -LiteralPath $imagePath
                if ($imageInfo.Length -le 0) {
                    Add-Failure "Image file is empty: $imageSrc"
                } else {
                    Add-Pass "Image exists: $imageSrc ($($imageInfo.Length) bytes)"
                }
            }
        }
    }

    if (Test-Path -LiteralPath $devlogIndexPath -PathType Leaf) {
        $devlogIndex = Get-Content -LiteralPath $devlogIndexPath -Raw -Encoding UTF8
        $devlogHref = 'href="' + $Date + '.html"'
        if ($devlogIndex -notmatch [regex]::Escape($devlogHref)) {
            Add-Failure 'Development log index does not link to the article.'
        } else {
            Add-Pass 'Development log index links to article'
        }

        if ($articleTitle -and $devlogIndex -notmatch [regex]::Escape($articleTitle)) {
            Add-Failure 'Article title is not present in development log index.'
        } elseif ($articleTitle) {
            Add-Pass 'Development log index title matches article'
        }
    } else {
        Add-Failure 'Development log index not found.'
    }

    if (Test-Path -LiteralPath $topPath -PathType Leaf) {
        $top = Get-Content -LiteralPath $topPath -Raw -Encoding UTF8
        $topHref = 'href="devlog/' + $Date + '.html"'
        if ($top -notmatch [regex]::Escape($topHref)) {
            Add-Failure 'Top page latest-devlog link does not point to the article.'
        } else {
            Add-Pass 'Top page latest-devlog link points to article'
        }
    } else {
        Add-Failure 'Top page not found.'
    }
}

$stylePath = Join-Path $repoRoot 'docs\assets\css\style.css'
if (Test-Path -LiteralPath $stylePath -PathType Leaf) {
    $style = Get-Content -LiteralPath $stylePath -Raw -Encoding UTF8
    if ($style -match '(?s)\.article\s+img\s*\{[^}]*max-width\s*:\s*100%[^}]*height\s*:\s*auto') {
        Add-Pass 'Article image CSS keeps responsive aspect ratio'
    } else {
        Add-Failure 'Responsive article image CSS (max-width:100%; height:auto) not confirmed.'
    }
} else {
    Add-Failure 'Site stylesheet not found.'
}

Push-Location $repoRoot
try {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $diffCheck = & git diff --check 2>&1
    $diffExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference

    if ($diffExitCode -ne 0) {
        Add-Failure 'git diff --check reported an error.'
        $diffCheck | ForEach-Object { Write-Host "       $_" }
    } else {
        Add-Pass 'git diff --check passed'
    }
} finally {
    $ErrorActionPreference = 'Stop'
    Pop-Location
}

if ($failures.Count -gt 0) {
    Write-Host "[DevlogValidate] FAILED: $($failures.Count) issue(s)"
    exit 1
}

Write-Host '[DevlogValidate] OK'
exit 0

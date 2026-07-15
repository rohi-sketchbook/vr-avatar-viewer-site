[CmdletBinding()]
param(
    [ValidateSet('Status', 'Finalize')]
    [string]$Action = 'Status',
    [Parameter(Mandatory = $true)]
    [string]$TransferId,
    [switch]$Force,
    [switch]$Cleanup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$inboxRoot = Join-Path $repoRoot 'UserData\Temp\ChatGPTImageBridge\inbox'

if ($TransferId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$') {
    throw 'TransferId must be 1-64 characters and use only letters, numbers, dot, underscore, or hyphen.'
}

$transferRoot = Join-Path $inboxRoot $TransferId
$manifestPath = Join-Path $transferRoot 'manifest.json'
$chunksRoot = Join-Path $transferRoot 'chunks'

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Manifest not found: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$chunkFiles = @(Get-ChildItem -LiteralPath $chunksRoot -Filter '*.b64' -File | Sort-Object Name)

if ($Action -eq 'Status') {
    Write-Host "[ChatGPTImageBridge] TransferId: $TransferId"
    Write-Host "[ChatGPTImageBridge] OutputPath: $($manifest.outputPath)"
    Write-Host "[ChatGPTImageBridge] Chunks: $($chunkFiles.Count) / $($manifest.chunkCount)"
    exit 0
}

if ($chunkFiles.Count -ne [int]$manifest.chunkCount) {
    throw "Chunk count mismatch: expected $($manifest.chunkCount), actual $($chunkFiles.Count)"
}

for ($i = 0; $i -lt $chunkFiles.Count; $i++) {
    $expectedName = ('{0:D6}.b64' -f $i)
    if ($chunkFiles[$i].Name -ne $expectedName) {
        throw "Invalid chunk sequence. Expected $expectedName but found $($chunkFiles[$i].Name)"
    }
}

$base64Builder = New-Object System.Text.StringBuilder
foreach ($chunk in $chunkFiles) {
    $text = Get-Content -LiteralPath $chunk.FullName -Raw -Encoding ASCII
    [void]$base64Builder.Append(($text -replace '\s', ''))
}

try {
    $bytes = [Convert]::FromBase64String($base64Builder.ToString())
} catch {
    throw 'Invalid Base64 payload.'
}

if ($bytes.LongLength -ne [long]$manifest.decodedBytes) {
    throw "Decoded size mismatch: expected $($manifest.decodedBytes), actual $($bytes.LongLength)"
}

$sha = [System.Security.Cryptography.SHA256]::Create()
try {
    $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
} finally {
    $sha.Dispose()
}
if ($hash -ne ([string]$manifest.sha256).ToLowerInvariant()) {
    throw "SHA-256 mismatch: expected $($manifest.sha256), actual $hash"
}

$outputPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$manifest.outputPath)))
$repoPrefix = $repoRoot.TrimEnd('\') + '\'
if (-not $outputPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputPath must stay inside this repository.'
}
if ($outputPath.Contains('\.git\')) {
    throw 'Writing under .git is not allowed.'
}

$ext = [System.IO.Path]::GetExtension($outputPath).ToLowerInvariant()
$contentType = ([string]$manifest.contentType).ToLowerInvariant()
$allowed = @{
    '.png' = 'image/png'
    '.jpg' = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.webp' = 'image/webp'
    '.gif' = 'image/gif'
}
if (-not $allowed.ContainsKey($ext) -or $allowed[$ext] -ne $contentType) {
    throw "Extension/contentType mismatch: $ext / $contentType"
}

if ((Test-Path -LiteralPath $outputPath) -and -not $Force) {
    throw "Output already exists. Use -Force to replace: $outputPath"
}

$outputDir = Split-Path -Parent $outputPath
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
$tempPath = "$outputPath.tmp-$([Guid]::NewGuid().ToString('N'))"
[System.IO.File]::WriteAllBytes($tempPath, $bytes)
Move-Item -LiteralPath $tempPath -Destination $outputPath -Force

Write-Host "[ChatGPTImageBridge] Saved: $outputPath"
Write-Host "[ChatGPTImageBridge] Bytes: $($bytes.LongLength)"
Write-Host "[ChatGPTImageBridge] SHA-256: $hash"

if ($Cleanup) {
    Remove-Item -LiteralPath $transferRoot -Recurse -Force
    Write-Host "[ChatGPTImageBridge] Cleaned: $transferRoot"
}

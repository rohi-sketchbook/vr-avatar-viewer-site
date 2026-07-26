[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TransferId,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [ValidateRange(0.05, 1.0)]
    [double]$Scale = 0.5,
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
if (-not (Test-Path -LiteralPath $transferRoot)) {
    throw "Transfer folder not found: $transferRoot"
}

$payloadFiles = @(Get-ChildItem -LiteralPath $transferRoot -Filter '*.b64' -File | Sort-Object Name)
if ($payloadFiles.Count -eq 0) {
    $chunksRoot = Join-Path $transferRoot 'chunks'
    if (Test-Path -LiteralPath $chunksRoot) {
        $payloadFiles = @(Get-ChildItem -LiteralPath $chunksRoot -Filter '*.b64' -File | Sort-Object Name)
    }
}
if ($payloadFiles.Count -eq 0) {
    throw "No .b64 payload files found under: $transferRoot"
}

$builder = New-Object System.Text.StringBuilder
foreach ($file in $payloadFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding ASCII
    $text = $text -replace '^data:image/[^;]+;base64,', ''
    [void]$builder.Append(($text -replace '\s', ''))
}

try {
    $sourceBytes = [Convert]::FromBase64String($builder.ToString())
} catch {
    throw 'Invalid Base64 payload.'
}

if ($sourceBytes.LongLength -gt 64MB) {
    throw "Decoded image is too large: $($sourceBytes.LongLength) bytes"
}

$isPng = $sourceBytes.Length -ge 8 -and
    $sourceBytes[0] -eq 0x89 -and $sourceBytes[1] -eq 0x50 -and $sourceBytes[2] -eq 0x4E -and $sourceBytes[3] -eq 0x47 -and
    $sourceBytes[4] -eq 0x0D -and $sourceBytes[5] -eq 0x0A -and $sourceBytes[6] -eq 0x1A -and $sourceBytes[7] -eq 0x0A
$isJpeg = $sourceBytes.Length -ge 3 -and $sourceBytes[0] -eq 0xFF -and $sourceBytes[1] -eq 0xD8 -and $sourceBytes[2] -eq 0xFF
$isWebp = $sourceBytes.Length -ge 12 -and
    $sourceBytes[0] -eq 0x52 -and $sourceBytes[1] -eq 0x49 -and $sourceBytes[2] -eq 0x46 -and $sourceBytes[3] -eq 0x46 -and
    $sourceBytes[8] -eq 0x57 -and $sourceBytes[9] -eq 0x45 -and $sourceBytes[10] -eq 0x42 -and $sourceBytes[11] -eq 0x50

if (-not $isPng -and -not $isJpeg -and -not $isWebp) {
    throw 'Only PNG, JPEG, or WebP Base64 payloads are supported by this simplified importer.'
}

$outputFullPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputPath))
$repoPrefix = $repoRoot.TrimEnd('\') + '\'
if (-not $outputFullPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputPath must stay inside this repository.'
}
if ($outputFullPath.Contains('\.git\')) {
    throw 'Writing under .git is not allowed.'
}
if ((Test-Path -LiteralPath $outputFullPath) -and -not $Force) {
    throw "Output already exists. Use -Force to replace: $outputFullPath"
}

$ext = [System.IO.Path]::GetExtension($outputFullPath).ToLowerInvariant()
if ($ext -ne '.png' -and $ext -ne '.jpg' -and $ext -ne '.jpeg' -and $ext -ne '.webp') {
    throw 'OutputPath must end in .png, .jpg, .jpeg, or .webp.'
}

if ($isWebp) {
    if ($ext -ne '.webp') {
        throw 'WebP input must use a .webp output path.'
    }
    if ([Math]::Abs($Scale - 1.0) -gt 0.000001) {
        throw 'WebP resizing is not available in System.Drawing. Pre-resize the WebP payload and use -Scale 1.'
    }
    $outputDir = Split-Path -Parent $outputFullPath
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    $tempPath = "$outputFullPath.tmp-$([Guid]::NewGuid().ToString('N'))"
    [System.IO.File]::WriteAllBytes($tempPath, $sourceBytes)
    Move-Item -LiteralPath $tempPath -Destination $outputFullPath -Force

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = ([BitConverter]::ToString($sha.ComputeHash($sourceBytes))).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
    Write-Host "[ChatGPTImageImport] Source files: $($payloadFiles.Count)"
    Write-Host "[ChatGPTImageImport] Saved WebP: $outputFullPath"
    Write-Host "[ChatGPTImageImport] Output bytes: $($sourceBytes.LongLength)"
    Write-Host "[ChatGPTImageImport] SHA-256: $hash"

    if ($Cleanup) {
        Remove-Item -LiteralPath $transferRoot -Recurse -Force
        Write-Host "[ChatGPTImageImport] Cleaned: $transferRoot"
    }
    exit 0
}

Add-Type -AssemblyName System.Drawing
$inputStream = New-Object System.IO.MemoryStream(,$sourceBytes)
$sourceImage = $null
$resizedBitmap = $null
$graphics = $null
try {
    $sourceImage = [System.Drawing.Image]::FromStream($inputStream, $true, $true)
    $targetWidth = [Math]::Max(1, [int][Math]::Round($sourceImage.Width * $Scale))
    $targetHeight = [Math]::Max(1, [int][Math]::Round($sourceImage.Height * $Scale))

    $resizedBitmap = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $resizedBitmap.SetResolution($sourceImage.HorizontalResolution, $sourceImage.VerticalResolution)
    $graphics = [System.Drawing.Graphics]::FromImage($resizedBitmap)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($sourceImage, 0, 0, $targetWidth, $targetHeight)

    $outputDir = Split-Path -Parent $outputFullPath
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    $tempPath = "$outputFullPath.tmp-$([Guid]::NewGuid().ToString('N'))"

    if ($ext -eq '.png') {
        $resizedBitmap.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } else {
        $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
        $encoder = [System.Drawing.Imaging.Encoder]::Quality
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encoder, [long]95)
        try {
            $resizedBitmap.Save($tempPath, $jpegCodec, $encoderParams)
        } finally {
            $encoderParams.Dispose()
        }
    }

    Move-Item -LiteralPath $tempPath -Destination $outputFullPath -Force

    $savedBytes = [System.IO.File]::ReadAllBytes($outputFullPath)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = ([BitConverter]::ToString($sha.ComputeHash($savedBytes))).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }

    Write-Host "[ChatGPTImageImport] Source files: $($payloadFiles.Count)"
    Write-Host "[ChatGPTImageImport] Source: $($sourceImage.Width)x$($sourceImage.Height), $($sourceBytes.LongLength) bytes"
    Write-Host "[ChatGPTImageImport] Saved: $outputFullPath"
    Write-Host "[ChatGPTImageImport] Output: ${targetWidth}x${targetHeight}, $($savedBytes.LongLength) bytes"
    Write-Host "[ChatGPTImageImport] SHA-256: $hash"
} finally {
    if ($graphics) { $graphics.Dispose() }
    if ($resizedBitmap) { $resizedBitmap.Dispose() }
    if ($sourceImage) { $sourceImage.Dispose() }
    $inputStream.Dispose()
}

if ($Cleanup) {
    Remove-Item -LiteralPath $transferRoot -Recurse -Force
    Write-Host "[ChatGPTImageImport] Cleaned: $transferRoot"
}

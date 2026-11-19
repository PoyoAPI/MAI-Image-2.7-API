Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host "Checking Node.js syntax"
Get-ChildItem -LiteralPath $Root -Recurse -Filter *.mjs -File | Where-Object { $_.FullName -notmatch "[\\/](node_modules|\.git)[\\/]" } | ForEach-Object {
  & node --check $_.FullName
  if ($LASTEXITCODE -ne 0) { throw "Node syntax failed: $($_.FullName)" }
}

Write-Host "Checking missing-key behavior"
$oldKey = $env:POYO_API_KEY
Remove-Item Env:\POYO_API_KEY -ErrorAction SilentlyContinue
try {
  $previousErrorAction = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $output = (& node (Join-Path $Root "node/index.mjs") 2>&1 | Out-String)
  $nodeExitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousErrorAction
  if ($nodeExitCode -eq 0 -or $output -notmatch "POYO_API_KEY") { throw "Node example must fail safely without POYO_API_KEY" }
} finally {
  $ErrorActionPreference = "Stop"
  if ($null -ne $oldKey) { $env:POYO_API_KEY = $oldKey }
}

Write-Host "Checking request payloads"
$allowedModels = @("mai-image-2.7", "mai-image-2.7-flash")
$allowedFields = @("prompt", "image_urls", "size", "resolution", "background", "output_format")
$ratios = @("1:1", "4:3", "3:4", "3:2", "2:3", "16:9", "9:16")
Get-ChildItem -LiteralPath (Join-Path $Root "payloads") -Filter *.json -File | ForEach-Object {
  $name = $_.Name
  $payload = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8) | ConvertFrom-Json
  if ($allowedModels -notcontains $payload.model) { throw "Unexpected model in ${name}: $($payload.model)" }
  $req = $payload.input
  if (-not $req.prompt -or -not $req.prompt.Trim()) { throw "prompt is required in $name" }
  foreach ($field in $req.PSObject.Properties.Name) {
    if ($allowedFields -notcontains $field) { throw "Unknown input field '$field' in $name" }
  }
  $fields = $req.PSObject.Properties.Name
  if ($fields -contains "image_urls") {
    $urls = @($req.image_urls)
    if ($urls.Count -lt 1 -or $urls.Count -gt 5) { throw "image_urls must hold 1-5 URLs in $name" }
    foreach ($url in $urls) { if ($url -notmatch "^https://") { throw "image_urls must be public HTTPS URLs in $name" } }
  }
  if ($fields -contains "resolution" -and @("1K", "2K") -notcontains $req.resolution) { throw "resolution must be 1K or 2K in $name" }
  if ($fields -contains "size" -and $ratios -notcontains $req.size) {
    if ($req.size -notmatch "^(\d+)x(\d+)$") { throw "size must be an aspect ratio or WIDTHxHEIGHT in $name" }
    $width = [int]$Matches[1]; $height = [int]$Matches[2]
    if ($width % 16 -or $height % 16 -or [Math]::Min($width, $height) -lt 768 -or $width * $height -gt 4194304) {
      throw "Custom size needs sides divisible by 16, each side at least 768, and at most 4194304 pixels in $name"
    }
  }
  $format = if ($fields -contains "output_format") { $req.output_format } else { "png" }
  if (@("png", "jpeg", "webp") -notcontains $format) { throw "output_format must be png, jpeg, or webp in $name" }
  if ($fields -contains "background") {
    if (@("opaque", "transparent") -notcontains $req.background) { throw "background must be opaque or transparent in $name" }
    if ($req.background -eq "transparent" -and @("png", "webp") -notcontains $format) { throw "Transparent background needs png or webp in $name" }
  }
}

Write-Host "Checking Python example"
& python -m py_compile (Join-Path $Root "python/generate.py")
if ($LASTEXITCODE -ne 0) { throw "Python syntax failed" }
$oldKey = $env:POYO_API_KEY
Remove-Item Env:\POYO_API_KEY -ErrorAction SilentlyContinue
try {
  $ErrorActionPreference = "Continue"
  $output = (& python (Join-Path $Root "python/generate.py") 2>&1 | Out-String)
  $pythonExitCode = $LASTEXITCODE
  $ErrorActionPreference = "Stop"
  if ($pythonExitCode -eq 0 -or $output -notmatch "POYO_API_KEY") { throw "Python example must fail safely without POYO_API_KEY" }
} finally {
  $ErrorActionPreference = "Stop"
  if ($null -ne $oldKey) { $env:POYO_API_KEY = $oldKey }
}

Write-Host "Checking README links and assets"
$readme = [IO.File]::ReadAllText((Join-Path $Root "README.md"), [Text.Encoding]::UTF8)
foreach ($match in [regex]::Matches($readme, 'src="(assets/[^"]+)"')) {
  if (-not (Test-Path -LiteralPath (Join-Path $Root $match.Groups[1].Value))) { throw "Missing gallery asset: $($match.Groups[1].Value)" }
}
$textFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -Include *.md, *.json, *.mjs, *.py | Where-Object { $_.FullName -notmatch "[\\/](node_modules|\.git)[\\/]" }
foreach ($file in $textFiles) {
  $text = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
  foreach ($match in [regex]::Matches($text, 'https://(docs\.)?poyo\.ai/[^\s)"''>]*')) {
    if ($match.Value -notmatch "utm_campaign=mai-image-2-7-api") { throw "Link without UTM in $($file.Name): $($match.Value)" }
  }
}

Write-Host "Scanning for committed secrets"
$files = Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object { $_.FullName -notmatch "[\\/](node_modules|\.git)[\\/]" }
foreach ($file in $files) {
  $text = [IO.File]::ReadAllText($file.FullName)
  if ($text -match "poyo_[A-Za-z0-9_-]{20,}") { throw "Possible API key in $($file.FullName)" }
  if ($text -match "sk-[A-Za-z0-9]{24,}") { throw "Possible API key in $($file.FullName)" }
}
Write-Host "All checks passed."
exit 0

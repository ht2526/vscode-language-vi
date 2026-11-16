@echo off
setlocal
pushd "%~dp0"
set "PS1=%TEMP%\hungthinhpack-build-%RANDOM%-%RANDOM%.ps1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$text=[IO.File]::ReadAllText('%~f0'); $marker='#__PS_PAYLOAD_BEGIN__'; $index=$text.LastIndexOf($marker); if($index -lt 0){exit 90}; $scriptText=$text.Substring($index+$marker.Length).TrimStart([char[]]@(13,10)); [IO.File]::WriteAllText('%PS1%',$scriptText,[Text.Encoding]::UTF8)"
if errorlevel 1 goto extraction_failed
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "BUILD_EXIT=%ERRORLEVEL%"
del "%PS1%" >nul 2>&1
popd
if not "%BUILD_EXIT%"=="0" (
  echo VSIX build failed with exit code %BUILD_EXIT%.
  pause
  exit /b %BUILD_EXIT%
)
echo VSIX build completed successfully.
pause
exit /b 0
:extraction_failed
set "BUILD_EXIT=%ERRORLEVEL%"
del "%PS1%" >nul 2>&1
popd
echo Could not prepare the embedded PowerShell build script.
pause
exit /b %BUILD_EXIT%
#__PS_PAYLOAD_BEGIN__
$ErrorActionPreference = 'Stop'

function Child($parent, $name) {
  foreach ($n in $parent.ChildNodes) { if ($n.NodeType -eq 'Element' -and $n.LocalName -eq $name) { return $n } }
  return $null
}
function Ensure($doc, $parent, $name, $ns) {
  $n = Child $parent $name
  if (-not $n) { $n = $doc.CreateElement($name, $ns); [void]$parent.AppendChild($n) }
  return $n
}
function SetProp($doc, $props, $id, $value, $ns) {
  $n = $null
  foreach ($item in $props.ChildNodes) { if ($item.LocalName -eq 'Property' -and $item.GetAttribute('Id') -eq $id) { $n = $item; break } }
  if (-not $n) { $n = $doc.CreateElement('Property', $ns); [void]$props.AppendChild($n) }
  $n.SetAttribute('Id', $id); $n.SetAttribute('Value', $value)
}
function AddBytes($zip, $name, [byte[]]$bytes) {
  $entry = $zip.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
  $entry.LastWriteTime = [DateTimeOffset]::Parse('1980-01-01T00:00:00Z')
  $stream = $entry.Open()
  try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
}
function XmlBytes($document) {
  $settings = New-Object System.Xml.XmlWriterSettings
  $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
  $settings.Indent = $true
  $stream = New-Object System.IO.MemoryStream
  $writer = [System.Xml.XmlWriter]::Create($stream, $settings)
  try { $document.Save($writer); $writer.Flush(); return ,$stream.ToArray() }
  finally { $writer.Dispose(); $stream.Dispose() }
}

try {
  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  Add-Type -AssemblyName System.Web.Extensions
  $jsonSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
  $jsonSerializer.MaxJsonLength = [int]::MaxValue
  $jsonSerializer.RecursionLimit = 512
  $root = [IO.Path]::GetFullPath((Get-Location).Path)
  $package = Get-Content -LiteralPath (Join-Path $root 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($field in @('publisher','name','version','displayName')) {
    if ([string]::IsNullOrWhiteSpace([string]$package.$field)) { throw "package.json is missing '$field'." }
  }
  if ($package.name -notmatch '^[A-Za-z0-9._-]+$' -or $package.publisher -notmatch '^[A-Za-z0-9._-]+$') { throw 'Invalid publisher or extension name.' }
  if ($package.version -notmatch '^\d+\.\d+\.\d+([+-][A-Za-z0-9.-]+)?$') { throw "Invalid version: $($package.version)" }
  if (-not $package.engines.vscode -or -not $package.contributes.localizations) { throw 'engines.vscode and contributes.localizations are required.' }

  $prefix = $root.TrimEnd([char]92,[char]47) + [IO.Path]::DirectorySeparatorChar
  $catalogEntries = New-Object 'System.Collections.Generic.List[string]'
  $translationAssets = New-Object 'System.Collections.Generic.List[object]'
  foreach ($locale in @($package.contributes.localizations)) {
    if (-not $locale.languageId -or -not $locale.translations) { throw 'A localization is missing languageId or translations.' }
    foreach ($translation in @($locale.translations)) {
      if (-not $translation.id -or -not $translation.path) { throw 'A translation entry is missing id or path.' }
      $relative = ([string]$translation.path).Replace('/',[IO.Path]::DirectorySeparatorChar).TrimStart([char]92,[char]47)
      $path = [IO.Path]::GetFullPath((Join-Path $root $relative))
      if (-not $path.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing or unsafe catalog: $($translation.path)" }
      try {
        $rawCatalog = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        [void]$jsonSerializer.DeserializeObject($rawCatalog)
      } catch { throw "Invalid JSON catalog '$($translation.path)': $($_.Exception.Message)" }
      $archivePath = 'extension/' + $path.Substring($prefix.Length).Replace('\','/')
      $catalogEntries.Add($archivePath)
      $translationAssets.Add(@{ Type = 'Microsoft.VisualStudio.Code.Translation.' + ([string]$locale.languageId).ToUpperInvariant(); Path = $archivePath })
    }
  }
  if ($catalogEntries.Count -eq 0) { throw 'No translation catalogs were found in package.json.' }
  if ($package.icon) {
    $icon = [IO.Path]::GetFullPath((Join-Path $root ([string]$package.icon).Replace('/',[IO.Path]::DirectorySeparatorChar)))
    if (-not $icon.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $icon -PathType Leaf)) { throw "Missing or unsafe icon: $($package.icon)" }
  }

  $manifestPath = Join-Path $root '.vsixmanifest'
  $manifest = New-Object System.Xml.XmlDocument
  $manifest.PreserveWhitespace = $false
  $manifest.Load($manifestPath)
  $manifestRoot = $manifest.DocumentElement
  $ns = $manifestRoot.NamespaceURI
  $metadata = Ensure $manifest $manifestRoot 'Metadata' $ns
  $identity = Ensure $manifest $metadata 'Identity' $ns
  $identity.SetAttribute('Language','en-US'); $identity.SetAttribute('Id',[string]$package.name)
  $identity.SetAttribute('Publisher',[string]$package.publisher); $identity.SetAttribute('Version',[string]$package.version)
  (Ensure $manifest $metadata 'DisplayName' $ns).InnerText = [string]$package.displayName
  $description = Ensure $manifest $metadata 'Description' $ns
  if ($package.description) { $description.InnerText = [string]$package.description }

  $tags = New-Object 'System.Collections.Generic.List[string]'
  foreach ($keyword in @($package.keywords)) { if ($keyword -and -not $tags.Contains([string]$keyword)) { $tags.Add([string]$keyword) } }
  $versionTag = [regex]::Match([string]$package.engines.vscode,'\d+\.\d+')
  if ($versionTag.Success -and -not $tags.Contains('vscode-' + $versionTag.Value)) { $tags.Add('vscode-' + $versionTag.Value) }
  foreach ($locale in @($package.contributes.localizations)) {
    $lang = [string]$locale.languageId
    if (-not $tags.Contains('lp-' + $lang)) { $tags.Add('lp-' + $lang) }
    foreach ($translation in @($locale.translations)) {
      foreach ($tag in @('__lp_' + $translation.id, '__lp-' + $lang + '_' + $translation.id)) { if (-not $tags.Contains($tag)) { $tags.Add($tag) } }
    }
  }
  (Ensure $manifest $metadata 'Tags' $ns).InnerText = $tags -join ','
  if (@($package.categories).Count -gt 0) { (Ensure $manifest $metadata 'Categories' $ns).InnerText = @($package.categories) -join ',' }
  $props = Ensure $manifest $metadata 'Properties' $ns
  SetProp $manifest $props 'Microsoft.VisualStudio.Code.Engine' ([string]$package.engines.vscode) $ns
  SetProp $manifest $props 'Microsoft.VisualStudio.Code.ExtensionDependencies' (@($package.dependencies) -join ',') $ns
  SetProp $manifest $props 'Microsoft.VisualStudio.Code.ExtensionPack' (@($package.extensionPack) -join ',') $ns
  $localizedNames = @($package.contributes.localizations | ForEach-Object { if ($_.localizedLanguageName) { $_.localizedLanguageName } else { $_.languageName } } | Where-Object { $_ }) -join ','
  if ($localizedNames) { SetProp $manifest $props 'Microsoft.VisualStudio.Code.LocalizedLanguages' $localizedNames $ns }

  $minimum = [regex]::Match([string]$package.engines.vscode,'\d+\.\d+\.\d+')
  if (-not $minimum.Success) { throw "Cannot read minimum VS Code version: $($package.engines.vscode)" }
  $installation = Ensure $manifest $manifestRoot 'Installation' $ns
  $target = Ensure $manifest $installation 'InstallationTarget' $ns
  $target.SetAttribute('Id','Microsoft.VisualStudio.Code')
  $target.SetAttribute('Version','[' + $minimum.Value + ',2.0.0)')
  [void](Ensure $manifest $manifestRoot 'Dependencies' $ns)
  $assets = Ensure $manifest $manifestRoot 'Assets' $ns
  $managedTypes = @('Microsoft.VisualStudio.Code.Manifest','Microsoft.VisualStudio.Services.Content.Details','Microsoft.VisualStudio.Services.Content.License','Microsoft.VisualStudio.Services.Content.Changelog','Microsoft.VisualStudio.Services.Icons.Default')
  $staleAssets = @($assets.ChildNodes | Where-Object {
    if ($_.NodeType -ne [System.Xml.XmlNodeType]::Element -or $_.LocalName -ne 'Asset') { return $false }
    $type = $_.GetAttribute('Type')
    ($managedTypes -contains $type) -or $type.StartsWith('Microsoft.VisualStudio.Code.Translation.',[StringComparison]::Ordinal)
  })
  foreach ($asset in $staleAssets) { [void]$assets.RemoveChild($asset) }
  $desiredAssets = New-Object 'System.Collections.Generic.List[object]'
  $desiredAssets.Add(@{ Type = 'Microsoft.VisualStudio.Code.Manifest'; Path = 'extension/package.json' })
  foreach ($optional in @(@{ Type = 'Microsoft.VisualStudio.Services.Content.Details'; Path = 'readme.md' },@{ Type = 'Microsoft.VisualStudio.Services.Content.License'; Path = 'LICENSE.txt' },@{ Type = 'Microsoft.VisualStudio.Services.Content.Changelog'; Path = 'changelog.md' })) {
    if (Test-Path -LiteralPath (Join-Path $root $optional.Path) -PathType Leaf) { $desiredAssets.Add(@{ Type = $optional.Type; Path = 'extension/' + $optional.Path }) }
  }
  if ($package.icon) {
    $iconRelative = ([string]$package.icon).Replace('\','/').TrimStart([char]92,[char]47)
    $desiredAssets.Add(@{ Type = 'Microsoft.VisualStudio.Services.Icons.Default'; Path = 'extension/' + $iconRelative })
  }
  foreach ($assetSpec in $translationAssets) { $desiredAssets.Add($assetSpec) }
  foreach ($assetSpec in $desiredAssets) {
    $asset = $manifest.CreateElement('Asset',$ns)
    $asset.SetAttribute('Type',$assetSpec.Type); $asset.SetAttribute('Path',$assetSpec.Path); $asset.SetAttribute('Addressable','true')
    [void]$assets.AppendChild($asset)
  }
  $manifestBytes = XmlBytes $manifest

  $files = @(Get-ChildItem -LiteralPath $root -Recurse -File -Force | Where-Object {
    $rel = $_.FullName.Substring($root.Length).TrimStart([char[]]@(92,47)); $parts = $rel -split '[\\/]'
    ($parts -notcontains '.git') -and ($parts -notcontains 'node_modules') -and
    ($_.Name -notin @('.vsixmanifest','build_vsix.bat','.vscodeignore')) -and ($_.Extension -ine '.vsix')
  })
  if ($files.Count -eq 0) { throw 'No extension files to package.' }

  $ct = New-Object System.Xml.XmlDocument
  [void]$ct.AppendChild($ct.CreateXmlDeclaration('1.0','utf-8',$null))
  $ctRoot = $ct.CreateElement('Types','http://schemas.openxmlformats.org/package/2006/content-types')
  [void]$ct.AppendChild($ctRoot)
  $mime = @{ json='application/json'; md='text/markdown'; txt='text/plain'; png='image/png'; jpg='image/jpeg'; jpeg='image/jpeg'; gif='image/gif'; svg='image/svg+xml'; xml='text/xml'; vsixmanifest='text/xml' }
  $extensions = New-Object 'System.Collections.Generic.SortedSet[string]' ([StringComparer]::OrdinalIgnoreCase)
  foreach ($file in $files) { if ($file.Extension) { [void]$extensions.Add($file.Extension.TrimStart('.').ToLowerInvariant()) } }
  [void]$extensions.Add('vsixmanifest')
  foreach ($ext in $extensions) {
    $node = $ct.CreateElement('Default',$ctRoot.NamespaceURI); $node.SetAttribute('Extension',$ext)
    if ($mime.ContainsKey($ext)) { $node.SetAttribute('ContentType',$mime[$ext]) } else { $node.SetAttribute('ContentType','application/octet-stream') }
    [void]$ctRoot.AppendChild($node)
  }
  $override = $ct.CreateElement('Override',$ctRoot.NamespaceURI)
  $override.SetAttribute('PartName','/extension.vsixmanifest'); $override.SetAttribute('ContentType','text/xml')
  [void]$ctRoot.AppendChild($override)
  $ctBytes = XmlBytes $ct

  $output = Join-Path $root ($package.name + '-' + $package.version + '.vsix')
  $temp = Join-Path ([IO.Path]::GetTempPath()) ('hungthinhpack-' + [Guid]::NewGuid().ToString('N') + '.vsix')
  $stream = [IO.File]::Open($temp,[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
  $zip = $null
  try {
    $zip = New-Object System.IO.Compression.ZipArchive($stream,[IO.Compression.ZipArchiveMode]::Create,$true)
    AddBytes $zip '[Content_Types].xml' $ctBytes
    AddBytes $zip 'extension.vsixmanifest' $manifestBytes
    foreach ($file in $files) {
      $rel = $file.FullName.Substring($root.Length).TrimStart([char[]]@(92,47))
      [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,('extension/' + $rel.Replace('\','/')),[IO.Compression.CompressionLevel]::Optimal)
    }
  } finally { if ($zip) { $zip.Dispose() }; $stream.Dispose() }

  $check = [IO.Compression.ZipFile]::OpenRead($temp)
  try {
    $names = @{}; foreach ($entry in $check.Entries) { $names[$entry.FullName] = $true }
    foreach ($required in @('[Content_Types].xml','extension.vsixmanifest','extension/package.json') + @($catalogEntries)) {
      if (-not $names.ContainsKey($required)) { throw "VSIX is missing required entry: $required" }
    }
    $entry = $check.GetEntry('extension.vsixmanifest')
    $reader = New-Object IO.StreamReader($entry.Open())
    try { [void][xml]$reader.ReadToEnd() } finally { $reader.Dispose() }
  } finally { $check.Dispose() }

  $manifestTemp = $manifestPath + '.tmp'
  [IO.File]::WriteAllBytes($manifestTemp,$manifestBytes)
  Move-Item -LiteralPath $manifestTemp -Destination $manifestPath -Force
  Move-Item -LiteralPath $temp -Destination $output -Force
  Write-Host "VSIX: $output"
  Write-Host "Size: $((Get-Item -LiteralPath $output).Length) bytes"
  Write-Host "SHA-256: $((Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash)"
  Write-Host "Validated translation catalogs: $($catalogEntries.Count)"
  exit 0
} catch {
  Write-Error $_
  exit 1
}

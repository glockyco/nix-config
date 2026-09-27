{
  byRole,
  applicationMetadata,
  powershell,
}:

let
  application = byRole "terminal-font";
  specification = {
    url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${application.version}/JetBrainsMono.zip";
  }
  // application.release;
in

{
  resource = {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "package-terminal-font";
    properties = {
      testScript = ''
        $specification = ${powershell.psJson specification} | ConvertFrom-Json
        $destinationDirectory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
        $registryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
        $registeredFonts = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
        if ($null -eq $registeredFonts) { return $false }
        foreach ($font in $specification.fonts.PSObject.Properties) {
          $destination = Join-Path $destinationDirectory $font.Name
          if (-not (Test-Path -LiteralPath $destination)) { return $false }
          if (${powershell.sha256Of "$destination"} -ne $font.Value.sha256) { return $false }
          if ($registeredFonts.PSObject.Properties[$font.Value.registryName].Value -ne $destination) { return $false }
        }
        foreach ($legacyName in $specification.legacyRegistryNames) {
          if ($null -ne $registeredFonts.PSObject.Properties[$legacyName]) { return $false }
        }
        Add-Type -AssemblyName System.Drawing
        $families = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        return ($families -contains 'JetBrainsMonoNL NF')
      '';
      setScript = ''
        $specification = ${powershell.psJson specification} | ConvertFrom-Json
        $archive = Join-Path $env:TEMP 'JetBrainsMono-${application.version}.zip'
        $expanded = Join-Path $env:TEMP 'JetBrainsMono-${application.version}'
        $destinationDirectory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
        $registryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
        $fontApi = Add-Type -Namespace WindowsConfiguration -Name FontApi -MemberDefinition @'
          [System.Runtime.InteropServices.DllImport("gdi32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode, SetLastError = true)]
          public static extern int AddFontResourceEx(string filename, uint flags, System.IntPtr reserved);
          [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)]
          public static extern System.IntPtr SendMessageTimeout(System.IntPtr window, uint message, System.UIntPtr wParam, System.IntPtr lParam, uint flags, uint timeout, out System.UIntPtr result);
        '@ -PassThru
        try {
          ${powershell.expandArchive {
            variable = "$specification";
            label = "JetBrainsMono";
          }}
          New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
          New-Item -Path $registryPath -Force | Out-Null
          foreach ($legacyName in $specification.legacyRegistryNames) {
            Remove-ItemProperty -Path $registryPath -Name $legacyName -ErrorAction SilentlyContinue
          }
          foreach ($font in $specification.fonts.PSObject.Properties) {
            $source = Join-Path $expanded $font.Name
            if (${powershell.sha256Of "$source"} -ne $font.Value.sha256) { throw "$($font.Name) checksum mismatch" }
            $destination = Join-Path $destinationDirectory $font.Name
            if (-not (Test-Path -LiteralPath $destination) -or ${powershell.sha256Of "$destination"} -ne $font.Value.sha256) {
              Copy-Item -LiteralPath $source -Destination $destination -Force
            }
            New-ItemProperty -Path $registryPath -Name $font.Value.registryName -Value $destination -PropertyType String -Force | Out-Null
            if ($fontApi::AddFontResourceEx($destination, 0, [IntPtr]::Zero) -eq 0) { throw "$($font.Name) could not be loaded" }
          }
          $broadcastResult = [UIntPtr]::Zero
          [void]$fontApi::SendMessageTimeout([IntPtr]0xffff, 0x001d, [UIntPtr]::Zero, [IntPtr]::Zero, 0x0002, 5000, [ref]$broadcastResult)
        } finally {
          Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
          Remove-Item -LiteralPath $expanded -Recurse -Force -ErrorAction SilentlyContinue
        }
      '';
    };
    metadata = {
      description = "Install the pinned JetBrainsMono Nerd Font faces for the interactive user";
      application = applicationMetadata application;
    };
  };
}

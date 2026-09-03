let
  version = "3.3.0";
  specification = {
    url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/JetBrainsMono.zip";
    archiveSha256 = "2d83782a350b604bfa70fce880604a41a7f77c3eec8f922f9cdc3c20952ddbe4";
    fonts = {
      "JetBrainsMonoNLNerdFont-Regular.ttf" = {
        registryName = "JetBrainsMonoNL Nerd Font (TrueType)";
        sha256 = "faf66bbb979ed5b0e73c91b4939ada2e737f5bf7b5d510085e459c226df397e1";
      };
      "JetBrainsMonoNLNerdFont-Bold.ttf" = {
        registryName = "JetBrainsMonoNL Nerd Font Bold (TrueType)";
        sha256 = "7779588d91cd33e7b69c1ea62b0eb4b2ea89e1e723223c31ece3bbf6ab1e182e";
      };
      "JetBrainsMonoNLNerdFont-Italic.ttf" = {
        registryName = "JetBrainsMonoNL Nerd Font Italic (TrueType)";
        sha256 = "221ad50706755754440e7761d674e506aac3ef25def2b950799ee6a039b55869";
      };
      "JetBrainsMonoNLNerdFont-BoldItalic.ttf" = {
        registryName = "JetBrainsMonoNL Nerd Font Bold Italic (TrueType)";
        sha256 = "c00c4adabbc95f7b7ad834c64baa48622e6ecfd1d6c28428a72823e37c1dd536";
      };
    };
  };
  specificationJson = builtins.toJSON specification;
in

{
  files = { };

  resource = {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "package-terminal-font";
    properties = {
      testScript = ''
        $specification = '${specificationJson}' | ConvertFrom-Json
        $destinationDirectory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
        $registryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
        foreach ($font in $specification.fonts.PSObject.Properties) {
          $destination = Join-Path $destinationDirectory $font.Name
          if (-not (Test-Path -LiteralPath $destination)) { return $false }
          if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant() -ne $font.Value.sha256) { return $false }
          if ((Get-ItemPropertyValue -Path $registryPath -Name $font.Value.registryName -ErrorAction SilentlyContinue) -ne $font.Name) { return $false }
        }
        return $true
      '';
      setScript = ''
        $specification = '${specificationJson}' | ConvertFrom-Json
        $archive = Join-Path $env:TEMP 'JetBrainsMono-3.3.0.zip'
        $expanded = Join-Path $env:TEMP 'JetBrainsMono-3.3.0'
        $destinationDirectory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
        $registryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
        try {
          Invoke-WebRequest -Uri $specification.url -OutFile $archive -UseBasicParsing
          if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $specification.archiveSha256) { throw 'JetBrainsMono archive checksum mismatch' }
          Remove-Item -LiteralPath $expanded -Recurse -Force -ErrorAction SilentlyContinue
          Add-Type -AssemblyName System.IO.Compression.FileSystem
          [IO.Compression.ZipFile]::ExtractToDirectory($archive, $expanded)
          New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
          New-Item -Path $registryPath -Force | Out-Null
          foreach ($font in $specification.fonts.PSObject.Properties) {
            $source = Join-Path $expanded $font.Name
            if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant() -ne $font.Value.sha256) { throw "$($font.Name) checksum mismatch" }
            Copy-Item -LiteralPath $source -Destination (Join-Path $destinationDirectory $font.Name) -Force
            New-ItemProperty -Path $registryPath -Name $font.Value.registryName -Value $font.Name -PropertyType String -Force | Out-Null
          }
        } finally {
          Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
          Remove-Item -LiteralPath $expanded -Recurse -Force -ErrorAction SilentlyContinue
        }
      '';
    };
    metadata = {
      description = "Install the pinned JetBrainsMono Nerd Font faces for the interactive user";
      application = {
        id = "ryanoasis.nerd-fonts.JetBrainsMono";
        roles = [ "terminal-font" ];
        inherit version;
        source = "nerd-fonts-release";
        scope = "user";
      };
    };
  };
}

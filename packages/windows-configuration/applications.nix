[
  {
    name = "Zed";
    role = "editor";
    id = "ZedIndustries.Zed";
    versionPolicy = "self-updating";
    source = "winget";
    scope = "user";
  }
  {
    name = "Zen Browser";
    role = "browser";
    id = "Zen-Team.Zen-Browser";
    versionPolicy = "exact";
    version = "1.21.16b";
    source = "winget";
    scope = "machine";
  }
  {
    name = "Brave";
    role = "browser-relay";
    id = "Brave.Brave";
    versionPolicy = "self-updating";
    source = "winget";
    scope = "user";
  }
  {
    name = "Ferdium";
    role = "communication-client";
    id = "Ferdium.Ferdium";
    versionPolicy = "self-updating";
    source = "winget";
    scope = "user";
  }
  {
    name = "Fork";
    role = "git-client";
    id = "Fork.Fork";
    versionPolicy = "exact";
    version = "2.21.0";
    source = "winget";
    scope = "user";
  }
  {
    name = "PowerToys";
    role = "launcher";
    id = "Microsoft.PowerToys";
    versionPolicy = "exact";
    version = "0.101.2362.0";
    source = "winget";
    scope = "user";
  }
  {
    name = "AltSnap";
    role = "window-tool";
    id = "AltSnap.AltSnap";
    versionPolicy = "exact";
    version = "1.68";
    source = "github-release";
    scope = "user";
    release = {
      url = "https://github.com/RamonUnch/AltSnap/releases/download/1.68/AltSnap1.68bin_x64.zip";
      archiveSha256 = "7db3dad3746e7b23857db92fc05ee2d3e17eee1b28e237709a612366ba909c79";
      executableSha256 = "dba17fbfc2633aac31f5faedb992f4f24ddee3092bb4c803d2b8db83d58255b9";
      hooksSha256 = "fa2ff5c2f76267ab6a1d80e432649da023b94e2183fe2f8c27f254f1b0637ed7";
    };
  }
  {
    name = "ReNeo (Neo2)";
    role = "keyboard-layout";
    id = "Rojetto.ReNeo.neo2";
    versionPolicy = "exact";
    version = "1.6.0";
    source = "winget";
    scope = "user";
  }
  {
    name = "Windows Terminal";
    role = "terminal";
    id = "Microsoft.WindowsTerminal";
    versionPolicy = "exact";
    version = "1.24.11911.0";
    source = "winget";
    scope = "user";
  }
  {
    name = "JetBrainsMono Nerd Font";
    role = "terminal-font";
    id = "ryanoasis.nerd-fonts.JetBrainsMono";
    versionPolicy = "exact";
    version = "3.3.0";
    source = "nerd-fonts-release";
    scope = "user";
    release = {
      archiveSha256 = "2d83782a350b604bfa70fce880604a41a7f77c3eec8f922f9cdc3c20952ddbe4";
      legacyRegistryNames = [
        "JetBrainsMonoNL Nerd Font (TrueType)"
        "JetBrainsMonoNL Nerd Font Bold (TrueType)"
        "JetBrainsMonoNL Nerd Font Italic (TrueType)"
        "JetBrainsMonoNL Nerd Font Bold Italic (TrueType)"
      ];
      fonts = {
        "JetBrainsMonoNLNerdFont-Regular.ttf" = {
          registryName = "JetBrainsMonoNL NF (TrueType)";
          sha256 = "faf66bbb979ed5b0e73c91b4939ada2e737f5bf7b5d510085e459c226df397e1";
        };
        "JetBrainsMonoNLNerdFont-Bold.ttf" = {
          registryName = "JetBrainsMonoNL NF Bold (TrueType)";
          sha256 = "7779588d91cd33e7b69c1ea62b0eb4b2ea89e1e723223c31ece3bbf6ab1e182e";
        };
        "JetBrainsMonoNLNerdFont-Italic.ttf" = {
          registryName = "JetBrainsMonoNL NF Italic (TrueType)";
          sha256 = "221ad50706755754440e7761d674e506aac3ef25def2b950799ee6a039b55869";
        };
        "JetBrainsMonoNLNerdFont-BoldItalic.ttf" = {
          registryName = "JetBrainsMonoNL NF Bold Italic (TrueType)";
          sha256 = "c00c4adabbc95f7b7ad834c64baa48622e6ecfd1d6c28428a72823e37c1dd536";
        };
      };
    };
  }
]

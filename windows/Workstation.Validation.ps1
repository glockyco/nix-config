function Assert-WorkstationRelativePath {
    param(
        [Parameter(Mandatory)][string] $Path,
        [switch] $AllowDot,
        [switch] $FileNameOnly
    )
    if ($AllowDot -and $Path -ceq '.') { return }
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^[\\/]' -or
        $Path -match '[<>:"|?*\x00-\x1f]' -or $Path -match '(^|[\\/])\.{1,2}([\\/]|$)' -or
        $Path -match '[ .]([\\/]|$)' -or $Path -match '[\\/]{2}|[\\/]$' -or
        ($FileNameOnly -and $Path -match '[\\/]')) {
        throw "Destination must be a safe relative path: $Path"
    }
}

function Assert-WorkstationData {
    param(
        [Parameter(Mandatory)][hashtable] $Data,
        [Parameter(Mandatory)][string] $ManagedPath
    )

    $managed = Get-Content -LiteralPath $ManagedPath -Raw -ErrorAction Stop | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    if (-not $managed.ContainsKey('identifiers') -or $managed.identifiers -isnot [array]) {
        throw 'The managed application audit must contain an identifiers array'
    }
    $names = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $ids = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $machineIds = @('Zen-Team.Zen-Browser', 'Tailscale.Tailscale', 'Docker.DockerDesktop')
    # Roles are stable workstation ownership contracts. Release versions remain data.
    $requiredRoles = @{
        'editor' = 'ZedIndustries.Zed'
        'browser' = 'Zen-Team.Zen-Browser'
        'container-runtime' = 'Docker.DockerDesktop'
        'browser-relay' = 'Brave.Brave'
        'communication-client' = 'Ferdium.Ferdium'
        'notes' = 'Obsidian.Obsidian'
        'git-client' = 'Fork.Fork'
        'launcher' = 'Microsoft.PowerToys'
        'keyboard-layout' = 'Rojetto.ReNeo.neo2'
        'terminal-font' = 'ryanoasis.nerd-fonts.JetBrainsMono'
        'window-tool' = 'AltSnap.AltSnap'
        'native-git' = 'Git.Git'
        'source-manager' = 'twpayne.chezmoi'
        'tailnet' = 'Tailscale.Tailscale'
        'vault-cli' = 'Bitwarden.CLI'
        'javascript-runtime' = 'OpenJS.NodeJS.LTS'
        'bun-runtime' = 'Oven-sh.Bun'
        'python-runtime' = 'Python.Python.3.13'
        'python-tooling' = 'astral-sh.uv'
        'repository-manager' = 'x-motemen.ghq'
        'search' = 'BurntSushi.ripgrep.MSVC'
        'find' = 'sharkdp.fd'
        'picker' = 'junegunn.fzf'
        'pager' = 'dandavison.delta'
        'prompt' = 'Starship.Starship'
        'directory-jumper' = 'ajeetdsouza.zoxide'
        'file-lister' = 'eza-community.eza'
        'picker-bindings' = 'PSFzf'
        'git-completion' = 'git-completion'
        'hook-runner' = 'evilmartians.lefthook'
        'secret-scanner' = 'Gitleaks.Gitleaks'
        'markdown-lsp' = 'FelixZeller.markdown-oxide'
        'document-compiler' = 'Typst.Typst'
        'typst-lsp' = 'Myriad-Dreamin.Tinymist'
        'shell' = 'PowerShell.PowerShell'
        'github-cli' = 'GitHub.cli'
        'openspec' = '@fission-ai/openspec'
        'python-lsp' = '@fission-ai/openspec'
        'typescript-lsp' = '@fission-ai/openspec'
        'svelte-lsp' = '@fission-ai/openspec'
        'latex-lsp' = 'TexLab.TexLab'
        'pdf-transform' = 'QPDF.QPDF'
        'image-converter' = 'ImageMagick.ImageMagick'
        'pdf-text' = 'oschwartz10612.Poppler'
        'document-converter' = 'JohnMacFarlane.Pandoc'
    }
    $roles = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $nodeIndex = -1
    $applicationIndex = -1
    foreach ($resource in @($Data.applications) + @($Data.settings)) {
        if (-not $names.Add($resource.name)) { throw "Duplicate resource name: $($resource.name)" }
    }
    foreach ($application in $Data.applications) {
        $applicationIndex++
        if (-not $ids.Add($application.id)) { throw "Duplicate application id: $($application.id)" }
        if ($managed.identifiers -contains $application.id) { throw "Application is centrally managed: $($application.id)" }
        if ($application.scope -eq 'machine' -and ($application.kind -ne 'winget' -or $machineIds -notcontains $application.id)) {
            throw "Unapproved machine application: $($application.id)"
        }
        if ($machineIds -contains $application.id -and $application.scope -ne 'machine') {
            throw "Approved machine installer must declare machine scope: $($application.id)"
        }
        if ($application.id -eq 'Docker.DockerDesktop' -and $application.installArguments -cne 'install --quiet --backend=wsl-2 --no-windows-containers') {
            throw 'Docker Desktop requires exactly the reviewed WSL 2 installer arguments'
        }
        if ($application.ContainsKey('installArguments') -and $application.id -ne 'Docker.DockerDesktop') {
            throw "Installer overrides are allowed only for Docker Desktop: $($application.id)"
        }
        if ($application.versionPolicy -eq 'pinned' -and ([string]::IsNullOrWhiteSpace($application.version) -or [string]::IsNullOrWhiteSpace($application.consumer))) {
            throw "A version pin requires a version and named consumer: $($application.id)"
        }
        if ($application.id -eq 'Oven-sh.Bun' -and ($application.versionPolicy -ne 'pinned' -or $application.consumer -cne 'omp-agent-setup/.bun-version')) {
            throw 'Bun must name the omp-agent-setup/.bun-version consumer pin'
        }
        if ($application.id -eq '@fission-ai/openspec' -and ($application.versionPolicy -ne 'pinned' -or $application.consumer -cne 'omp-agent-setup reusable workflow OpenSpec pin')) {
            throw 'OpenSpec must name the omp-agent-setup reusable workflow consumer pin'
        }
        foreach ($role in $application.roles) {
            if (-not $roles.Add($role)) { throw "Duplicate application role: $role" }
            if (-not $requiredRoles.ContainsKey($role) -or $requiredRoles[$role] -ine $application.id) {
                throw "Application role has an unexpected owner: $role"
            }
        }
        if ($application.ContainsKey('root') -and $application.root -notin @('LOCALAPPDATA', 'APPDATA')) {
            throw "Application destination requires an approved user environment root: $($application.id)"
        }
        foreach ($field in @('directory', 'executable')) {
            if ($application.ContainsKey($field)) { Assert-WorkstationRelativePath -Path $application[$field] }
        }
        if ($application.ContainsKey('payload')) { Assert-WorkstationRelativePath -Path $application.payload -AllowDot }
        if ($application.ContainsKey('ownedFiles')) {
            foreach ($path in $application.ownedFiles.Keys) { Assert-WorkstationRelativePath -Path $path }
        }
        if ($application.ContainsKey('preserveFiles')) {
            foreach ($path in $application.preserveFiles) { Assert-WorkstationRelativePath -Path $path }
        }
        if ($application.kind -eq 'font') {
            foreach ($path in $application.fonts.Keys) { Assert-WorkstationRelativePath -Path $path -FileNameOnly }
        }
        if ($application.id -eq 'OpenJS.NodeJS.LTS') { $nodeIndex = $applicationIndex }
        if ($application.kind -eq 'npm') {
            if ($application.nodeId -ine 'OpenJS.NodeJS.LTS' -or $nodeIndex -lt 0 -or $nodeIndex -ge $applicationIndex) {
                throw 'The declared Node runtime must precede its npm closure'
            }
            Assert-WorkstationRelativePath -Path $application.source
            $source = Join-Path $PSScriptRoot $application.source
            $manifest = Read-WorkstationJsonFile -Path (Join-Path $source 'package.json')
            $lock = Read-WorkstationJsonFile -Path (Join-Path $source 'package-lock.json')
            $id = $application.id
            if ($manifest.dependencies[$id] -cne $application.version -or
                $lock.packages[''].dependencies[$id] -cne $application.version -or
                $lock.packages["node_modules/$id"].version -cne $application.version) {
                throw 'OpenSpec manifest and integrity lock must match its declared consumer version'
            }
        }
    }
    foreach ($role in $requiredRoles.Keys) {
        if (-not $roles.Contains($role)) { throw "Missing required application role: $role" }
    }

    $languageIndex = -1
    $inputIndex = -1
    for ($index = 0; $index -lt $Data.settings.Count; $index++) {
        $setting = $Data.settings[$index]
        if ($setting.kind -in @('registry', 'taskbarVisibility')) {
            Assert-WorkstationUserRegistryPath -Path $setting.path
            if ($setting.path -match '(?i)\\(CloudStore|Taskband|FileExts|UrlAssociations|DefaultAssociations|RegisteredApplications)(\\|$)' -or
                $setting.path -match '(?i)\\(UserChoice|FileAssociations|URLAssociations)(\\|$)' -or
                $setting.path -match '(?i)^HKCU:\\Software\\Classes\\(\.[^\\]+|[^\\]+\\shell\\open\\command)(\\|$)') {
                throw "Prohibited registry surface: $($setting.path)"
            }
            if ($setting.kind -eq 'registry' -and $setting.path -match '(?i)\\(StuckRects\d*|MMStuckRects\d*)(\\|$)') {
                throw 'Taskbar visibility requires the typed taskbarVisibility setting'
            }
            if ($setting.kind -eq 'taskbarVisibility' -and
                ($setting.path -ine 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3' -or
                 $setting.valueName -cne 'Settings' -or $setting.index -ne 8 -or $setting.value -ne 2)) {
                throw 'Taskbar visibility may change only StuckRects3 Settings byte 8 to 2'
            }
        }
        if ($setting.kind -eq 'language') {
            if ($languageIndex -ge 0 -or ($setting.languages -join ',') -cne 'en-GB,de-DE,de-AT' -or $setting.ui -cne 'en-GB') {
                throw 'Language configuration must preserve English UI and German/Austrian input languages'
            }
            $languageIndex = $index
        }
        if ($setting.kind -eq 'inputMethods') {
            if ($inputIndex -ge 0 -or $setting.ordered.Count -ne 2 -or
                ($setting.ordered -join ',') -cne '0407:00000407,0407:b0000407' -or $setting.default -cne '0407:00000407' -or
                $setting.neoRegistryPath -ine 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\b0000407') {
                throw 'Input methods require German QWERTZ first/default and native Neo second with its read-only driver prerequisite'
            }
            $inputIndex = $index
        }
    }
    if ($inputIndex -ge 0 -and ($languageIndex -lt 0 -or $languageIndex -gt $inputIndex)) {
        throw 'The language setting must precede the input-method setting'
    }
}

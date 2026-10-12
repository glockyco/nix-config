BeforeAll {
    . (Join-Path $PSScriptRoot '../bootstrap.ps1')
}

Describe 'Minimal Windows PowerShell prerequisite bootstrap' {
    It 'resolves the registered user MSIX instead of assuming a WinGet portable directory' {
        Mock Test-Path { $LiteralPath -eq 'C:\Program Files\WindowsApps\Microsoft.PowerShell\pwsh.exe' }
        Mock Get-AppxPackage { [pscustomobject]@{ InstallLocation = 'C:\Program Files\WindowsApps\Microsoft.PowerShell' } }
        Resolve-PrerequisiteExecutable -Id 'Microsoft.PowerShell' -RelativePaths @() -Executable 'pwsh.exe' | Should -Be 'C:\Program Files\WindowsApps\Microsoft.PowerShell\pwsh.exe'
        Should -Invoke Get-AppxPackage -Times 1 -Exactly -ParameterFilter { $Name -eq 'Microsoft.PowerShell' }
    }

    It 'installs only user prerequisites, selects MSIX rather than privileged MSI, and hands over without apply' {
        $originalPath = $env:PATH
        try {
            $script:resolved = @{}
            Mock Test-PrerequisiteElevated { $false }
            Mock Resolve-PrerequisiteExecutable {
                if (-not $script:resolved.ContainsKey($Id)) { $script:resolved[$Id] = $true; return $null }
                return "C:\user\$Id\$Executable"
            }
            Mock Invoke-PrerequisiteProcess {}
            Mock Invoke-PrerequisiteHandoff {}
            $null = Invoke-PrerequisiteBootstrap
            Should -Invoke Invoke-PrerequisiteProcess -Times 3 -Exactly -ParameterFilter {
                $Arguments[0] -eq 'install' -and $Arguments -contains '--skip-dependencies' -and
                $Arguments[$Arguments.IndexOf('--scope') + 1] -eq 'user' -and
                $Arguments[$Arguments.IndexOf('--id') + 1] -in @('Microsoft.PowerShell', 'Git.Git', 'twpayne.chezmoi')
            }
            Should -Invoke Invoke-PrerequisiteProcess -Times 1 -Exactly -ParameterFilter {
                $Arguments[$Arguments.IndexOf('--id') + 1] -eq 'Microsoft.PowerShell' -and
                $Arguments[$Arguments.IndexOf('--installer-type') + 1] -eq 'msix'
            }
            Should -Invoke Invoke-PrerequisiteHandoff -Times 1 -Exactly -ParameterFilter { $Command -eq 'C:\user\Microsoft.PowerShell\pwsh.exe' }
        } finally { $env:PATH = $originalPath }
    }

    It 'refuses an Administrator bootstrap before installs or handoff' {
        Mock Test-PrerequisiteElevated { $true }
        Mock Invoke-PrerequisiteProcess {}
        Mock Invoke-PrerequisiteHandoff {}
        { Invoke-PrerequisiteBootstrap } | Should -Throw '*standard user*'
        Should -Invoke Invoke-PrerequisiteProcess -Times 0 -Exactly
        Should -Invoke Invoke-PrerequisiteHandoff -Times 0 -Exactly
    }
}

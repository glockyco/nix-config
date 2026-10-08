# Chezmoi can inherit PowerShell 7's module directories before spawning the
# in-box Windows PowerShell interpreter. Rebuild its process-only search path
# from Desktop defaults and persisted user/machine paths, not the parent's Core
# runtime. Native module cmdlets must load from this interpreter's own modules.
if ($PSVersionTable.PSEdition -eq 'Desktop') {
  $windowsModulePaths = @(
    [IO.Path]::Combine($PSHOME, 'Modules'),
    [IO.Path]::Combine([Environment]::GetFolderPath('MyDocuments'), 'WindowsPowerShell', 'Modules'),
    [IO.Path]::Combine([Environment]::GetEnvironmentVariable('ProgramFiles', 'Process'), 'WindowsPowerShell', 'Modules')
  )
  foreach ($scope in @('User', 'Machine')) {
    $configuredModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', $scope)
    if (-not [string]::IsNullOrWhiteSpace($configuredModulePath)) { $windowsModulePaths += $configuredModulePath }
  }
  $env:PSModulePath = [string]::Join(';', [string[]]$windowsModulePaths)
}

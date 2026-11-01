function Get-WorkstationPluginUpdatePaths {
    return @{
        Source = Join-Path $PSScriptRoot 'personal-plugin-upgrade.ps1'
        Runner = Join-Path $env:LOCALAPPDATA 'WindowsConfiguration\personal-plugin-upgrade.ps1'
    }
}

function Get-WorkstationPluginUpdateTaskXml {
    $paths = Get-WorkstationPluginUpdatePaths
    $userId = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $command = [Security.SecurityElement]::Escape((Join-Path $PSHOME 'pwsh.exe'))
    $arguments = [Security.SecurityElement]::Escape('-NoProfile -NonInteractive -WindowStyle Hidden -File "' + $paths.Runner + '"')
    return @"
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <LogonTrigger><Enabled>true</Enabled><UserId>$userId</UserId></LogonTrigger>
    <TimeTrigger><Repetition><Interval>PT1H</Interval><StopAtDurationEnd>false</StopAtDurationEnd></Repetition><StartBoundary>2020-01-01T00:00:00</StartBoundary><Enabled>true</Enabled></TimeTrigger>
  </Triggers>
  <Principals><Principal id="User"><UserId>$userId</UserId><LogonType>InteractiveToken</LogonType><RunLevel>LeastPrivilege</RunLevel></Principal></Principals>
  <Settings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><StartWhenAvailable>true</StartWhenAvailable><ExecutionTimeLimit>PT15M</ExecutionTimeLimit><Enabled>true</Enabled></Settings>
  <Actions Context="User"><Exec><Command>$command</Command><Arguments>$arguments</Arguments></Exec></Actions>
</Task>
"@
}

function Test-WorkstationPluginUpdateTask {
    param([hashtable] $Resource)
    $paths = Get-WorkstationPluginUpdatePaths
    if (-not (Test-Path -LiteralPath $paths.Runner -PathType Leaf)) { return $false }
    if ((Get-FileHash -LiteralPath $paths.Source).Hash -cne (Get-FileHash -LiteralPath $paths.Runner).Hash) { return $false }
    $task = Get-ScheduledTask -TaskName $Resource.taskName -TaskPath '\' -ErrorAction SilentlyContinue
    if ($null -eq $task) { return $false }
    [xml]$actual = Export-ScheduledTask -TaskName $Resource.taskName -TaskPath '\' -ErrorAction Stop
    [xml]$desired = Get-WorkstationPluginUpdateTaskXml
    $namespace = [Xml.XmlNamespaceManager]::new($desired.NameTable)
    $namespace.AddNamespace('t', $desired.DocumentElement.NamespaceURI)
    # Export adds scheduler defaults. Compare every declared leaf and reject extra triggers/actions.
    foreach ($node in $desired.SelectNodes('//t:*[not(*)]', $namespace)) {
        $parts = [Collections.Generic.List[string]]::new()
        $current = $node
        while ($current -is [Xml.XmlElement]) {
            $parts.Insert(0, 't:' + $current.LocalName)
            $current = $current.ParentNode
        }
        $matchedNodes = $actual.SelectNodes('/' + ($parts -join '/'), $namespace)
        if ($matchedNodes.Count -ne 1 -or $matchedNodes[0].InnerText -cne $node.InnerText) { return $false }
    }
    return $actual.Task.Triggers.ChildNodes.Count -eq 2 -and $actual.Task.Actions.ChildNodes.Count -eq 1 -and
        $actual.Task.Principals.ChildNodes.Count -eq 1 -and $actual.Task.Actions.Context -ceq 'User'
}

function Set-WorkstationPluginUpdateTask {
    param([hashtable] $Resource)
    if (Test-WorkstationPluginUpdateTask -Resource $Resource) { return }
    $paths = Get-WorkstationPluginUpdatePaths
    $null = New-Item -ItemType Directory -Path (Split-Path $paths.Runner -Parent) -Force
    Copy-Item -LiteralPath $paths.Source -Destination $paths.Runner -Force -ErrorAction Stop
    Register-ScheduledTask -TaskName $Resource.taskName -TaskPath '\' -Xml (Get-WorkstationPluginUpdateTaskXml) -Force -ErrorAction Stop | Out-Null
}

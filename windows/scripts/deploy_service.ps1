<#
.Synopsis
  Installs a Windows service on a remote computer.
  Sets the credentials for the service to run under.
  Grants SeServiceLogonRight to the account.
  Sets service recovery options.
.Parameter computerName
  Defines the name of the computer which will host the service.
  Default is the local computer on which the script is run.
.Parameter name
  Defines the name (in Services Manager) of the service.
  Mandatory parameter
.Parameter display
  Defines the display name (in Services Manager) of the service.
  Default is to match the service name
.Parameter description
  Defines the description (in Services Manager) of the service.
  Default is to match the service display name
.Parameter path
  Defines the path to the service executable (including command arguments).
.Parameter startup
  Defines the startup type of the service.
  Can be set to: Automatic, Manual or Disabled
.Parameter username
  Defines the username under which the service should run.
  Use the form: domain\username.
.Parameter password
  Defines the password for the user under which the service should run.
.Parameter recoverReset
  Defines the number of days to wait before resetting the fail count (0 = never).
.Parameter recoverDelay
  Defines the number of milliseconds to wait before taking recovery action.
.Parameter recoverActions
  Defines the recovery actions to take when the service stops unexpectedly.
.Parameter recoverCommand
  Defines a command to run when the service stops unexpectedly.
  eg: "echo 'crash count: %1%'>> C:\Services\TeamCityConfigMonitor\crash.log"
.Parameter removeOnly
  If set, removes the service specified by $name on host specified by $computerName. No service will be installed and configured.
.Example
  Usage:
  .\ServiceDeploy.ps1 -computerName hostname.domain.com -name TeamCityConfigMonitor -display "TeamCity Config Monitor" -path "C:\Services\TeamCityConfigMonitor\TeamCityConfigMonitor.exe" -username "domain\username" -password "password"
#>
param(
    [string] $computerName = ("{0}.{1}" -f $env:COMPUTERNAME.ToLower(), $env:USERDNSDOMAIN.ToLower()),

    [Parameter(Mandatory = $true)]
    [string] $name,

    [string] $display = $name,

    [string] $description = $display,

    [Parameter(Mandatory = $true)]
    [string] $path,

    [ValidateSet("Automatic", "Manual", "Disabled")]
    [string] $startup = "Automatic",

    [string] $username = $null,
    [string] $password = $null,

    [int] $recoverReset = 0,
    [int] $recoverDelay = 60000,
    [string] $recoverActions = "restart/$recoverDelay/restart/$recoverDelay/restart/$recoverDelay",
    [string] $recoverCommand = $null,

    [switch] $removeOnly = $false
)

Invoke-Command -ComputerName $computerName -Script {
    param(
        [string] $computerName,
        [string] $name,
        [string] $display,
        [string] $description,
        [string] $path,
        [string] $startup,
        [string] $username,
        [string] $password,
        [int] $recoverReset,
        [int] $recoverDelay,
        [string] $recoverActions,
        [string] $recoverCommand,
        [bool] $removeOnly
    )
    $returnCodes = @{ 0 = "Success"; 1 = "Not Supported"; 2 = "Access Denied"; 3 = "Dependent Services Running"; 4 = "Invalid Service Control"; 5 = "Service Cannot Accept Control"; 6 = "Service Not Active"; 7 = "Service Request Timeout"; 8 = "Unknown Failure"; 9 = "Path Not Found"; 10 = "Service Already Running"; 11 = "Service Database Locked"; 12 = "Service Dependency Deleted"; 13 = "Service Dependency Failure"; 14 = "Service Disabled"; 15 = "Service Logon Failure"; 16 = "Service Marked For Deletion"; 17 = "Service No Thread"; 18 = "Status Circular Dependency"; 19 = "Status Duplicate Name"; 20 = "Status Invalid Name"; 21 = "Status Invalid Parameter"; 22 = "Status Invalid Service Account"; 23 = "Status Service Exists"; 24 = "Service Already Paused" }

    # Remove service if it exists.
    if ((Get-Service $name -ErrorAction SilentlyContinue)) {
        $service = Get-WmiObject -Class Win32_Service -Filter "Name='$name'"
        # Stop Service -------------------------------------------
        if ($service -and $service.AcceptStop) {
            Write-Host ("Stopping service {0} ({1}) on host: {2}." -f $service.Name, $service.DisplayName, $computerName)
            $stopStatus = $service.StopService()
            switch ([int]$stopStatus.ReturnValue) {
                0 { Write-Host ("Service {0}, on host: {1}, stopped." -f $name, $computerName) }
                10 { Write-Host ("Service {0}, on host: {1}, was not running." -f $name, $computerName) }
                default { Write-Host ("Error, service {0}, on host: {1}, not stopped. Return code: {2}, ({3})." -f $name, $computerName, $($stopStatus.ReturnValue), $returnCodes[([int]$stopStatus.ReturnValue)]) }
            }
        }
        else {
            Write-Host ("Service: {0} ({1}) on host: {2} will not accept a stop command." -f $service.Name, $service.DisplayName, $computerName)
        }
        # Delete Service -------------------------------------------
        Write-Host ("Deleting service {0} ({1}) on host: {2}." -f $service.Name, $service.DisplayName, $computerName)
        $deleteStatus = $service.Delete()
        switch ([int]$deleteStatus.ReturnValue) {
            0 { Write-Host ("Success, service: {0}, on host: {1}, deleted." -f $name, $computerName) }
            default { Write-Host ("Error, service {0}, on host: {1}, not deleted. Return code: {2}, ({3})." -f $name, $computerName, $($deleteStatus.ReturnValue), $returnCodes[([int]$deleteStatus.ReturnValue)]) }
        }
    }
    else {
        Write-Host ("Service: {0}, not found on host: {1}." -f $name, $computerName)
    }

    if (!$removeOnly) {
        # Install service.
        New-Service -name $name -binaryPathName $path -displayName $display -description $description -startupType $startup

        if ((Get-Service $name -ErrorAction SilentlyContinue)) {
            Write-Host ("Service: {0}, on host: {1} created." -f $name, $computerName)
            $service = Get-WmiObject -Class Win32_Service -Filter "Name='$name'"

            # Set the credentials under which the service should run if a username and password were provided.
            if (($username) -and ($password)) {
                if (!$username.Contains("\")) {
                    $username = ".\{0}" -f $username
                }

                # Grant logon as a service right
                $tempPath = [System.IO.Path]::GetTempPath()
                $import = Join-Path -Path $tempPath -ChildPath "import.inf"
                if (Test-Path $import) { Remove-Item -Path $import -Force }
                $export = Join-Path -Path $tempPath -ChildPath "export.inf"
                if (Test-Path $export) { Remove-Item -Path $export -Force }
                $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
                if (Test-Path $secedt) { Remove-Item -Path $secedt -Force }
                try {
                    Write-Host ("Granting SeServiceLogonRight to user account: {0} on host: {1}." -f $username, $computerName)
                    $sid = ((New-Object System.Security.Principal.NTAccount($username)).Translate([System.Security.Principal.SecurityIdentifier])).Value
                    secedit /export /cfg $export
                    $sids = (Select-String $export -Pattern "SeServiceLogonRight").Line
                    foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsAService security template", "[Privilege Rights]", "SeServiceLogonRight = *$sids,*$sid")) {
                        Add-Content $import $line
                    }
                    secedit /import /db $secedt /cfg $import
                    secedit /configure /db $secedt
                    gpupdate /force
                    Remove-Item -Path $import -Force
                    Remove-Item -Path $export -Force
                    Remove-Item -Path $secedt -Force
                }
                catch {
                    Write-Host ("Failed to grant SeServiceLogonRight to user account: {0} on host: {1}." -f $username, $computerName)
                    $error[0]
                }

                # Configure service to use provided credentials
                Write-Host ("Changing service {0} ({1}) to run under user account: {2}." -f $service.Name, $service.DisplayName, $username)
                $changeStatus = $service.Change($null, $null, $null, $null, $null, $null, $username, $password, $null, $null, $null)
                switch ([int]$changeStatus.ReturnValue) {
                    0 { Write-Host ("Success, service: {0}, on host: {1}, set to run under user account: {2}." -f $name, $computerName, $username) }
                    default { Write-Host ("Error: Failed to set service: {0}, on host: {1}, to run under user account: {2}. Return code: {3}, ({4}." -f $name, $computerName, $username, $($changeStatus.ReturnValue), $returnCodes[([int]$changeStatus.ReturnValue)]) }
                }
            }
            else {
                Write-Host ("Service: {0}, is set to run under user account: {1}." -f $name, $service.StartName)
            }

            # Attempt service start if startup type is not disabled or manual.
            if ($startup -eq "Automatic") {
                Write-Host ("Starting service {0} ({1}) on host: {2}." -f $service.Name, $service.DisplayName, $computerName)
                $startStatus = $service.StartService()
                switch ([int]$startStatus.ReturnValue) {
                    0 {
                        Write-Host ("Service {0}, on host: {1}, started." -f $name, $computerName)
                        Write-Host ("Waiting a few seconds to see if it stays running." -f $name, $computerName)
                        Start-Sleep -s 1
                        $service = Get-WmiObject -Class Win32_Service -Filter "Name='$name'"
                        switch ($service.State) {
                            # Handle service starts then stops.
                            "Stopped" {
                                Write-Host ("Service {0}, on host: {1}, started but then stopped. Check the service logs for more information." -f $name, $computerName)
                            }
                            default {
                                Write-Host ("Service {0}, on host: {1} entered state: {2}." -f $name, $computerName, $service.State)
                                # Service is running. Set service recovery options.
                                # http://gallery.technet.microsoft.com/scriptcenter/Set-Windows-Service-via-899f89f3
                                $scStatus = sc.exe \\$computerName failure $service.Name reset= $recoverReset command= `"$recoverCommand`" actions= $recoverActions
                                if ($scStatus -eq "[SC] ChangeServiceConfig2 SUCCESS") {
                                    Write-Host ("Service {0}, on host: {1}, recovery options set (reset (days): {2}, delay (ms): {3}, actions: {4}, command: `"{5}`")." -f $name, $computerName, $recoverReset, $recoverDelay, $recoverActions, $recoverCommand)
                                }
                                else {
                                    Write-Host ("Error, service {0}, on host: {1}, recovery options not set (reset (days): {2}, delay (ms): {3}, actions: {4}, command: `"{5}`")." -f $name, $computerName, $recoverReset, $recoverDelay, $recoverActions, $recoverCommand)
                                    $scStatus
                                }
                            }
                        }
                    }
                    10 { Write-Host ("Service {0}, on host: {1}, already running." -f $name, $computerName) }
                    15 { Write-Host ("Error, service {0}, on host: {1}, not started. Return code: {2}, ({3}). Username: {4}, Password: {5}." -f $name, $computerName, $($startStatus.ReturnValue), $returnCodes[([int]$startStatus.ReturnValue)], $username, $password) }
                    default { Write-Host ("Error, service {0}, on host: {1}, not started. Return code: {2}, ({3})." -f $name, $computerName, $($startStatus.ReturnValue), $returnCodes[([int]$startStatus.ReturnValue)]) }
                }
            }
        }
        else {
            Write-Host ("Error, failed to create service: {0}, on host: {1}." -f $name, $computerName)
        }
    }
} -ArgumentList $computerName, $name, $display, $description, $path, $startup, $username, $password, $recoverReset, $recoverDelay, $recoverActions, $recoverCommand, $removeOnly
#Requires -Module:"xPSDesiredStateConfiguration"

# begin {
#     $currentExecutionPolicy = Get-ExecutionPolicy -Scope:LocalMachine
#     Set-ExecutionPolicy -ExecutionPolicy:Unrestricted -Scope:LocalMachine -Force:$true -Verbose:$true

#     $service = Get-Service -Name:@("WinRM")
#     if ($service.Status -ne "Running") {
#         Start-Service -Name:@("WinRM") -Verbose:$true
#     }
# }

# process {

# }

# end {
#     Set-ExecutionPolicy -ExecutionPolicy:$currentExecutionPolicy -Scope:LocalMachine -Force:$true -Verbose:$true
# }

function Invoke-DscConfiguration {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigurationName
    )

    $outputPath = Join-Path -Path:@("$env:PUBLIC") -ChildPath:"DSCOutput\5"

    if (-not (Test-Path -Path:@("$outputPath") -PathType:Container)) {
        New-Item -Path:@("$outputPath") -ItemType:Directory -Verbose:$true
    }

    $outputPath = Join-Path -Path:@("$env:PUBLIC") -ChildPath:"DSCOutput\5\$ConfigurationName"

    if (-not (Test-Path -Path:@("$outputPath") -PathType:Container)) {
        New-Item -Path:@("$outputPath") -ItemType:Directory -Verbose:$true
    }

    & $ConfigurationName -OutputPath:$outputPath -Verbose:$true

    $testResult = Test-DscConfiguration -Path:$outputPath
    if (-not($testResult.InDesiredState)) {
        Start-DscConfiguration -Path:$outputPath -Force:$true -Wait:$true -Verbose:$true
    }
}

Configuration xWindowsOptionalFeature_Enable_Virtualization_Config_5 {

    $params = @(
        @{
            Name = "Containers-DisposableClientVM"
        },
        @{
            Name = "Containers"
        },
        @{
            Name = "HostGuardian"
        },
        @{
            Name = "HypervisorPlatform"
        },
        @{
            Name = "Microsoft-Hyper-V-All"
        },
        @{
            Name = "Microsoft-Hyper-V-Hypervisor"
        },
        @{
            Name = "Microsoft-Hyper-V-Management-Clients"
        },
        @{
            Name = "Microsoft-Hyper-V-Management-PowerShell"
        },
        @{
            Name = "Microsoft-Hyper-V-Services"
        },
        @{
            Name = "Microsoft-Hyper-V-Tools-All"
        },
        @{
            Name = "Microsoft-Hyper-V"
        },
        @{
            Name = "Microsoft-Windows-Subsystem-Linux"
        },
        @{
            Name = "VirtualMachinePlatform"
        }
    )

    Import-DscResource -ModuleName:"xPSDesiredStateConfiguration" -ModuleVersion:"9.1.0"

    Node "localhost" {
        $params | ForEach-Object {
            xWindowsOptionalFeature "Enable_Virtualization_$($_.Name)" {
                Name                 = $_.Name
                Ensure               = "Present"
                RemoveFilesOnDisable = $true
            }
        }
    }
}

# Invoke-DscConfiguration -ConfigurationName:"xWindowsOptionalFeature_Enable_Virtualization_Config_5"

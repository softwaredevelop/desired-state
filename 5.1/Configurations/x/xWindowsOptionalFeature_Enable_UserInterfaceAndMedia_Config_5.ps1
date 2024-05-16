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

Configuration xWindowsOptionalFeature_Enable_UserInterfaceAndMedia_Config_5 {

    $params = @(
        @{
            Name = "MediaPlayback"
        },
        @{
            Name = "Microsoft-RemoteDesktopConnection"
        },
        @{
            Name = "Microsoft-SnippingTool"
        },
        @{
            Name = "WindowsMediaPlayer"
        }
    )

    Import-DscResource -ModuleName:"xPSDesiredStateConfiguration" -ModuleVersion:"9.1.0"

    Node "localhost" {
        $params | ForEach-Object {
            xWindowsOptionalFeature "Enable_UserInterfaceAndMedia_$($_.Name)" {
                Name                 = $_.Name
                Ensure               = "Present"
                RemoveFilesOnDisable = $true
            }
        }
    }
}

# Invoke-DscConfiguration -ConfigurationName:"xWindowsOptionalFeature_Enable_UserInterfaceAndMedia_Config_5"

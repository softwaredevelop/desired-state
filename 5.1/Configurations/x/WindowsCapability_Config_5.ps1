#Requires -Module:"ComputerManagementDsc"

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

Configuration WindowsCapability_Config_5 {

    $params = @(
        @{
            Name = "App.StepsRecorder~~~~0.0.1.0"
        },
        @{
            Name = "App.Support.QuickAssist~~~~0.0.1.0"
        },
        @{
            Name = "DirectX.Configuration.Database~~~~0.0.1.0"
        },
        @{
            Name = "Language.Basic~~~de-DE~0.0.1.0"
        },
        @{
            Name = "Language.Basic~~~en-US~0.0.1.0"
        },
        @{
            Name = "Language.Basic~~~hu-HU~0.0.1.0"
        },
        @{
            Name = "Language.Handwriting~~~de-DE~0.0.1.0"
        },
        @{
            Name = "Language.Handwriting~~~en-US~0.0.1.0"
        },
        @{
            Name = "Language.OCR~~~de-DE~0.0.1.0"
        },
        @{
            Name = "Language.OCR~~~en-US~0.0.1.0"
        },
        @{
            Name = "Language.OCR~~~hu-HU~0.0.1.0"
        },
        @{
            Name = "Language.Speech~~~de-DE~0.0.1.0"
        },
        @{
            Name = "Language.Speech~~~en-US~0.0.1.0"
        },
        @{
            Name = "Language.TextToSpeech~~~de-DE~0.0.1.0"
        },
        @{
            Name = "Language.TextToSpeech~~~en-US~0.0.1.0"
        },
        @{
            Name = "Language.TextToSpeech~~~hu-HU~0.0.1.0"
        },
        @{
            Name = "MathRecognizer~~~~0.0.1.0"
        },
        @{
            Name = "Media.WindowsMediaPlayer~~~~0.0.12.0"
        },
        @{
            Name = "Microsoft.Onecore.StorageManagement~~~~0.0.1.0"
        },
        @{
            Name = "Microsoft.Windows.MSPaint~~~~0.0.1.0"
        },
        @{
            Name = "Microsoft.Windows.Notepad~~~~0.0.1.0"
        },
        @{
            Name = "Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0"
        },
        @{
            Name = "Microsoft.Windows.StorageManagement~~~~0.0.1.0"
        },
        @{
            Name = "Microsoft.Windows.WordPad~~~~0.0.1.0"
        },
        @{
            Name = "Msix.PackagingTool.Driver~~~~0.0.1.0"
        },
        @{
            Name = "OneCoreUAP.OneSync~~~~0.0.1.0"
        },
        @{
            Name = "OpenSSH.Client~~~~0.0.1.0"
        },
        @{
            Name = "Print.Management.Console~~~~0.0.1.0"
        },
        @{
            Name = "RasCMAK.Client~~~~0.0.1.0"
        },
        @{
            Name = "SNMP.Client~~~~0.0.1.0"
        },
        @{
            Name = "Tools.DeveloperMode.Core~~~~0.0.1.0"
        },
        @{
            Name = "Tools.Graphics.DirectX~~~~0.0.1.0"
        },
        @{
            Name = "Windows.Client.ShellComponents~~~~0.0.1.0"
        }
    )

    $allCapabilities = Get-WindowsCapability -Online | Select-Object -ExpandProperty Name
    $paramNames = $params | ForEach-Object { $_.Name }
    $missingCapabilities = $allCapabilities | Where-Object { $_ -notin $paramNames }
    $absentParams = $missingCapabilities | ForEach-Object { @{ Name = $_ } }

    Import-DscResource -ModuleName:"ComputerManagementDsc"

    Node "localhost" {
        $params | ForEach-Object {
            WindowsCapability "Capability_Add_$($_.Name)" {
                Name   = $_.Name
                Ensure = "Present"
            }
        }

        $absentParams | ForEach-Object {
            WindowsCapability "Capability_Remove_$($_.Name)" {
                Name   = $_.Name
                Ensure = "Absent"
            }
        }
    }
}

# Invoke-DscConfiguration -ConfigurationName:"WindowsCapability_Config_5"

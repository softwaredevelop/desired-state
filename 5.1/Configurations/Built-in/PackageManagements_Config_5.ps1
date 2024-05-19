#Requires -Module:"PackageManagement"

# begin {
#     $currentExecutionPolicy = Get-ExecutionPolicy -Scope:Process
#     Set-ExecutionPolicy -ExecutionPolicy:Unrestricted -Scope:Process -Force:$true -Verbose:$true

#     $service = Get-Service -Name:@("WinRM")
#     if ($service.Status -ne "Running") {
#         Start-Service -Name:@("WinRM") -Verbose:$true
#     }
# }

# process {

# }

# end {
#     Set-ExecutionPolicy -ExecutionPolicy:$currentExecutionPolicy -Scope:Process -Force:$true -Verbose:$true
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

Configuration PackageManagements_Config_5 {

    $params = @(
        @{
            Ensure       = "Present"
            Name         = "ComputerManagementDsc"
            ProviderName = "PowerShellGet"
        },
        @{
            Ensure       = "Present"
            Name         = "PSScriptAnalyzer"
            ProviderName = "PowerShellGet"
        },
        @{
            Ensure       = "Present"
            Name         = "xPSDesiredStateConfiguration"
            ProviderName = "PowerShellGet"
        }
    )

    Import-DscResource -ModuleName:"PackageManagement" -ModuleVersion:"1.0.0.1"

    Node "localhost"
    {
        $params | ForEach-Object {
            PackageManagement "Package_$($_.Name)" {
                Ensure       = $_.Ensure
                Name         = $_.Name
                ProviderName = $_.ProviderName
            }
        }
    }
}

# Invoke-DscConfiguration -ConfigurationName:"PackageManagements_Config_5"

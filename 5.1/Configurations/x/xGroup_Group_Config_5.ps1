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

Configuration xGroup_Group_Config_5 {

    Import-DscResource -ModuleName:"xPSDesiredStateConfiguration" -ModuleVersion:"9.1.0"

    Node "localhost" {
        xGroup "S-1-5-32-545" {
            Ensure           = "Present"
            GroupName        = Split-Path -Path:(New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-545")).Translate([System.Security.Principal.NTAccount]) -Leaf
            MembersToInclude = @("user", "trader")
        }
    }
}

# Invoke-DscConfiguration -ConfigurationName:"xGroup_Group_Config_5"

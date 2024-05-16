#Requires -Module:"PSDesiredStateConfiguration"

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

    $outputPath = Join-Path -Path:@("$env:TEMP") -ChildPath:"DSCOutput\5"

    if (-not (Test-Path -Path:@("$outputPath") -PathType:Container)) {
        New-Item -Path:@("$outputPath") -ItemType:Directory -Verbose:$true
    }

    $outputPath = Join-Path -Path:@("$env:TEMP") -ChildPath:"DSCOutput\5\$ConfigurationName"

    if (-not (Test-Path -Path:@("$outputPath") -PathType:Container)) {
        New-Item -Path:@("$outputPath") -ItemType:Directory -Verbose:$true
    }

    & $ConfigurationName -OutputPath:$outputPath -Verbose:$true

    $testResult = Test-DscConfiguration -Path:$outputPath
    if (-not($testResult.InDesiredState)) {
        Start-DscConfiguration -Path:$outputPath -Force:$true -Wait:$true -Verbose:$true
    }
}

Configuration Create_Files_Config_5
{
    Import-DscResource -ModuleName:"PSDesiredStateConfiguration"

    Node "localhost" {
        File "DockerDirectory" {
            DestinationPath = Join-Path -Path:@("$env:ProgramFiles") -ChildPath:"Docker\Docker"
            Ensure          = "Present"
            Type            = "Directory"
            # add to PATH %ProgramFiles%\Docker\Docker;
            # $dockerPath     = Join-Path -Path:@("$env:ProgramFiles") -ChildPath:"Docker\Docker\docker.exe"
            # $daggerPath     = Join-Path -Path:@("$env:ProgramFiles") -ChildPath:"RedHat\Podman\podman.exe"
            # New-Item -ItemType:SymbolicLink -Path:$dockerPath -Target:$daggerPath
        }
    }
}

# Invoke-DscConfiguration -ConfigurationName:"Create_Files_Config_5"

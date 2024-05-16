#Requires -Module:"Cobalt"

# begin {
#     $currentExecutionPolicy = Get-ExecutionPolicy -Scope:Process
#     Set-ExecutionPolicy -ExecutionPolicy:Unrestricted -Scope:Process -Force:$true -Verbose:$true
# }

# process {

# }

# end {
#     Set-ExecutionPolicy -ExecutionPolicy:$currentExecutionPolicy -Scope:Process -Force:$true -Verbose:$true
# }

begin {
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        Write-Error "winget.exe is not installed. Please install it before running this script."
        exit 1
    }

    <#
    .SYNOPSIS
        Tests if a Windows Package is installed using WinGet.

    .DESCRIPTION
        This function tests if a Windows Package is installed using WinGet. It takes an ID parameter and checks if a package with that ID exists.

    .PARAMETER ID
        Specifies the ID of the package to be checked.

    .EXAMPLE
        TestWinGetPackages -ID "example-package"
        This example checks if a package with the ID "example-package" is installed using WinGet.

    .OUTPUTS
        System.Boolean
        Returns $true if the package is installed, $false otherwise.

    #>
    function Test-WinGetPackages {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$ID
        )
        if ($null -ne (Get-WinGetPackage -ID:$ID)) {
            return $true
        } else {
            return $false
        }
    }

    Import-PackageProvider -Name:@("WinGet") -Force:$true -ForceBootstrap:$true -Verbose:$true

    # $packageNames = Get-Content .\wingetexport.json | ConvertFrom-Json
    # $packageNames.Sources.Packages | ForEach-Object { $_.PackageIdentifier } | Sort-Object
    $packageNames = @(
        "Microsoft.PowerShell"
    )
}

process {
    $packageNames | ForEach-Object {
        if (Test-WinGetPackages -ID:$_) {
            Get-WinGetPackage -ID:$_ -Verbose:$true
        } else {
            Install-WinGetPackage -ID:$_ -Verbose:$true
        }
    }
}

end {
    Update-WinGetPackage -All:$true -Verbose:$true
}

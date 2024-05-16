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
        Tests if a Windows Package Manager (WinGet) package is installed.

    .DESCRIPTION
        The Test-WinGetPackage function checks if a package with the specified ID is installed using the Windows Package Manager (WinGet).
        It returns a boolean value indicating whether the package is installed or not.

    .PARAMETER ID
        Specifies the ID of the package to be checked.

    .OUTPUTS
        System.Boolean
        Returns $true if the package is installed, otherwise returns $false.

    .EXAMPLE
        Test-WinGetPackage -ID "example-package"
        This example checks if the package with the ID "example-package" is installed using WinGet.

    #>
    function Test-WinGetPackage {
        [CmdletBinding()]
        [OutputType([System.Boolean])]
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
        if (Test-WinGetPackage -ID:$_) {
            Get-WinGetPackage -ID:$_ -Verbose:$true
        } else {
            Install-WinGetPackage -ID:$_ -Verbose:$true
        }
    }
}

end {
    Update-WinGetPackage -All:$true -Verbose:$true
}

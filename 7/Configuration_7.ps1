begin {
    # $currentExecutionPolicy = Get-ExecutionPolicy -Scope:Process
    # Set-ExecutionPolicy -ExecutionPolicy:Unrestricted -Scope:Process -Force:$true -Verbose:$true

    <#
    .SYNOPSIS
    Sets a package source as trusted.

    .DESCRIPTION
    The Set-PackageSourceTrusted function sets a package source as trusted. It checks if the package source already exists and if it is trusted. If the package source does not exist, it registers the package source and sets it as trusted. If the package source exists but is not trusted, it updates the package source and sets it as trusted.

    .PARAMETER Name
    The name of the package source.

    .PARAMETER Location
    The location of the package source.

    .PARAMETER ProviderName
    The provider name of the package source. Valid values are "Bootstrap", "NuGet", "PowerShellGet", and "WinGet".

    .EXAMPLE
    Set-PackageSourceTrusted -Name "MyPackageSource" -Location "https://example.com/packages" -ProviderName "NuGet"
    Registers the package source "MyPackageSource" with the location "https://example.com/packages" and sets it as trusted.

    .NOTES
    This function requires administrative privileges to register or update package sources.
    #>
    function Set-PackageSourceTrusted {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,

            [string]$Location,

            [ValidateSet("Bootstrap", "NuGet", "PowerShellGet", "WinGet")]
            [string]$ProviderName
        )

        $packageSource = Get-PackageSource | Where-Object { $_.Name -eq $Name }

        if ($null -eq $packageSource) {
            if ($PSCmdlet.ShouldProcess($Name, "Register-PackageSource")) {
                Register-PackageSource -Name:$Name -Location:$Location -Force:$true -ForceBootstrap:$true -ProviderName:$ProviderName -Trusted:$true -Verbose:$true
            }
        } elseif ($packageSource.IsTrusted -eq $false) {
            if ($PSCmdlet.ShouldProcess($Name, "Set-PackageSource")) {
                Set-PackageSource -Name:$Name -ForceBootstrap:$true -Location:$Location -ProviderName:$ProviderName -Trusted:$true -Verbose:$true
            }
        }
    }

    <#
    .SYNOPSIS
        Installs a PowerShell module if it is not already in the specified module path.

    .DESCRIPTION
        The Install-ModuleIfNotInPath function checks if a PowerShell module is already installed in the specified module path.
        If the module is not found in the path, it installs the module using the Install-Module cmdlet.

    .PARAMETER ModuleName
        Specifies the name of the module to be installed.

    .PARAMETER Repository
        Specifies the repository from which to install the module. Default value is "PSGallery".

    .PARAMETER MaximumVersion
        Specifies the maximum version of the module to be installed.

    .PARAMETER PSGetPath
        Specifies the module paths to check for the presence of the module. Default paths are:
        - $PSHOME\Modules
        - $PSHOME\Scripts
        - $HOME\Documents\PowerShell\Modules
        - $HOME\Documents\PowerShell\Scripts
        - $env:ProgramFiles\PowerShell\Modules
        - $env:ProgramFiles\PowerShell\Scripts

    .EXAMPLE
        Install-ModuleIfNotInPath -ModuleName "MyModule" -Repository "PSGallery" -MaximumVersion "2.0"

        This example installs the module named "MyModule" from the "PSGallery" repository with a maximum version of "2.0".
    #>
    function Install-ModuleIfNotInPath {
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$ModuleName,

            [string[]]$Repository = @("PSGallery"),

            [string]$MaximumVersion,

            [string[]]$PSGetPath = @(
                "$PSHOME\Modules",
                "$PSHOME\Scripts",
                "$HOME\Documents\PowerShell\Modules",
                "$HOME\Documents\PowerShell\Scripts",
                "$env:ProgramFiles\PowerShell\Modules",
                "$env:ProgramFiles\PowerShell\Scripts"
            )
        )

        $module = Get-Module -ListAvailable:$true | Where-Object { $_.Name -eq $ModuleName }

        if ($module) {
            $moduleInPath = $PSGetPath | Where-Object { $module.ModuleBase -like "$_*" }

            if (-not $moduleInPath) {
                if ($MaximumVersion) {
                    Install-Module -Name:$ModuleName -MaximumVersion:$MaximumVersion -Repository:$Repository -AllowClobber:$true -Force:$true -Verbose:$true
                } else {
                    Install-Module -Name:$ModuleName -Repository:$Repository -AllowClobber:$true -Force:$true -Verbose:$true
                }
            }
        } else {
            if ($MaximumVersion) {
                Install-Module -Name:$ModuleName -MaximumVersion:$MaximumVersion -Repository:$Repository -AllowClobber:$true -Force:$true -Verbose:$true
            } else {
                Install-Module -Name:$ModuleName -Repository:$Repository -AllowClobber:$true -Force:$true -Verbose:$true
            }
        }
    }

    Set-PackageSourceTrusted -Name:"PSGallery" -Location:"https://www.powershellgallery.com/api/v2" -ProviderName:"PowerShellGet"

    Install-ModuleIfNotInPath -ModuleName:@("PSDesiredStateConfiguration") -MaximumVersion:"2.99"
    # Install-ModuleIfNotInPath -ModuleName:@("PSDscResources")
}

process {
    $scriptDir = Join-Path -Path:$PSScriptRoot -ChildPath:"Scripts"

    $xDir = Join-Path -Path:$scriptDir -ChildPath:"x"
    $xDirScript = Get-ChildItem -Path:$xDir -Filter:"*Script_7.ps1" | Sort-Object -Property:Name
    $xDirScript | ForEach-Object {
        & $_.FullName
    }
}

end {
    # Set-ExecutionPolicy -ExecutionPolicy:$currentExecutionPolicy -Scope:Process -Force:$true -Verbose:$true
}

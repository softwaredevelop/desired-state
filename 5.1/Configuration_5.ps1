begin {
    # $currentExecutionPolicy = Get-ExecutionPolicy -Scope:Process
    # Set-ExecutionPolicy -ExecutionPolicy:Unrestricted -Scope:Process -Force:$true -Verbose:$true

    # $service = Get-Service -Name:@("WinRM")
    # if ($service.Status -ne "Running") {
    #     Start-Service -Name:@("WinRM") -Verbose:$true
    # }

    <#
    .SYNOPSIS
    Installs a package provider if it doesn't already exist.

    .DESCRIPTION
    The Install-PackageProviderIfNotExist function checks if a specified package provider is already installed. If the provider is not found, it installs the package provider using the Install-PackageProvider cmdlet.

    .PARAMETER ProviderName
    The name of the package provider to install.

    .EXAMPLE
    Install-PackageProviderIfNotExist -ProviderName "NuGet"

    This example checks if the "NuGet" package provider is installed. If not, it installs the provider using the Install-PackageProvider cmdlet.

    #>
    function Install-PackageProviderIfNotExist {
        param(
            [Parameter(Mandatory = $true)]
            [string]$ProviderName
        )

        $provider = Get-PackageProvider -ListAvailable:$true | Where-Object { $_.Name -eq $ProviderName }
        if ($null -eq $provider) {
            Install-PackageProvider -Name:@($ProviderName) -Force:$true -ForceBootstrap:$true -Verbose:$true
        }
    }

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
    Sets a PowerShell repository as trusted.

    .DESCRIPTION
    The Set-PSRepositoryTrusted function is used to register or update a PowerShell repository as trusted. It checks if the repository already exists and if its installation policy is set to "Trusted". If the repository does not exist, it registers the repository with the specified name, source location, and package management provider, and sets the installation policy to "Trusted". If the repository exists but its installation policy is not "Trusted", it updates the repository with the specified name, source location, and package management provider, and sets the installation policy to "Trusted".

    .PARAMETER Name
    The name of the PowerShell repository to register or update.

    .PARAMETER SourceLocation
    The source location of the PowerShell repository.

    .PARAMETER PackageManagementProvider
    The package management provider for the PowerShell repository.

    .EXAMPLE
    Set-PSRepositoryTrusted -Name "MyRepo" -SourceLocation "https://myrepo.com" -PackageManagementProvider "NuGet"

    This example registers a PowerShell repository named "MyRepo" with the source location "https://myrepo.com" and the package management provider "NuGet". If the repository already exists, it updates the repository and sets the installation policy to "Trusted".

    .NOTES
    - This function requires administrative privileges to register or update a PowerShell repository.
    - The function uses the ShouldProcess method to support the -WhatIf and -Confirm parameters for confirming the action before executing it.
    #>
    function Set-PSRepositoryTrusted {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,

            [Parameter(Mandatory = $true)]
            [string]$SourceLocation,

            [Parameter(Mandatory = $true)]
            [string]$PackageManagementProvider
        )

        $psRepository = Get-PSRepository | Where-Object { $_.Name -eq $Name }

        if ($null -eq $psRepository) {
            if ($PSCmdlet.ShouldProcess($Name, "Register-PSRepository")) {
                Register-PSRepository -Name:$Name -SourceLocation:$SourceLocation -InstallationPolicy:Trusted -PackageManagementProvider:$PackageManagementProvider -Verbose:$true
            }
        } elseif ($psRepository.InstallationPolicy -ne "Trusted") {
            if ($PSCmdlet.ShouldProcess($Name, "Set-PSRepository")) {
                Set-PSRepository -Name:$Name -SourceLocation:$SourceLocation -InstallationPolicy:Trusted -PackageManagementProvider:$PackageManagementProvider -Verbose:$true
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
        Specifies the repository from which to install the module. Default is PSGallery.

    .PARAMETER MaximumVersion
        Specifies the maximum version of the module to be installed.

    .PARAMETER PSGetPath
        Specifies the module paths to check for the presence of the module. Default paths include:
        - $PSHOME\Modules
        - $PSHOME\Scripts
        - $HOME\Documents\WindowsPowerShell\Modules
        - $HOME\Documents\WindowsPowerShell\Scripts
        - $env:ProgramFiles\WindowsPowerShell\Modules
        - $env:ProgramFiles\WindowsPowerShell\Scripts

    .EXAMPLE
        Install-ModuleIfNotInPath -ModuleName "MyModule" -Repository "PSGallery" -MaximumVersion "2.0"

        This example installs the module named "MyModule" from the PSGallery repository if it is not already installed in the default module paths.
        The maximum version of the module to be installed is specified as "2.0".

    .NOTES
        This function requires the Install-Module cmdlet to be available in the PowerShell session.
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
                "$HOME\Documents\WindowsPowerShell\Modules",
                "$HOME\Documents\WindowsPowerShell\Scripts",
                "$env:ProgramFiles\WindowsPowerShell\Modules",
                "$env:ProgramFiles\WindowsPowerShell\Scripts"
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

    <#
    .SYNOPSIS
        Invokes DSC (Desired State Configuration) files and applies the configuration.

    .DESCRIPTION
        The Invoke-DscFile function takes an array of DSC files and applies the configuration specified in each file.
        It executes the configuration script, checks if the system is in the desired state, and if not, applies the configuration.

    .PARAMETER DscFiles
        Specifies an array of DSC files to be invoked and applied.

    .EXAMPLE
        $files = Get-ChildItem -Path "C:\DSC\Configurations" -Filter "*.ps1"
        Invoke-DscFile -DscFiles $files
        This example retrieves all the DSC configuration files in the "C:\DSC\Configurations" directory and applies them using the Invoke-DscFile function.

    #>
    function Invoke-DscFile {
        param(
            [Parameter(Mandatory = $true)]
            [System.Object[]]$DscFiles
        )

        $DscFiles | ForEach-Object {
            . $_.FullName
            $configurationName = $_.BaseName

            $local:outputPath = Join-Path -Path:@("$env:PUBLIC") -ChildPath:"DSCOutput\5\$configurationName"
            & $configurationName -OutputPath:$local:outputPath -Verbose:$true

            $local:testResult = Test-DscConfiguration -Path:$local:outputPath
            if (-not($local:testResult.InDesiredState)) {
                Start-DscConfiguration -Path:$local:outputPath -Force:$true -Wait:$true -Verbose:$true
            }
        }
    }

    function UpdateModuleHelp5 {
        $moduleNames = @(
            "Cobalt",
            "ConfigDefender",
            "ConfigDefenderPerformance",
            "DeliveryOptimization",
            "HostNetworkingService",
            "PersistentMemory",
            "Pester",
            "PSDiagnostics",
            "PSDscResources",
            "PSReadline",
            "StorageBusCache",
            "WinGet",
            "ComputerManagementDsc",
            "gsudoModule",
            "xPSDesiredStateConfiguration"
        )
        $modules = Get-Module -ListAvailable:$true | Where-Object { $_.Name -notin $moduleNames } | ForEach-Object { $_.Name }
        Update-Help -Module:$modules -UICulture:en-US -Force:$true -Verbose:$true
    }

    Install-PackageProviderIfNotExist -ProviderName:"NuGet"
    Set-PackageSourceTrusted -Name:"nuget.org" -Location:"https://www.nuget.org/api/v2" -ProviderName:"NuGet"

    Set-PackageSourceTrusted -Name:"PSGallery" -Location:"https://www.powershellgallery.com/api/v2" -ProviderName:"PowerShellGet"

    Install-PackageProviderIfNotExist -ProviderName:"WinGet"
    Set-PackageSourceTrusted -Name:"winget" -Location:"https://cdn.winget.microsoft.com/cache" -ProviderName:"WinGet"
}

process {
    $dscDirectoryBuiltIn = Join-Path -Path:@($PSScriptRoot) -ChildPath:"Configurations\Built-in"
    $dscBuiltInFiles = Get-ChildItem -Path:@($dscDirectoryBuiltIn) -Filter:"*Config_5.ps1"

    $dscBuiltInFileH = $dscBuiltInFiles | Where-Object { $_.Name -eq "HelloWorld_Config_5.ps1" }
    Invoke-DscFile -DscFiles:$dscBuiltInFileH

    # $dscBuiltInFileP = $dscBuiltInFiles | Where-Object { $_.Name -eq "PackageManagements_Config_5.ps1" }
    # Invoke-DscFile -DscFiles:$dscBuiltInFileP

    $dscBuiltInFileDesc = $dscBuiltInFiles | Where-Object { $_.Name -ne "HelloWorld_Config_5.ps1" } | Sort-Object
    Invoke-DscFile -DscFiles:$dscBuiltInFileDesc

    $dscDirectoryx = Join-Path -Path:@($PSScriptRoot) -ChildPath:"Configurations\x"
    $dscxFiles = Get-ChildItem -Path:@($dscDirectoryx) -Filter:"*Config_5.ps1"

    $dscxFileWn = $dscxFiles | Where-Object { $_.Name -notlike "WindowsCapability*" -and $_.Name -notlike "xWindowsOptionalFeature*" } | Sort-Object -Property:Name -Descending:$true
    Invoke-DscFile -DscFiles:$dscxFileWn

    $dscFilesW = $dscxFiles | Where-Object { $_.Name -like "WindowsCapability*" -or $_.Name -like "xWindowsOptionalFeature*" } | Sort-Object -Property:Name -Descending:$true
    Invoke-DscFile -DscFiles:$dscFilesW

    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Scripts\Install_WinGet_Package_5.ps1"
    & $scriptPath

    UpdateModuleHelp5
}

end {
    # Set-ExecutionPolicy -ExecutionPolicy:$currentExecutionPolicy -Scope:Process -Force:$true -Verbose:$true
}

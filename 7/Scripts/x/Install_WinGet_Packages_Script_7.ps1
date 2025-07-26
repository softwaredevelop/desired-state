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
        Tests if a package is installed using Windows Package Manager (WinGet).

    .DESCRIPTION
        The Test-WinGetPackage function checks if a package with the specified ID is installed using WinGet.
        It returns a boolean value indicating whether the package is installed or not.

    .PARAMETER ID
        Specifies the ID of the package to be checked.

    .OUTPUTS
        System.Boolean
        Returns $true if the package is installed, otherwise returns $false.

    .EXAMPLE
        Test-WinGetPackage -ID "example-package"
        This example checks if the package with ID "example-package" is installed using WinGet.

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
    # $packageNames.Sources.Packages | ForEach-Object { $_.PackageIdentifier } | Sort-Object -Unique
    $packageNames = @(
        "7zip.7zip",
        "Anaconda.Miniconda3",
        "DuckDuckGo.DesktopBrowser",
        "EditorConfig-Checker.EditorConfig-Checker",
        "gerardog.gsudo",
        "Git.Git",
        "GoLang.Go",
        "Google.Chrome.EXE",
        "hadolint.hadolint",
        "Insecure.Nmap",
        "Microsoft.AppInstaller",
        "Microsoft.DotNet.Runtime.8",
        "Microsoft.DotNet.SDK.8",
        "Microsoft.Edge",
        "Microsoft.NuGet",
        "Microsoft.OneDrive",
        "Microsoft.PowerShell",
        "Microsoft.UI.Xaml.2.7",
        "Microsoft.UI.Xaml.2.8",
        "Microsoft.VCLibs.Desktop.14",
        "Microsoft.VCRedist.2008.x86",
        "Microsoft.VCRedist.2013.x86",
        "Microsoft.VisualStudioCode",
        "Microsoft.WindowsTerminal",
        "mvdan.shfmt",
        "Opera.Opera",
        "Pulumi.Pulumi",
        "Python.Launcher",
        "rhysd.actionlint",
        "TradingView.TradingViewDesktop"
        # git config --global core.autocrlf false
        # git config --global credential.helper cache
        # git config --global init.defaultBranch main
        # git config --global user.email
        # git config --global user.name
        # add to PATH C:\Program Files (x86)\Nmap;
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
    # Get-WinGetPackage | ForEach-Object { $_.ID } | Sort-Object -Unique
}

end {
    Update-WinGetPackage -All:$true -Verbose:$true
}

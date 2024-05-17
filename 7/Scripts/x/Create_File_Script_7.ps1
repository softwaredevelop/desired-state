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
    <#
    .SYNOPSIS
        Retrieves information about a file at the specified destination path.

    .DESCRIPTION
        The Get-File function retrieves information about a file at the specified destination path. It uses the Get-Item cmdlet to get the file object and returns it.

    .PARAMETER DestinationPath
        Specifies the path to the file.

    .EXAMPLE
        Get-File -DestinationPath "C:\Path\To\File.txt"
        Retrieves information about the file located at "C:\Path\To\File.txt".

    #>
    function Get-File {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$DestinationPath
        )
        Get-Item -Path:$DestinationPath -Force:$true -Verbose:$true
    }

    <#
    .SYNOPSIS
        Creates a file or directory at the specified destination path.

    .DESCRIPTION
        The Set-File function creates a file or directory at the specified destination path. It supports creating both files and directories, and allows specifying the contents of the file if creating a file.

    .PARAMETER DestinationPath
        Specifies the path where the file or directory should be created.

    .PARAMETER Type
        Specifies the type of the item to be created. Valid values are "Directory" and "File".

    .PARAMETER Contents
        Specifies the contents of the file to be created. This parameter is only applicable when creating a file.

    .EXAMPLE
        Set-File -DestinationPath "C:\Temp\NewFile.txt" -Type "File" -Contents "This is a new file."

        This example creates a new file named "NewFile.txt" at the specified destination path "C:\Temp\" with the contents "This is a new file."

    .EXAMPLE
        Set-File -DestinationPath "C:\Temp\NewFolder" -Type "Directory"

        This example creates a new directory named "NewFolder" at the specified destination path "C:\Temp\".

    #>
    function Set-File {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param (
            [Parameter(Mandatory = $true)]
            [string]$DestinationPath,

            [ValidateSet("Directory", "File")]
            [string]$Type,

            [string]$Contents
        )

        if ($PSCmdlet.ShouldProcess($DestinationPath, "Creating $Type")) {
            if ($null -ne $Contents) {
                New-Item -Path:$DestinationPath -Type:$Type -Force:$true -Value:$Contents -Verbose:$true
            } elseif ($Type -eq "Directory") {
                New-Item -Path:$DestinationPath -Type:$Type -Force:$true -Verbose:$true
            }
        }
    }

    <#
    .SYNOPSIS
        Tests if a file exists at the specified destination path.

    .DESCRIPTION
        The Test-File function checks if a file exists at the specified destination path. It returns a boolean value indicating whether the file exists or not.

    .PARAMETER DestinationPath
        Specifies the path of the file to be tested.

    .OUTPUTS
        System.Boolean
        Returns $true if the file exists, and $false if it does not.

    .EXAMPLE
        Test-File -DestinationPath "C:\Path\to\File.txt"
        Returns $true if the file "File.txt" exists at the specified path, and $false otherwise.
    #>
    function Test-File {
        [CmdletBinding()]
        [OutputType([System.Boolean])]
        param (
            [Parameter(Mandatory = $true)]
            [string]$DestinationPath
        )

        if (Test-Path -Path:$DestinationPath) {
            return $true
        } else {
            return $false
        }
    }

    $files = @(
        @{
            DestinationPath = Join-Path -Path:@("$env:TEMP") -ChildPath:"t"
            Type            = "Directory"
        },
        @{
            DestinationPath = Join-Path -Path:@("$env:TEMP") -ChildPath:"t.txt"
            Type            = "File"
        },
        @{
            Contents        = "Hello, tt!"
            DestinationPath = Join-Path -Path:@("$env:TEMP") -ChildPath:"tt" -AdditionalChildPath:@("tt.txt")
            Type            = "File"
        },
        @{
            Contents        = "{`"credStore`": `"desktop`"}"
            DestinationPath = Join-Path -Path:@("$env:USERPROFILE") -ChildPath:".docker" -AdditionalChildPath:@("config.json")
            Type            = "File"
        },
        @{
            DestinationPath = Join-Path -Path:@("$env:USERPROFILE") -ChildPath:"@vscode" -AdditionalChildPath:@(".projectmanager")
            Type            = "Directory"
        },
        @{
            DestinationPath = Join-Path -Path:@("$env:USERPROFILE") -ChildPath:"@vscode" -AdditionalChildPath:@(".projectmanager", "projects.json")
            Type            = "File"
        }
    )
}

process {
    $files | ForEach-Object {
        if ($null -ne $_.Contents) {
            if (Test-File -DestinationPath:$_.DestinationPath) {
                Get-File -DestinationPath:$_.DestinationPath
            } else {
                Set-File -DestinationPath:$_.DestinationPath -Type:$_.Type -Contents:$_.Contents
            }
        } else {
            if (Test-File -DestinationPath:$_.DestinationPath) {
                Get-File -DestinationPath:$_.DestinationPath
            } else {
                Set-File -DestinationPath:$_.DestinationPath -Type:$_.Type
            }
        }
    }
}

# end {
#     $files | ForEach-Object {
#         Remove-Item -Path:$_.DestinationPath -Force -Verbose:$true
#     }
# }

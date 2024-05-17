#Requires -Module:"Cobalt"

<#
.SYNOPSIS
    Sets up passwordless SSH key authentication for a remote host.

.DESCRIPTION
    The Set-SSHKeyPasswordless function generates an SSH key pair and sets up passwordless SSH key authentication for a remote host. It creates the necessary directories, sets the appropriate permissions, and generates the SSH key pair based on the specified key type.

.PARAMETER RemoteHost
    The remote host for which passwordless SSH key authentication is being set up. The default value is "github.com".

.PARAMETER RemoteUser
    The remote user for which passwordless SSH key authentication is being set up. The default value is "githubuser".

.PARAMETER Keytype
    The type of SSH key to generate. Valid values are "ed25519", "rsa", and "ecdsa". The default value is "ed25519".

.PARAMETER Comment
    The comment to include in the SSH key. The default value is "${RemoteUser}@${RemoteHost}".

.EXAMPLE
    Set-SSHKeyPasswordless -RemoteHost "example.com" -RemoteUser "user" -Keytype "rsa" -Comment "RSA Key for example.com"
    Generates an RSA SSH key pair with the comment "RSA Key for example.com" for the remote host "example.com" and the remote user "user".

.NOTES
    This function requires the "ssh-keygen.exe" and "winget.exe" executables to be installed. It also requires the "gerardog.gsudo" and "Insecure.Nmap" packages to be installed using WinGet.

.LINK
    https://github.com/username/repo
    Additional documentation and examples can be found on the GitHub repository.
#>
function Set-SSHKeyPasswordless {
    param (
        [string]$RemoteHost = "github.com",
        [string]$RemoteUser = "githubuser",
        [ValidateSet("ed25519", "rsa", "ecdsa")]
        [string]$Keytype = "ed25519",
        [string]$Comment = "${RemoteUser}@${RemoteHost}"
    )

    begin {
        function New-DirectoryIfNotExist {
            [CmdletBinding(SupportsShouldProcess = $true)]
            param(
                [Parameter(Mandatory = $true)]
                [string]$Path,
                [Parameter(Mandatory = $true)]
                [string]$ChildPath
            )

            $DestinationPath = Join-Path -Path:@($Path) -ChildPath:$ChildPath

            if ($PSCmdlet.ShouldProcess($DestinationPath, "Creating directory")) {
                if (-not (Test-Path -Path:$DestinationPath)) {
                    New-Item -Path:@($DestinationPath) -Type:Directory -Force -Verbose:$true
                } else {
                    Get-Item -Path:@($DestinationPath) -Force:$true -Verbose:$true
                }
            }
        }

        function Set-Permission {
            [CmdletBinding(SupportsShouldProcess = $true)]
            param (
                [Parameter(Mandatory = $true)]
                [string]$Item,

                [Parameter(Mandatory = $true)]
                [string]$IdentityReference,

                [Parameter(Mandatory = $true)]
                [string]$FileSystemRights,

                [Parameter(Mandatory = $true)]
                [string]$AccessControlType
            )

            if ($PSCmdlet.ShouldProcess($Item, "Modifying permissions")) {
                $acl = Get-Acl -Path:$Item
                $acl.Access | ForEach-Object {
                    if ($PSCmdlet.ShouldProcess($_, "Removing access rule")) {
                        $acl.RemoveAccessRule($_)
                    }
                }
                $accessRule = [System.Security.AccessControl.FileSystemAccessRule]::new($IdentityReference, $FileSystemRights, $AccessControlType)
                if ($PSCmdlet.ShouldProcess($accessRule, "Adding access rule")) {
                    $acl.AddAccessRule($accessRule)
                }
                Set-Acl -Path:$Item -AclObject:$acl
            }
        }

        # Function to check if the current user is an administrator in Windows
        function Test-IsAdminWindows {
            ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        }

        # Check if required executables are installed
        @("ssh-keygen.exe", "winget.exe") | ForEach-Object {
            if (-not (Get-Command $_ -ErrorAction SilentlyContinue)) {
                Write-Error "$_ is not installed. Please install it before running this script."
                exit 1
            }
        }

        # Check if required packages are installed using WinGet
        @("gerardog.gsudo", "Insecure.Nmap") | ForEach-Object {
            if ($null -eq (Get-WinGetPackage -ID:$_)) {
                Install-WinGetPackage -ID:$_
            }
        }
    }

    process {
        # Create or retrieve the .ssh directory
        $sshDirPath = New-DirectoryIfNotExist -Path:$env:USERPROFILE -ChildPath:".ssh"

        # Set permissions for the .ssh directory
        $identityReference = $env:USERNAME
        Set-Permission -Item:$sshDirPath.FullName -IdentityReference:$identityReference -FileSystemRights:"FullControl" -AccessControlType:"Allow"

        # Generate SSH key pair based on the specified key type
        $rsaKeylength = 4096
        $ecdsaKeylength = 521
        $kdf = Get-Random -Minimum 16 -Maximum 27

        if ($Keytype -eq "rsa") {
            $id = "id_rsa_"
            $keyOptions = @("-a${kdf}", "-t${Keytype}", "-b${rsaKeylength}", "-C${Comment}")
        } elseif ($Keytype -eq "ecdsa") {
            $id = "id_ecdsa_"
            $keyOptions = @("-a${kdf}", "-t${Keytype}", "-b${ecdsaKeylength}", "-C${Comment}")
        } elseif ($Keytype -eq "ed25519") {
            $id = "id_ed25519_"
            $keyOptions = @("-a${kdf}", "-t${Keytype}", "-C${Comment}")
        }

        $sshPass = ""

        $hostname = $env:COMPUTERNAME
        $chars = @(
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
            'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
            'u', 'v', 'w', 'x', 'y', 'z'
        )
        $hash = -join (1..6 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
        $keyName = "${RemoteHost}.${RemoteUser}" + "_" + $hostname + "_" + $hash

        # Generate SSH key pair and set permissions
        if (
            (
                $PSVersionTable.PSEdition -eq "Desktop" -or
                $PSVersionTable.PSEdition -eq "Core"
            ) -and
            (
                [System.Environment]::OSVersion.Platform -eq "Win32NT" -or
                $PSVersionTable.Platform -eq "Win32NT"
            )
        ) {
            if ("" -eq $sshPass -and $null -ne $keyName) {
                $keyfile = Join-Path -Path:$sshDirPath.FullName -ChildPath:"${Id}${keyName}.key"
                ssh-keygen $keyOptions -f $keyfile -N $sshPass

                # Set $keyfile permissions to 600
                if ($false -eq (Test-IsAdminWindows)) {
                    Invoke-Gsudo {
                        function Set-Permission {
                            [CmdletBinding(SupportsShouldProcess = $true)]
                            param (
                                [Parameter(Mandatory = $true)]
                                [string]$Item,

                                [Parameter(Mandatory = $true)]
                                [string]$IdentityReference,

                                [Parameter(Mandatory = $true)]
                                [string]$FileSystemRights,

                                [Parameter(Mandatory = $true)]
                                [string]$AccessControlType
                            )

                            if ($PSCmdlet.ShouldProcess($Item, "Modifying permissions")) {
                                $acl = Get-Acl -Path:$Item
                                $acl.Access | ForEach-Object {
                                    if ($PSCmdlet.ShouldProcess($_, "Removing access rule")) {
                                        $acl.RemoveAccessRule($_)
                                    }
                                }
                                $accessRule = [System.Security.AccessControl.FileSystemAccessRule]::new($IdentityReference, $FileSystemRights, $AccessControlType)
                                if ($PSCmdlet.ShouldProcess($accessRule, "Adding access rule")) {
                                    $acl.AddAccessRule($accessRule)
                                }
                                Set-Acl -Path:$Item -AclObject:$acl
                            }
                        }

                        Set-Permission -Item:$using:keyfile -IdentityReference:$using:identityReference -FileSystemRights:"Read, Write" -AccessControlType:"Allow"
                    }
                } else {
                    Set-Permission -Item:$keyfile -IdentityReference:$identityReference -FileSystemRights:"Read, Write" -AccessControlType:"Allow"
                }

                # Set "$keyfile.pub" permissions to 644
                if ((Test-IsAdminWindows) -eq $false) {
                    Invoke-Gsudo {
                        function Set-Permission {
                            [CmdletBinding(SupportsShouldProcess = $true)]
                            param (
                                [Parameter(Mandatory = $true)]
                                [string]$Item,

                                [Parameter(Mandatory = $true)]
                                [string]$IdentityReference,

                                [Parameter(Mandatory = $true)]
                                [string]$FileSystemRights,

                                [Parameter(Mandatory = $true)]
                                [string]$AccessControlType
                            )

                            if ($PSCmdlet.ShouldProcess($Item, "Modifying permissions")) {
                                $acl = Get-Acl -Path:$Item
                                $acl.Access | ForEach-Object {
                                    if ($PSCmdlet.ShouldProcess($_, "Removing access rule")) {
                                        $acl.RemoveAccessRule($_)
                                    }
                                }
                                $accessRule = [System.Security.AccessControl.FileSystemAccessRule]::new($IdentityReference, $FileSystemRights, $AccessControlType)
                                if ($PSCmdlet.ShouldProcess($accessRule, "Adding access rule")) {
                                    $acl.AddAccessRule($accessRule)
                                }
                                Set-Acl -Path:$Item -AclObject:$acl
                            }
                        }

                        Set-Permission -Item:"$using:keyfile.pub" -IdentityReference:$using:identityReference -FileSystemRights:"Read, Write" -AccessControlType:"Allow"

                        # Add a new access rule for the 'Users' group with Read permissions
                        $acl = Get-Acl -Path:"$using:keyfile.pub"
                        $sid = [System.Security.Principal.SecurityIdentifier]::new("S-1-1-0")
                        $accessRule = [System.Security.AccessControl.FileSystemAccessRule]::new($sid, "Read", "Allow")
                        $acl.AddAccessRule($accessRule)
                        Set-Acl -Path:"$using:keyfile.pub" -AclObject:$acl
                    }
                } else {
                    Set-Permission -Item:"${keyfile}.pub" -IdentityReference:$identityReference -FileSystemRights:"Read, Write" -AccessControlType:"Allow"

                    # Add a new access rule for the 'Users' group with Read permissions
                    $acl = Get-Acl -Path:"${keyfile}.pub"
                    $sid = [System.Security.Principal.SecurityIdentifier]::new("S-1-1-0")
                    $accessRule = [System.Security.AccessControl.FileSystemAccessRule]::new($sid, "Read", "Allow")
                    $acl.AddAccessRule($accessRule)
                    Set-Acl -Path:"${keyfile}.pub" -AclObject:$acl
                }
            }
        }

        # Configure SSH client to use the generated key for authentication
        $configFile = Join-Path -Path:$sshDirPath.FullName -ChildPath:"config"

        if (Test-Path -Path:$keyfile) {
            $configContent = @"
Host                 ${RemoteHost}.${RemoteUser}
Hostname             ${RemoteHost}
IdentitiesOnly       yes
IdentityFile         ${keyfile}
User                 git
ProxyCommand         ncat --proxy 127.0.0.1:9050 --proxy-type socks5 %h %p

"@

            Add-Content -Path:$configFile -Value:$configContent

            Remove-Variable -Name:sshPass -ErrorAction:SilentlyContinue
            Remove-Variable -Name:sshDirPath -ErrorAction:SilentlyContinue
        }

    }

    end {

    }
}

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

begin {

}

process {
    $daggerPath = Join-Path -Path:$env:USERPROFILE -ChildPath:"dagger" -AdditionalChildPath:@("dagger.exe")

    if (-not (Test-Path -Path:$daggerPath)) {
        Invoke-WebRequest -UseBasicParsing:$true -Uri:"https://dl.dagger.io/dagger/install.ps1" | Invoke-Expression
    } else {
        try {
            $d = & $daggerPath version
        } catch {

        }
        $d
    }
    # add to PATH %USERPROFILE%\dagger;
}

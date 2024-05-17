$goModuleDirs = Get-ChildItem -Recurse -Filter "go.mod" | Select-Object -Unique DirectoryName
foreach ($dir in $goModuleDirs) {
    Push-Location $dir.DirectoryName
    go mod tidy
    go get -u ./...
    Pop-Location
}

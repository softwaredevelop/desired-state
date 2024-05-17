begin {

}

process {
    $yesterday = (Get-Date).AddDays(-1)
    $goBuildCachePath = Join-Path -Path:$HOME -ChildPath:".cache" -AdditionalChildPath:"go-build"
    Get-ChildItem -Path:$goBuildCachePath -Recurse:$true -File:$true | Where-Object { $_.LastWriteTime -lt $yesterday } | Remove-Item -Force:$true
    go clean -cache -modcache
    if ($IsLinux) {
        $env:GOCACHE = Join-Path -Path:"/tmp" -ChildPath:"gocache"
    } elseif ($IsWindows) {
        Join-Path -Path:$env:TEMP -ChildPath:"gocache"
    }

    $goModuleDirs = Get-ChildItem -Recurse:$true -Filter:"go.mod"
    $goModuleDirs | ForEach-Object {
        Push-Location -Path:$_.DirectoryName
        go mod tidy
        go get -u ./...
        Pop-Location
    }
}

end {

}

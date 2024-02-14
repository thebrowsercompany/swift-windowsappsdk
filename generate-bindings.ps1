function Restore-Nuget {
    param(
        [string]$PackagesDir
    )
    $NugetDownloadPath = Join-Path $env:TEMP "nuget.exe"
    if (-not (Test-Path $NugetDownloadPath)) {
        Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $NugetDownloadPath
    }

    & $NugetDownloadPath restore .\packages.config -PackagesDirectory $PackagesDir
}

function Get-NugetPackageVersion() {
    param(
        [string]$Package
    )

    return (Select-XML -Path $PSScriptRoot\packages.config -XPath "/packages/package[@id='$Package']/@version").Node.Value
}

function Get-WinMDInputs() {
    param(
        [string]$Package
    )
    $Version = Get-NugetPackageVersion -Package $Package
    return Get-ChildItem -Path $PackagesDir\$Package.$Version\ -Filter *.winmd -Recurse
    $Winmds = $winmds | ForEach-Object {
        $RspParams += "-input $($_.FullName)`n"
    }
}

function Invoke-SwiftWinRT() {
    param(
        [string]$PackagesDir
    )

    $SwiftWinRTVersion = Get-NugetPackageVersion -Package "TheBrowserCompany.SwiftWinRT"

    # write generated bindings to a temp directory since swiftwinrt will generate all dependencies and the CWinRT
    $OutputLocation = Join-Path $PSScriptRoot ".generated"
    if (Test-Path $OutputLocation) {
        Remove-Item -Path $OutputLocation -Recurse -Force
    }

    $RspParams = "-output $OutputLocation`n"

    # read projections.json and for each "include" write to -include param. for each "exclude" write to -exclude param
    $Projections = Get-Content -Path $PSScriptRoot\projections.json | ConvertFrom-Json
    $ProjectName = $Projections.Project
    if (-not $ProjectName) {
        Write-Host "projections.json must contain a 'Project' property" -ForegroundColor Red
        return
    }

    $Package = $Projections.Package
    if (-not $ProjectName) {
        Write-Host "projections.json must contain a 'Package' property" -ForegroundColor Red
        return
    }

    $Projections.Include | ForEach-Object {
        $RspParams += "-include $_`n"
    }
    $Projections.Exclude | ForEach-Object {
        $RspParams += "-exclude $_`n"
    }

    Get-WinMDInputs -Package $Package | ForEach-Object {
        $RspParams += "-input $($_.FullName)`n"
    }

    $Projections.Dependencies | ForEach-Object {
        Get-WinMDInputs -Package $_ | ForEach-Object {
            $RspParams += "-reference $($_.FullName)`n"
        }
    }

    # write rsp params to file
    $RspFile = Join-Path $PSScriptRoot "swift-winrt.rsp"
    $RspParams | Out-File -FilePath $RspFile
    & $PackagesDir\TheBrowserCompany.SwiftWinRT.$SwiftWinRTVersion\bin\swiftwinrt.exe "@$RspFile"

    # check error code
    if ($LASTEXITCODE -ne 0) {
        Write-Host "swiftwinrt failed with error code $LASTEXITCODE" -ForegroundColor Red
        return
    }
    # swift-winrt will generate all dependencies so copy all "UWP" sources from the generated dir to the UWP project
    $ProjectDir = Join-Path $PSScriptRoot "Sources\$ProjectName"
    Remove-Item -Path $ProjectDir -Recurse -Force
    Copy-Item -Path $OutputLocation\Sources\$ProjectName -Filter *.swift -Destination $ProjectDir -Recurse -Force
}

function Copy-PackageAssets {
    param(
        [string]$PackagesDir
    )

    $Arch = "x64"
    $Projections = Get-Content -Path $PSScriptRoot\projections.json | ConvertFrom-Json
    $Package = $Projections.Package
    $PackageVersion = Get-NugetPackageVersion -Package $Package

    $ProjectName = $Projections.Project
    $ProjectDir = Join-Path $PSScriptRoot "Sources\C$ProjectName\nuget"

    # copy dlls from runtimes\win-<arch>\native to vendor\bin
    $PackageDir = Join-Path $PackagesDir "$Package.$PackageVersion"
    $PackagesRuntimeDir = Join-Path $PackageDir "runtimes\win-$Arch\native"
    $PackagesBinaries = Get-ChildItem -Path $PackagesRuntimeDir -Filter *.dll -Recurse

    $ProjectBinaryDir = Join-Path $ProjectDir "bin"
    if (-not (Test-Path $ProjectBinaryDir)) {
        New-Item -Path $ProjectBinaryDir -ItemType Directory -Force | Out-Null
    }

    $PackagesBinaries | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $ProjectBinaryDir -Force
    }

    # copy headers from include to vendor\include
    $ProjectHeadersDir = Join-Path $ProjectDir "include"
    if (-not (Test-Path $ProjectHeadersDir)) {
        New-Item -Path $ProjectHeadersDir -ItemType Directory -Force | Out-Null
    }
    $PackagesHeaderDir = Join-Path $PackageDir "include"
    $PackagesHeaders = Get-ChildItem -Path $PackagesHeaderDir -Filter *.h -Recurse
    $PackagesHeaders | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $ProjectHeadersDir -Force
    }

    # Copy libs from lib\win-<arch> to vendor\lib
    $ProjectLibsDir = Join-Path $ProjectDir "lib"
    $PackagesLibsDir = Join-Path $PackageDir "lib\win10-x64"
    $PackagesLibs = Get-ChildItem -Path $PackagesLibsDir -Filter *.lib -Recurse
    if (-not (Test-Path $ProjectLibsDir)) {
        New-Item -Path $ProjectLibsDir -ItemType Directory -Force | Out-Null
    }
    $PackagesLibs | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $ProjectLibsDir -Force
    }
}

$PackagesDir = Join-Path $PSScriptRoot ".packages"
Restore-Nuget -PackagesDir $PackagesDir
Invoke-SwiftWinRT -PackagesDir $PackagesDir
Copy-PackageAssets -PackagesDir $PackagesDir

if ($LASTEXITCODE -eq 0) {
    Write-Host "SwiftWinRT bindings generated successfully!" -ForegroundColor Green
}
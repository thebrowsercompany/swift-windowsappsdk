# swift-windowsappsdk
Swift Language Bindings for the Windows App SDK APIs

These APIs are intendened to be used in conjuction with the following projects:
- [swift-winui](https://github.com/thebrowsercompany/swift-winui)
- [swift-win2d](https://github.com/thebrowsercompany/swift-win2d)

## APIs
These projections contains a subset of APIs for the Windows App SDK, minus those of WinUI (`Microsoft.UI.Xaml`). See official documentation for more information on these components:

- [API Docs](https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/)
- [Official GitHub repo](https://github.com/microsoft/WindowsAppSDK)

### SDK Versions

1. Windows SDK: `10.0.18362.0`
2. Windows App SDK: `1.5-preview1`

## Project Configuration
The bindings are generated from WinMD files, found in NuGet packages on Nuget.org. There are three key files which drive this:
1. packages.config - this specifies the packages and their versions
2. projections.json - this specifies the project/package and which apis to include in the projection
3. generate-bindings.ps1 - this file reads both `packages.config` and `projections.json` and generates the appropriate bindings.

## Known Issues and Limitations
- The developer experience for consuming WinRT APIs from Swift is a work in progress. Due to current limitations, not all APIs can be generated as this causes export limit issues.

- The APIs listed in projections.json are required for the other `swift-*` projects to build. Modify a projections.json in any one of those projects could require an update here.

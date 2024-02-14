// swift-tools-version: 5.10

import PackageDescription
import Foundation

let currentDirectory = Context.packageDirectory

let linkerSettings: [LinkerSetting] = [
/* Figure out magic incantation so we can delay load these dlls
    .unsafeFlags(["-L\(currentDirectory)/Sources/CWinAppSDK/nuget/lib"]),
    .unsafeFlags(["-Xlinker" , "/DELAYLOAD:Microsoft.WindowsAppRuntime.Bootstrap.dll"]),
*/
]

let package = Package(
    name: "swift-windowsappsdk",
    products: [
        .library(name: "WinAppSDK", type: .dynamic, targets: ["WinAppSDK"]),
        .library(name: "CWinAppSDK", targets: ["CWinAppSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/thebrowsercompany/swift-cwinrt", branch: "main"),
        .package(url: "https://github.com/thebrowsercompany/swift-uwp", branch: "main"),
        .package(url: "https://github.com/thebrowsercompany/swift-windowsfoundation", branch: "main"),
    ],
    targets: [
        .target(
            name: "WinAppSDK",
            dependencies: [
                .product(name: "CWinRT", package: "swift-cwinrt"),
                .product(name: "UWP", package: "swift-uwp"),
                .product(name: "WindowsFoundation", package: "swift-windowsfoundation"),
                "CWinAppSDK"
            ]
        ),
        .target(
            name: "CWinAppSDK",
            resources: [
                .copy("nuget/bin/Microsoft.WindowsAppRuntime.Bootstrap.dll"),
            ],
            linkerSettings: linkerSettings
        ),
        .testTarget(
            name: "WinAppSDKTests",
            dependencies: [
                "WinAppSDK",
            ]
        )
    ]
)

// swift-tools-version: 5.10

import PackageDescription
import Foundation
let currentDirectory = Context.packageDirectory

print(currentDirectory)
let includeSettings: [SwiftSetting] = [
    .unsafeFlags(["-I\(currentDirectory)/vendor/include"])
]

let linkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-L\(currentDirectory)/vendor/lib"])
]

let package = Package(
    name: "swift-windowsappsdk",
    products: [
        .library(name: "WinAppSDK", type: .dynamic, targets: ["WinAppSDK"]),
        .library(name: "CWinAppSDK", targets: ["CWinAppSDK"]),
        .library(name: "WinAppSDKExt", targets: ["WinAppSDKExt"])
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
            ],
            resources: [
                .copy("../../vendor/bin/Microsoft.WindowsAppRuntime.Bootstrap.dll"),
            ]
        ),
        .target(
            name: "CWinAppSDK",
            swiftSettings: includeSettings,
            linkerSettings: linkerSettings
        ),
        .target(
            name: "WinAppSDKExt",
            dependencies: [
                "WinAppSDK",
                "CWinAppSDK"
            ]
        ),
    ]
)

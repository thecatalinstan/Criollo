// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Criollo",
    platforms: [
        .iOS(.v8),
        .macOS(.v10_10),
        .tvOS(.v9)
    ],
    products: [
        .library(
            name: "Criollo",
            type: .dynamic,
            targets: ["Criollo"]),
    ],
    dependencies: [
        .package(name:"CocoaAsyncSocket", url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.4"),
    ],
    targets: [
        .target(
            name: "Criollo",            
            dependencies: [
                "CocoaAsyncSocket"
            ],        
            path: "Criollo",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Source"),
                .headerSearchPath("Source/Extensions"),
                .headerSearchPath("Source/FCGI"),
                .headerSearchPath("Source/HTTP"),
                .headerSearchPath("Source/Routing")]),

        .testTarget(name: "CriolloTests",
                    dependencies: ["Criollo"],
                    path: "CriolloTests"),
    ]
)

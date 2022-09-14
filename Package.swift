// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Criollo",
    platforms: [.iOS(.v9), .macOS(.v10_10), .tvOS(.v9)],
    products: [
        .library(
            name: "Criollo",
            targets: ["Criollo"]
        ),
        .library(
            name: "CriolloSwift",
            targets: ["CriolloSwift"]
        ),
        .executable(
            name: "CriolloDemoSwift",
            targets: ["CriolloDemoSwift"]
        ),
        .executable(
            name: "CriolloDemoObjectiveC",
            targets: ["CriolloDemoObjectiveC"]
        ),
    ],
    dependencies: [
        .package(name:"CocoaAsyncSocket", url: "https://github.com/robbiehanson/CocoaAsyncSocket", .upToNextMinor(from: "7.6.5")),
    ],
    targets: [
        .target(
            name: "Criollo",            
            dependencies: [
                .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket")
            ],
            publicHeadersPath: "Headers",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("./Extensions"),
                .headerSearchPath("./FCGI"),
                .headerSearchPath("./HTTP"),
                .headerSearchPath("./Routing"),
            ]
        ),
        .testTarget(
            name: "CriolloTests",
            dependencies: ["Criollo"],
            cSettings: [
                .headerSearchPath("../../Sources/Criollo"),
                .headerSearchPath("../../Sources/Criollo/Extensions"),
                .headerSearchPath("../../Sources/Criollo/FCGI"),
                .headerSearchPath("../../Sources/Criollo/HTTP"),
                .headerSearchPath("../../Sources/Criollo/Routing"),
            ]
        ),
        .target(
            name: "CriolloSwift",
            dependencies: ["Criollo"]            
        ),
        .testTarget(
            name: "CriolloSwiftTests",
            dependencies: ["Criollo"]
        ),
        .executableTarget(
            name: "CriolloDemoSwift",
            dependencies: ["CriolloSwift"]
        ),
        .executableTarget(
            name: "CriolloDemoObjectiveC",
            dependencies: ["Criollo"]
        )
    ]
)

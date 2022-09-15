// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Criollo",
    platforms: [.iOS(.v9), .macOS(.v10_10), .tvOS(.v9)],
    products: [
        .library(name: "Criollo", targets: ["Criollo"]),
        .executable(name: "CriolloDemoSwift", targets: ["CriolloDemoSwift"]),
        .executable(name: "CriolloDemoObjectiveC", targets: ["CriolloDemoObjectiveC"]),
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
            exclude: [
                "../../Criollo.podspec"
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
        .executableTarget(
            name: "CriolloDemoSwift",
            dependencies: ["Criollo"]
        ),
        .executableTarget(
            name: "CriolloDemoObjectiveC",
            dependencies: ["Criollo"]
        )
    ]
)

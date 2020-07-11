// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [.macOS(.v10_13)],
    products: [],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
        .package(url: "https://github.com/MetalPetal/SIMDType.git", from: "0.0.3")
    ],
    targets: [
        .target(
            name: "SwiftPackageGenerator",
            dependencies: ["ArgumentParser", "URLExpressibleByArgument", "MetalPetalSourceLocator"]),
        .target(
            name: "BoilerplateGenerator",
            dependencies: ["ArgumentParser", "SIMDType", "URLExpressibleByArgument", "MetalPetalSourceLocator"]),
        .target(
            name: "UmbrellaHeaderGenerator",
            dependencies: ["ArgumentParser", "URLExpressibleByArgument", "RunCommand", "MetalPetalSourceLocator"]),
        .target(
            name: "PodspecGenerator",
            dependencies: ["ArgumentParser", "URLExpressibleByArgument", "RunCommand", "MetalPetalSourceLocator"]),
        .target(
            name: "URLExpressibleByArgument",
            dependencies: ["ArgumentParser"]),
        .target(name: "RunCommand"),
        .target(name: "MetalPetalSourceLocator"),
        .target(
            name: "main",
            dependencies: ["SwiftPackageGenerator", "BoilerplateGenerator", "UmbrellaHeaderGenerator", "PodspecGenerator"])
    ]
)

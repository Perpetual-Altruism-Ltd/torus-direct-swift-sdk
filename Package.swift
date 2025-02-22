// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "CustomAuth",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CustomAuth",
            targets: ["CustomAuth"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Perpetual-Altruism-Ltd/torus-utils-swift.git", branch: "master"),
        .package(name:"jwt-kit", url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
        .package(name: "JWTDecode", url: "https://github.com/auth0/JWTDecode.swift.git", from: "2.6.3")
    ],
    targets: [
        .target(
            name: "CustomAuth",
            dependencies: [.product(name: "TorusUtils", package: "torus-utils-swift"), "JWTDecode"]),
        .testTarget(
            name: "CustomAuthTests",
            dependencies: ["CustomAuth", .product(name: "TorusUtils", package: "torus-utils-swift"), .product(name: "JWTKit", package: "jwt-kit")]),
    ]
)

// swift-tools-version: 6.1
import PackageDescription
let package = Package(
    name: "SandboxLabCore",
    platforms: [.iOS(.v17)],
    products: [.library(name: "SandboxLabCore", targets: ["SandboxLabCore"])],
    targets: [
        .target(name: "SandboxLabCore"),
        .testTarget(name: "SandboxLabCoreTests", dependencies: ["SandboxLabCore"]),
    ]
)

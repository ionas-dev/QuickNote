// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MarkdownKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "MarkdownKit", targets: ["MarkdownKit"])
    ],
    targets: [
        .target(name: "MarkdownKit"),
        .testTarget(name: "MarkdownKitTests", dependencies: ["MarkdownKit"])
    ]
)

// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Quit",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
			url: "https://github.com/apple/swift-package-manager.git",
			from: "0.3.0"
		)
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Quit",
            dependencies: ["QuitCore"]
		),
        .target(
			name: "QuitCore",
			dependencies: ["Utility"]
		),
        .testTarget(
            name: "QuitTests",
            dependencies: ["QuitCore", "Utility"]),
    ]
)

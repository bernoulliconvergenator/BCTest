// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
   name: "bcTest",

   platforms: [
      .iOS(.v16), .macOS(.v15), .macCatalyst(.v15), .tvOS(.v18), .watchOS(.v11)
   ],

   products: [
      .library(
         name: "BCTest",
         targets: ["BCTest"]
      ),
   ],

   dependencies: [
      .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
   ],

   targets: [
      .target(
         name: "BCTest",
         dependencies: ["BCTestMacros"]
      ),
      .testTarget(
         name: "BCTestTests",
         dependencies: ["BCTest"]
      ),
      .macro(
         name: "BCTestMacros",
         dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
         ]
      ),
      .testTarget(
         name: "BCTestMacrosTests",
         dependencies: [
            "BCTest",
            "BCTestMacros",
            .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
         ]
      ),
      .testTarget(
         name: "AlternativesTests"
      ),
   ]
)

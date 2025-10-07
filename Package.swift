// swift-tools-version: 6.1

// Package.swift
// Swift-ONNX-CoreML

import PackageDescription
import Foundation

let shouldEnableRemoteTest = ProcessInfo.processInfo.environment["ENABLE_REMOTE_TEST"] != nil
//let shouldEnableRemoteTest = false

var dependencies: [Package.Dependency] = []
if shouldEnableRemoteTest {
    dependencies.append(
        .package(url: "file:///tmp/classifier-swift", from: "1.0.0")
    )
}

var targets: [Target] = [
        .binaryTarget(
            name: "onnxruntime",
            path: "../onnxruntime.xcframework"
        ),
        .target(
            name: "CommonUtils",
            dependencies: [
                .target(name: "ClassifierWrapper"),
            ],
            path: "Sources/common",
            sources: [
                "ReadJSON.swift",
                "TestClassifier.swift"
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ],
        ),
        .executableTarget(
            name: "test1",
            dependencies: [
                .target(name: "ClassifierWrapper"),
                .target(name: "CommonUtils")
            ],
            path: "Sources/test1",
            sources: [
                "main.swift"
            ],
            resources: [
                .process("Resources/GeoClassifier.onnx"),
                .process("Resources/GeoClassifierEvaluationData.json"),
                //.copy("Resources/GeoClassifier.mlmodelc")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .unsafeFlags(["-g"], .when(configuration: .debug))
            ],
        ),
        .target(
            name: "ClassifierWrapper",
            dependencies: [
                .target(name: "onnxruntime"),
                .target(name: "classifier"),
            ],
            path: "Sources/classifierWrapper",
            exclude: [
                "Resources/GeoClassifier.mlpackage",
            ],
            sources: [
                "CppClassifierWrapper.swift",
                "ClassifierProtocol.swift",
                "SwiftClassifier.swift",
            ],
            resources: [
                .copy("Resources/GeoClassifier.mlmodelc"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ],
        ),
        .target(
            name: "classifier",
            dependencies: [
                .target(name: "onnxruntime")
            ],
            path: "Sources/classifier",
            sources: ["ClassifierWrapper.cpp"],
            cxxSettings: [
                .headerSearchPath("include"),
                .unsafeFlags([
                    "-std=c++23",
                ])
            ],
        )
]

if shouldEnableRemoteTest {
    targets.append(
        .executableTarget(
            name: "test2",
            dependencies: [
                .product(name: "ClassifierWrapper", package: "classifier-swift"), 
                .product(name: "CommonUtils", package: "classifier-swift"), 
            ],
            path: "Sources/test2",
            sources: [
                "main.swift"
            ],
            resources: [
                .process("Resources/GeoClassifier.onnx"),
                .process("Resources/GeoClassifierEvaluationData.json"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        )
    )
}

let package = Package(
    name: "classifier",
    platforms: [
        .macOS(.v15),
        .iOS(.v16),
    ],
    products: shouldEnableRemoteTest ? 
        [
            // Include existing products + testClassifier2
            .library(name: "onnxruntime",targets: ["onnxruntime"]),
            .executable(name: "testClassifier1", targets: ["test1"]),
            .executable(name: "testClassifier2", targets: ["test2"]), // Conditional
            .library(name: "ClassifierWrapper", targets: ["ClassifierWrapper"]),
            .library(name: "CommonUtils", targets: ["CommonUtils"]),
            .library(name: "classifier", targets: ["classifier"])
        ] :
        [
            // Include only existing products
            .library(name: "onnxruntime",targets: ["onnxruntime"]),
            .executable(name: "testClassifier1", targets: ["test1"]),
            .library(name: "ClassifierWrapper", targets: ["ClassifierWrapper"]),
            .library(name: "CommonUtils", targets: ["CommonUtils"]),
            .library(name: "classifier", targets: ["classifier"])
        ],
        dependencies: dependencies, // Use the conditional dependency array
        targets: targets 
    )

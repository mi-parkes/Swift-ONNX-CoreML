// main.swift
// Swift-ONNX-CoreML/Sources/test2

import Foundation
import ClassifierWrapper
import CommonUtils

public class ModuleBundleHelper {
    public static func getFileUrl(filename: String, ext: String) -> URL? {
        if let fileURL = Bundle.module.url(forResource: filename, withExtension: ext) {
            return fileURL
        } else {
            print("Error: Could not find \(filename).\(ext) in the package module.")
            return nil
        }
    }
}

let args = CommandLine.arguments
let verbose = args.contains("--verbose")

func printer(msg: String) {
    print(msg)
}

let fileGeoDataLoader = FileGeoDataLoader()

let onnxClassifier: ClassifierProtocol = CppClassifierWrapper()
let onnxModelURL = ModuleBundleHelper.getFileUrl(filename: "GeoClassifier", ext: "onnx")
let testDataURL = ModuleBundleHelper.getFileUrl(filename: "GeoClassifierEvaluationData", ext: "json")

if let testURL = testDataURL, let modelURL = onnxModelURL {
    let tc: TestClassifier = TestClassifier(
        geoClassifier: onnxClassifier,
        geoDataLoader: fileGeoDataLoader,
        printer: printer,
        modelURL: modelURL,
        testURL: testURL,
        verbose: verbose
    )
    if !tc.runTest() {
        printer(msg: "Check your C++ wrapper setup.")
    }
} else {
    printer(msg: "ONNX classifier test skipped: One or more files not found.")
}

var swiftClassifier: ClassifierProtocol = SwiftClassifier()
let coreMLModelURL = ClassifierBundleAccess.getFileUrl(filename: "GeoClassifier", ext: "mlmodelc")

if let testURL = testDataURL, let modelURL = coreMLModelURL {
    //print("coreMLModelURL=\(coreMLModelURL)")
    let tc: TestClassifier = TestClassifier(
        geoClassifier: swiftClassifier,
        geoDataLoader: fileGeoDataLoader,
        printer: printer,
        modelURL: modelURL,
        testURL: testURL,
        verbose: verbose
    )
    if !tc.runTest() {
        printer(msg: "Check your Swift classifier setup.")
    }
} else {
    printer(msg: "Core ML classifier test skipped: One or more files not found.")
}

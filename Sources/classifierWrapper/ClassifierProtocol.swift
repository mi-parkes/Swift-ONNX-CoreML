//
// ClassifierProtocol.swift
// Swift-ONNX-CoreML/Sources/classifierWrapper
//
import Foundation

public protocol ClassifierProtocol {
    
    /// Initializes the classifier with a model.
    func minit(modelURL: URL, verbose: Bool) -> Int
    
    /// Performs inference and returns the predicted class index.
    func infer(v1: Float, v2: Float) -> Int
    
    /// De-initializes the classifier.
    func dispose()
    
    /// Returns the last error message.
    func getLastError() -> String

    func getName() -> String
}

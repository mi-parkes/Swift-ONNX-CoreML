// ReadJSON.swift
// Swift-ONNX-CoreML/Sources/common

import Foundation

public struct CityData: Decodable {
    public let label: Int
    public let coords: [[Double]]
}

public typealias GeoData = [String: CityData]

public class FileGeoDataLoader: GeoDataLoader {
    public init() {}
    public func loadGeoData(from url: URL) -> GeoData? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let geoData = try decoder.decode(GeoData.self, from: data)
            return geoData
        } catch {
            print("Error decoding geodata: \(error)")
            return nil
        }
    }
}

public class DefaultCityNameFinder: CityNameFinder {
    public init() {}
    public func findCityName(forLabel targetLabel: Int, in geoData: GeoData) -> String? {
        for (cityName, cityData) in geoData {
            if cityData.label == targetLabel {
                return cityName
            }
        }
        return nil
    }
}


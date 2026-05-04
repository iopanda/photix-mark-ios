import Foundation
import CoreGraphics

public protocol ImageProcessor: Sendable {
    var name: String { get }
    func process(_ ctx: ProcessorContext) async throws -> ProcessorContext
}

public enum ProcessorError: Error, LocalizedError {
    case invalidLayer
    case cgContextCreationFailed
    case missingRequiredConfig(String)
    case unsupportedImageFormat

    public var errorDescription: String? {
        switch self {
        case .invalidLayer: return "No valid image layer in context"
        case .cgContextCreationFailed: return "Failed to create CGContext"
        case .missingRequiredConfig(let key): return "Missing required config key: \(key)"
        case .unsupportedImageFormat: return "Unsupported image format"
        }
    }
}

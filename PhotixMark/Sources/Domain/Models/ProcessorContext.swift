import Foundation
import CoreGraphics

public struct ProcessorContext: Sendable {
    /// Multi-layer image buffer — equivalent to web's HTMLCanvasElement[]
    public var layers: [CGImage]
    public var exif: ExifData
    public var userOptions: TemplateUserOptions
    /// Per-step config from the ProcessorStep definition
    public var stepConfig: [String: StepValue]
    /// Custom brand logos: brand name (lowercased) → PNG data
    public var customLogos: [String: Data]

    public init(
        sourceImage: CGImage,
        exif: ExifData,
        userOptions: TemplateUserOptions,
        customLogos: [String: Data] = [:]
    ) {
        self.layers = [sourceImage]
        self.exif = exif
        self.userOptions = userOptions
        self.stepConfig = [:]
        self.customLogos = customLogos
    }

    public var primaryLayer: CGImage { layers[0] }
    public var primarySize: CGSize { CGSize(width: primaryLayer.width, height: primaryLayer.height) }
}

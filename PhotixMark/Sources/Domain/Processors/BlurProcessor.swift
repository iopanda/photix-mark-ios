import Foundation
import CoreGraphics

/// Applies Gaussian blur to the primary layer.
/// stepConfig: blur_radius (Double, fraction of height if < 2, else absolute px)
public struct BlurProcessor: ImageProcessor {
    public let name = "blur"

    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let fraction = ctx.stepConfig["blur_radius"]?.doubleValue ?? ctx.userOptions.blur?.radiusFraction ?? 0.03
        let radius = CGContextHelpers.resolve(fraction, reference: CGFloat(source.height))

        guard let blurred = CGContextHelpers.blur(source, radius: radius) else {
            return ctx
        }

        var result = ctx
        result.layers[0] = blurred
        return result
    }
}

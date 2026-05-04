import Foundation
import CoreGraphics

/// Clips the primary layer to rounded corners.
/// stepConfig: corner_radius (Double, fraction of min(width,height) if < 1)
public struct RoundedCornerProcessor: ImageProcessor {
    public let name = "rounded_corner"

    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let fraction = ctx.stepConfig["corner_radius"]?.doubleValue
            ?? ctx.userOptions.border?.radiusFraction ?? 0.0
        guard fraction > 0 else { return ctx }

        let w = CGFloat(source.width)
        let h = CGFloat(source.height)
        let radius = CGContextHelpers.resolve(fraction, reference: min(w, h))

        guard let cgCtx = CGContextHelpers.createContext(width: source.width, height: source.height) else {
            throw ProcessorError.cgContextCreationFailed
        }

        // Build rounded rect path and clip
        let rect = CGRect(x: 0, y: 0, width: w, height: h)
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        cgCtx.addPath(path)
        cgCtx.clip()

        CGContextHelpers.draw(source, in: cgCtx, at: rect)

        guard let result = cgCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers[0] = result
        return newCtx
    }
}

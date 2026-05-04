import Foundation
import CoreGraphics

/// Crops the primary layer.
/// stepConfig: x, y, width, height (all Double, fractions of source size if < 1)
public struct CropProcessor: ImageProcessor {
    public let name = "crop"

    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let sw = CGFloat(source.width)
        let sh = CGFloat(source.height)

        let x = CGContextHelpers.resolve(ctx.stepConfig["x"]?.doubleValue ?? 0, reference: sw)
        let y = CGContextHelpers.resolve(ctx.stepConfig["y"]?.doubleValue ?? 0, reference: sh)
        let w = CGContextHelpers.resolve(ctx.stepConfig["width"]?.doubleValue ?? 1, reference: sw)
        let h = CGContextHelpers.resolve(ctx.stepConfig["height"]?.doubleValue ?? 1, reference: sh)

        let cropRect = CGRect(x: x, y: y, width: w, height: h)
        guard let cropped = source.cropping(to: cropRect) else { return ctx }

        var newCtx = ctx
        newCtx.layers[0] = cropped
        return newCtx
    }
}

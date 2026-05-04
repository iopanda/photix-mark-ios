import Foundation
import CoreGraphics

/// Resizes the primary layer.
/// stepConfig: target_width (Double), target_height (Double), scale (Double, fraction) — mutually exclusive
public struct ResizeProcessor: ImageProcessor {
    public let name = "resize"

    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let origW = CGFloat(source.width)
        let origH = CGFloat(source.height)

        let targetW: CGFloat
        let targetH: CGFloat

        if let scale = ctx.stepConfig["scale"]?.doubleValue {
            targetW = origW * CGFloat(scale)
            targetH = origH * CGFloat(scale)
        } else if let tw = ctx.stepConfig["target_width"]?.doubleValue,
                  let th = ctx.stepConfig["target_height"]?.doubleValue {
            targetW = CGFloat(tw)
            targetH = CGFloat(th)
        } else if let tw = ctx.stepConfig["target_width"]?.doubleValue {
            targetW = CGFloat(tw)
            targetH = origH * (CGFloat(tw) / origW)
        } else if let th = ctx.stepConfig["target_height"]?.doubleValue {
            targetH = CGFloat(th)
            targetW = origW * (CGFloat(th) / origH)
        } else {
            return ctx
        }

        guard let cgCtx = CGContextHelpers.createContext(width: Int(targetW), height: Int(targetH)) else {
            throw ProcessorError.cgContextCreationFailed
        }

        CGContextHelpers.draw(source, in: cgCtx, at: CGRect(x: 0, y: 0, width: targetW, height: targetH))

        guard let result = cgCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers[0] = result
        return newCtx
    }
}

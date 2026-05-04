import Foundation
import CoreGraphics

/// Adds uniform padding around the primary layer with a background fill.
/// stepConfig: margin (Double, fraction of height), bg_color (String hex)
public struct MarginProcessor: ImageProcessor {
    public let name = "margin"

    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let fraction = ctx.stepConfig["margin"]?.doubleValue
            ?? ctx.userOptions.layout.paddingFraction
        let bgHex = ctx.stepConfig["bg_color"]?.stringValue
            ?? ctx.userOptions.background.backgroundColorHex

        let w = CGFloat(source.width)
        let h = CGFloat(source.height)
        let margin = CGContextHelpers.resolve(fraction, reference: h)

        let newW = Int(w + margin * 2)
        let newH = Int(h + margin * 2)

        guard let cgCtx = CGContextHelpers.createContext(width: newW, height: newH) else {
            throw ProcessorError.cgContextCreationFailed
        }

        cgCtx.setFillColor(CGContextHelpers.color(hex: bgHex))
        cgCtx.fill(CGRect(x: 0, y: 0, width: newW, height: newH))
        CGContextHelpers.draw(source, in: cgCtx, at: CGRect(x: margin, y: margin, width: w, height: h))

        guard let result = cgCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers[0] = result
        return newCtx
    }
}

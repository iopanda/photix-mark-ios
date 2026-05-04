import Foundation
import CoreGraphics

/// Adds a drop shadow around the primary layer.
/// stepConfig: shadow_radius (Double, fraction), shadow_color (String hex), shadow_offset_y (Double, fraction)
public struct ShadowProcessor: ImageProcessor {
    public let name = "shadow"

    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let opts = ctx.userOptions.shadow
        let radiusFraction = ctx.stepConfig["shadow_radius"]?.doubleValue ?? opts?.radiusFraction ?? 0.006
        let colorHex = ctx.stepConfig["shadow_color"]?.stringValue ?? opts?.colorHex ?? "#00000033"
        let offsetYFraction = ctx.stepConfig["shadow_offset_y"]?.doubleValue ?? 0.01

        let w = source.width
        let h = source.height
        let radius = CGContextHelpers.resolve(radiusFraction, reference: CGFloat(h))
        let offsetY = CGContextHelpers.resolve(offsetYFraction, reference: CGFloat(h))
        let padding = radius * 2

        let newW = Int(CGFloat(w) + padding * 2)
        let newH = Int(CGFloat(h) + padding * 2 + offsetY)

        guard let cgCtx = CGContextHelpers.createContext(width: newW, height: newH) else {
            throw ProcessorError.cgContextCreationFailed
        }

        let shadowColor = CGContextHelpers.color(hex: colorHex)
        cgCtx.setShadow(
            offset: CGSize(width: 0, height: -offsetY),
            blur: radius,
            color: shadowColor
        )

        let destRect = CGRect(x: padding, y: padding, width: CGFloat(w), height: CGFloat(h))
        CGContextHelpers.draw(source, in: cgCtx, at: destRect)

        guard let result = cgCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers[0] = result
        return newCtx
    }
}

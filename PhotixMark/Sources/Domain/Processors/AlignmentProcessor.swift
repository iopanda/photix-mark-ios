import Foundation
import CoreGraphics

/// Overlays layer[1] on top of layer[0] with alignment control.
/// stepConfig: h_align ("left"|"center"|"right"), v_align ("top"|"center"|"bottom"),
///             offset_x (Double, fraction), offset_y (Double, fraction), bg_color (hex)
public struct AlignmentProcessor: ImageProcessor {
    public let name = "alignment"

    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard ctx.layers.count >= 2 else { return ctx }
        let base = ctx.layers[0]
        let overlay = ctx.layers[1]

        let bw = CGFloat(base.width)
        let bh = CGFloat(base.height)
        let ow = CGFloat(overlay.width)
        let oh = CGFloat(overlay.height)

        let hAlign = ctx.stepConfig["h_align"]?.stringValue ?? "center"
        let vAlign = ctx.stepConfig["v_align"]?.stringValue ?? "center"
        let offsetXFrac = ctx.stepConfig["offset_x"]?.doubleValue ?? 0
        let offsetYFrac = ctx.stepConfig["offset_y"]?.doubleValue ?? 0
        let bgHex = ctx.stepConfig["bg_color"]?.stringValue
            ?? ctx.userOptions.background.backgroundColorHex

        let totalW = max(bw, ow)
        let totalH = bh + oh
        let newW = Int(totalW)
        let newH = Int(totalH)

        guard let cgCtx = CGContextHelpers.createContext(width: newW, height: newH) else {
            throw ProcessorError.cgContextCreationFailed
        }

        cgCtx.setFillColor(CGContextHelpers.color(hex: bgHex))
        cgCtx.fill(CGRect(x: 0, y: 0, width: newW, height: newH))

        // Draw base layer
        CGContextHelpers.draw(base, in: cgCtx, at: CGRect(x: 0, y: 0, width: bw, height: bh))

        // Compute overlay position
        let ox: CGFloat
        switch hAlign {
        case "left":  ox = CGContextHelpers.resolve(offsetXFrac, reference: bw)
        case "right": ox = bw - ow - CGContextHelpers.resolve(offsetXFrac, reference: bw)
        default:      ox = (bw - ow) / 2 + CGContextHelpers.resolve(offsetXFrac, reference: bw)
        }

        let oy: CGFloat
        switch vAlign {
        case "top":    oy = CGContextHelpers.resolve(offsetYFrac, reference: bh)
        case "bottom": oy = bh - oh - CGContextHelpers.resolve(offsetYFrac, reference: bh)
        default:       oy = bh // stack below by default
        }

        CGContextHelpers.draw(overlay, in: cgCtx, at: CGRect(x: ox, y: oy, width: ow, height: oh))

        guard let result = cgCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers = [result]
        return newCtx
    }
}

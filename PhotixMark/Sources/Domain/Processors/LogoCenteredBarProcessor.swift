import Foundation
import CoreGraphics

/// Appends a white bar below the photo containing only the brand logo centered.
/// No text. Mirrors web's logoCentered template (品牌印记).
public struct LogoCenteredBarProcessor: ImageProcessor {
    public let name = "logo_centered_bar"
    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let sw = CGFloat(source.width)
        let sh = CGFloat(source.height)
        let barH = max(80.0, sh * 0.12)

        let resolver = LogoResolver(customLogos: ctx.customLogos)
        guard let logo = resolver.resolve(brand: ctx.exif.make) else {
            return ctx
        }

        let logoTargetH = barH * 0.55
        let aspect = CGFloat(logo.width) / max(CGFloat(logo.height), 1)
        let logoW = logoTargetH * aspect

        let totalH = sh + barH
        guard let finalCtx = CGContextHelpers.createContext(width: Int(sw), height: Int(totalH)) else {
            throw ProcessorError.cgContextCreationFailed
        }

        // Background white
        finalCtx.setFillColor(CGContextHelpers.color(hex: "#FFFFFF"))
        finalCtx.fill(CGRect(x: 0, y: 0, width: sw, height: totalH))

        CGContextHelpers.draw(source, in: finalCtx,
                              at: CGRect(x: 0, y: 0, width: sw, height: sh))

        let logoX = (sw - logoW) / 2
        let logoY = sh + (barH - logoTargetH) / 2

        CGContextHelpers.draw(logo, in: finalCtx,
                              at: CGRect(x: logoX, y: logoY, width: logoW, height: logoTargetH))

        guard let result = finalCtx.makeImage() else {
            throw ProcessorError.cgContextCreationFailed
        }
        var newCtx = ctx
        newCtx.layers[0] = result
        return newCtx
    }
}

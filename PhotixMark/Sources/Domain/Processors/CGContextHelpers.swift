import Foundation
import CoreGraphics
import CoreImage
import CoreText

// MARK: - Shared Core Graphics helpers used by all processors

enum CGContextHelpers {

    static let colorSpace = CGColorSpaceCreateDeviceRGB()

    static func createContext(width: Int, height: Int) -> CGContext? {
        CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).rawValue
        )
    }

    /// Draws a CGImage into a CGContext using top-left origin coordinates (UIKit convention).
    /// CGContext is y-up (origin = bottom-left), so we convert the rect before calling ctx.draw.
    static func draw(_ image: CGImage, in ctx: CGContext, at rect: CGRect) {
        let h = CGFloat(ctx.height)
        // Convert from top-left origin to bottom-left origin
        let flipped = CGRect(x: rect.origin.x,
                             y: h - rect.origin.y - rect.height,
                             width: rect.width,
                             height: rect.height)
        ctx.draw(image, in: flipped)
    }

    /// Resolves a fraction-or-absolute value: if < 2, treats as fraction of `reference`.
    static func resolve(_ value: Double, reference: CGFloat) -> CGFloat {
        value < 2 ? CGFloat(value) * reference : CGFloat(value)
    }

    /// Applies a Gaussian blur to a CGImage using Core Image.
    static func blur(_ image: CGImage, radius: CGFloat) -> CGImage? {
        let ciImage = CIImage(cgImage: image)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage else { return nil }
        let context = CIContext(options: [.useSoftwareRenderer: false])
        // Crop to original bounds to avoid blur edge expansion
        let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        return context.createCGImage(output, from: rect)
    }

    // MARK: - CoreText text rendering (cross-platform, replaces UIGraphics text APIs)

    static func ctFont(size: CGFloat, bold: Bool) -> CTFont {
        let uiType: CTFontUIFontType = bold ? .emphasizedSystem : .system
        return CTFontCreateUIFontForLanguage(uiType, size, nil)
            ?? CTFontCreateWithName("Helvetica" as CFString, size, nil)
    }

    /// Renders text into a CGImage in y-up storage format (same as all other CGImages
    /// produced by this pipeline). Callers blit it with the standard `draw(_:in:at:)`.
    /// CoreText draws natively in y-up space; ctx.draw's implicit row-0-at-bottom placement
    /// combined with CGContextHelpers.draw's y-flip results in correct glyph orientation.
    static func renderText(
        _ text: String,
        font: CTFont,
        color: CGColor,
        maxWidth: CGFloat
    ) -> CGImage? {
        guard !text.isEmpty else { return nil }
        let attrs: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: color
        ]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let framesetter = CTFramesetterCreateWithAttributedString(attrStr)
        let fitSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter, CFRangeMake(0, 0), nil,
            CGSize(width: maxWidth, height: .greatestFiniteMagnitude), nil)
        let w = max(1, ceil(fitSize.width) + 2)
        let h = max(1, ceil(fitSize.height) + 2)
        guard let ctx = createContext(width: Int(w), height: Int(h)) else { return nil }
        // Draw CoreText directly in y-up space — no flip needed.
        // The resulting CGImage is in the same y-up storage format as all other images
        // in this pipeline (photos, composites). Use draw(_:in:at:) to blit.
        let path = CGPath(rect: CGRect(x: 1, y: 0, width: w - 2, height: h - 2), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        CTFrameDraw(frame, ctx)
        return ctx.makeImage()
    }

    /// Returns the width of `text` rendered as a single unbroken line (no wrapping).
    static func measureSingleLine(_ text: String, font: CTFont) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let attrs: [CFString: Any] = [kCTFontAttributeName: font]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    }

    static func measureText(_ text: String, font: CTFont, maxWidth: CGFloat) -> CGSize {
        guard !text.isEmpty else { return .zero }
        let attrs: [CFString: Any] = [kCTFontAttributeName: font]
        let attrStr = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
        let framesetter = CTFramesetterCreateWithAttributedString(attrStr)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter, CFRangeMake(0, 0), nil,
            CGSize(width: maxWidth, height: .greatestFiniteMagnitude), nil)
        return CGSize(width: ceil(size.width) + 2, height: ceil(size.height) + 2)
    }

    /// Creates a CGColor from a hex string like "#RRGGBB" or "#RRGGBBAA".
    static func color(hex: String) -> CGColor {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned = String(cleaned.dropFirst()) }

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        switch cleaned.count {
        case 6:
            let r = CGFloat((rgb >> 16) & 0xFF) / 255
            let g = CGFloat((rgb >> 8) & 0xFF) / 255
            let b = CGFloat(rgb & 0xFF) / 255
            return CGColor(colorSpace: colorSpace, components: [r, g, b, 1.0]) ?? CGColor(gray: 0, alpha: 1)
        case 8:
            let r = CGFloat((rgb >> 24) & 0xFF) / 255
            let g = CGFloat((rgb >> 16) & 0xFF) / 255
            let b = CGFloat((rgb >> 8) & 0xFF) / 255
            let a = CGFloat(rgb & 0xFF) / 255
            return CGColor(colorSpace: colorSpace, components: [r, g, b, a]) ?? CGColor(gray: 0, alpha: 1)
        default:
            return CGColor(gray: 0, alpha: 1)
        }
    }
}

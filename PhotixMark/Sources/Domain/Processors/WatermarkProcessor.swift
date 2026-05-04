import Foundation
import CoreGraphics

/// Appends a watermark bar below the photo.
/// Uses CGContext throughout — all coordinates passed to CGContextHelpers.draw are top-left.
public struct WatermarkProcessor: ImageProcessor {
    public let name = "watermark"
    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let renderer = TemplateRenderer(exif: ctx.exif, customLogos: ctx.customLogos, exifFields: ctx.userOptions.exifFields)
        let opts = ctx.userOptions

        let sourceW = CGFloat(source.width)
        let sourceH = CGFloat(source.height)
        let barHeight = max(80.0, sourceH * 0.12)
        let padding = sourceW * 0.04
        let logoSize = barHeight * 0.55

        let textColorHex = ctx.stepConfig["text_color"]?.stringValue ?? opts.colors.textColorHex
        let secColorHex  = ctx.stepConfig["secondary_color"]?.stringValue ?? opts.colors.secondaryTextColorHex
        let logoEnabled  = ctx.stepConfig["logo_enabled"]?.boolValue ?? opts.logo.enabled

        let leftTop  = resolveCornerText("left_top",    ctx: ctx, renderer: renderer) ?? ctx.exif.model ?? ""
        let leftBot  = resolveCornerText("left_bottom", ctx: ctx, renderer: renderer) ?? ctx.exif.lensModel ?? ""
        let rightTop = resolveCornerText("right_top",   ctx: ctx, renderer: renderer) ?? buildParamsText(opts.exifFields, exif: ctx.exif)
        let rightBot = resolveCornerText("right_bottom", ctx: ctx, renderer: renderer) ?? (ctx.exif.dateTimeOriginal ?? "")

        guard let canvas = CGContextHelpers.createContext(width: Int(sourceW), height: Int(sourceH + barHeight)) else {
            throw ProcessorError.cgContextCreationFailed
        }

        // 1. Draw source photo (top-left: y=0)
        CGContextHelpers.draw(source, in: canvas, at: CGRect(x: 0, y: 0, width: sourceW, height: sourceH))

        // 2. Fill watermark bar.
        // Canvas is (sourceW) x (sourceH + barHeight). CGContext y-up means:
        //   - Photo occupies top portion  → CGContextHelpers.draw places source at top-left y=0
        //   - Bar occupies bottom portion → CGContext y=0..barHeight (bottom of canvas)
        let bgColor = CGContextHelpers.color(hex: ctx.stepConfig["bg_color"]?.stringValue ?? opts.background.backgroundColorHex)
        canvas.setFillColor(bgColor)
        canvas.fill(CGRect(x: 0, y: 0, width: sourceW, height: barHeight))

        // 3. Optional separator line
        // In CGContext y-up coordinates: the boundary between photo and bar is at y = barHeight
        if opts.border?.enabled == true {
            let lineColor = CGContextHelpers.color(hex: opts.border?.colorHex ?? "#E5E5E5")
            canvas.setStrokeColor(lineColor)
            canvas.setLineWidth(1)
            canvas.move(to: CGPoint(x: 0, y: barHeight))
            canvas.addLine(to: CGPoint(x: sourceW, y: barHeight))
            canvas.strokePath()
        }

        // 5. Logo — determine rightEdge before any text layout
        var rightEdge = sourceW - padding
        if logoEnabled {
            let resolver = LogoResolver(customLogos: ctx.customLogos)
            if let logo = resolver.resolve(brand: ctx.exif.make) {
                let aspect = CGFloat(logo.width) / max(CGFloat(logo.height), 1)
                let logoW = logoSize * aspect
                let logoX = sourceW - padding - logoW
                let logoY = sourceH + (barHeight - logoSize) / 2
                CGContextHelpers.draw(logo, in: canvas,
                                      at: CGRect(x: logoX, y: logoY, width: logoW, height: logoSize))
                rightEdge = logoX - padding * 0.5
            }
        }

        // Available width per side (half of usable bar minus a centre gap)
        let centerGap  = padding
        let availableW = rightEdge - padding
        let halfW      = max((availableW - centerGap) / 2, 1)

        // Font size: start from bar-relative size, then shrink until every text fits in halfW
        let primaryFontSize   = fittingFontSize(
            texts: [leftTop, rightTop], bold: true,
            startSize: barHeight * 0.28, maxWidth: halfW)
        let secondaryFontSize = fittingFontSize(
            texts: [leftBot, rightBot], bold: false,
            startSize: barHeight * 0.22, maxWidth: halfW)

        // Vertical text placement inside bar (top-left coords)
        let textY   = sourceH + (barHeight - primaryFontSize - secondaryFontSize) / 3
        let secondY = textY + primaryFontSize * 1.3

        // 4. Draw texts
        let leftZone = CGRect(x: padding, y: 0, width: halfW, height: CGFloat.greatestFiniteMagnitude)
        drawText(leftTop, in: leftZone, y: textY,   fontSize: primaryFontSize,   colorHex: textColorHex, bold: true,  into: canvas)
        drawText(leftBot, in: leftZone, y: secondY,  fontSize: secondaryFontSize, colorHex: secColorHex,  bold: false, into: canvas)

        drawTextRight(rightTop, rightEdge: rightEdge, maxWidth: halfW, y: textY,   fontSize: primaryFontSize,   colorHex: textColorHex, bold: true,  into: canvas)
        drawTextRight(rightBot, rightEdge: rightEdge, maxWidth: halfW, y: secondY,  fontSize: secondaryFontSize, colorHex: secColorHex,  bold: false, into: canvas)

        guard let cgResult = canvas.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers = [cgResult]
        return newCtx
    }

    // MARK: - Helpers

    private func resolveCornerText(_ key: String, ctx: ProcessorContext, renderer: TemplateRenderer) -> String? {
        guard let dict = ctx.stepConfig[key]?.dictValue,
              let template = dict["text"]?.stringValue else { return nil }
        let rendered = renderer.render(template)
        return rendered.isEmpty ? nil : rendered
    }

    private func buildParamsText(_ fields: ExifFieldOptions, exif: ExifData) -> String {
        var parts: [String] = []
        if fields.showFocalLength, let v = exif.focalLength { parts.append(v) }
        if fields.showAperture,   let v = exif.fNumber      { parts.append(v) }
        if fields.showShutter,    let v = exif.exposureTime { parts.append(v) }
        if fields.showISO,        let v = exif.iso          { parts.append(v) }
        return parts.joined(separator: "  ")
    }

    /// Returns the largest font size ≤ startSize such that every non-empty text
    /// fits on a single line within maxWidth.
    private func fittingFontSize(texts: [String], bold: Bool,
                                 startSize: CGFloat, maxWidth: CGFloat) -> CGFloat {
        var size = startSize
        let minSize: CGFloat = 8
        while size > minSize {
            let font = CGContextHelpers.ctFont(size: size, bold: bold)
            let fits = texts.filter { !$0.isEmpty }.allSatisfy {
                CGContextHelpers.measureSingleLine($0, font: font) <= maxWidth
            }
            if fits { return size }
            size -= 1
        }
        return minSize
    }

    /// Draws left-aligned text at (zone.origin.x, y) in top-left coordinates.
    private func drawText(_ text: String, in zone: CGRect, y: CGFloat,
                          fontSize: CGFloat, colorHex: String, bold: Bool,
                          into canvas: CGContext) {
        guard !text.isEmpty else { return }
        let maxW = zone.width
        if let img = RichTextProcessor().renderText(text, fontSize: fontSize, colorHex: colorHex, bold: bold, maxWidth: maxW) {
            let iw = min(CGFloat(img.width), zone.width)
            let ih = CGFloat(img.height)
            CGContextHelpers.draw(img, in: canvas, at: CGRect(x: zone.origin.x, y: y, width: iw, height: ih))
        }
    }

    /// Draws right-aligned text ending at `rightEdge`, rendered within `maxWidth`.
    private func drawTextRight(_ text: String, rightEdge: CGFloat, maxWidth: CGFloat, y: CGFloat,
                               fontSize: CGFloat, colorHex: String, bold: Bool,
                               into canvas: CGContext) {
        guard !text.isEmpty, maxWidth > 0 else { return }
        if let img = RichTextProcessor().renderText(text, fontSize: fontSize, colorHex: colorHex, bold: bold, maxWidth: maxWidth) {
            let iw = min(CGFloat(img.width), maxWidth)
            let ih = CGFloat(img.height)
            CGContextHelpers.draw(img, in: canvas, at: CGRect(x: rightEdge - iw, y: y, width: iw, height: ih))
        }
    }
}

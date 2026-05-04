import Foundation
import CoreGraphics

/// Nikon Z-series style: blurred background + scaled-down sharp photo +
/// model name with "Z" highlighted in red + shooting params — all in white over the blur.
///
/// Pipeline (self-contained, replaces blur + resize + alignment chain):
///   1. Scale source up × bg_scale → blur → background canvas
///   2. Scale source down × photo_scale → sharp foreground
///   3. Composite foreground centered-top on background
///   4. Render model name split at first "Z": [before Z](white bold) + [Z](red bold) + [after Z](white bold)
///   5. Render params line (white regular)
///   6. Stack text lines vertically, overlay at bottom-center
///
/// stepConfig:
///   blur_radius  (Double fraction, default 0.05)
///   bg_scale     (Double multiplier, default 1.15)
///   photo_scale  (Double multiplier, default 0.88)
///   text_spacing (Double fraction of source height, default 0.03)
public struct NikonBlurCompositeProcessor: ImageProcessor {
    public let name = "nikon_blur_composite"
    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let blurFraction  = ctx.stepConfig["blur_radius"]?.doubleValue  ?? ctx.userOptions.blur?.radiusFraction ?? 0.05
        let bgScale       = CGFloat(ctx.stepConfig["bg_scale"]?.doubleValue   ?? 1.15)
        let photoScale    = CGFloat(ctx.stepConfig["photo_scale"]?.doubleValue ?? 0.88)
        let textSpacingFr = ctx.stepConfig["text_spacing"]?.doubleValue ?? 0.03

        let sw = CGFloat(source.width)
        let sh = CGFloat(source.height)
        let blurRadius  = CGContextHelpers.resolve(blurFraction, reference: sh)
        let textSpacing = CGContextHelpers.resolve(textSpacingFr, reference: sh)

        // ── 1. Blurred background ─────────────────────────────────────────────
        let bgW = Int(sw * bgScale)
        let bgH = Int(sh * bgScale)
        guard let bgCtx = CGContextHelpers.createContext(width: bgW, height: bgH) else {
            throw ProcessorError.cgContextCreationFailed
        }
        CGContextHelpers.draw(source, in: bgCtx,
                              at: CGRect(x: 0, y: 0, width: CGFloat(bgW), height: CGFloat(bgH)))
        guard let bgRaw = bgCtx.makeImage(),
              let bgBlurred = CGContextHelpers.blur(bgRaw, radius: blurRadius) else {
            throw ProcessorError.cgContextCreationFailed
        }

        // ── 2. Sharp foreground (scaled down) ────────────────────────────────
        let fgW = Int(sw * photoScale)
        let fgH = Int(sh * photoScale)
        guard let fgCtx = CGContextHelpers.createContext(width: fgW, height: fgH) else {
            throw ProcessorError.cgContextCreationFailed
        }
        CGContextHelpers.draw(source, in: fgCtx,
                              at: CGRect(x: 0, y: 0, width: CGFloat(fgW), height: CGFloat(fgH)))
        guard let foreground = fgCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }

        // ── 3. Composite photo centered, slightly above center ────────────────
        let photoOffsetY = CGFloat(bgH) * 0.03
        let photoX = (CGFloat(bgW) - CGFloat(fgW)) / 2
        let photoY = max(0, (CGFloat(bgH) - CGFloat(fgH)) / 2 - photoOffsetY)

        guard let compositeCtx = CGContextHelpers.createContext(width: bgW, height: bgH) else {
            throw ProcessorError.cgContextCreationFailed
        }
        CGContextHelpers.draw(bgBlurred, in: compositeCtx,
                              at: CGRect(x: 0, y: 0, width: CGFloat(bgW), height: CGFloat(bgH)))
        CGContextHelpers.draw(foreground, in: compositeCtx,
                              at: CGRect(x: photoX, y: photoY, width: CGFloat(fgW), height: CGFloat(fgH)))
        guard let withPhoto = compositeCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }

        // ── 4 & 5. Build text lines ────────────────────────────────────────────
        let line1FontSize = CGContextHelpers.resolve(0.04, reference: sh)
        let line2FontSize = CGContextHelpers.resolve(0.03, reference: sh)
        let maxTextW      = CGFloat(bgW) * 0.85

        let modelLine  = renderModelLine(ctx.exif.model, fontSize: line1FontSize, maxWidth: maxTextW)
        let paramsText = buildParamsText(ctx.exif, opts: ctx.userOptions.exifFields)
        let richText   = RichTextProcessor()
        let paramsLine = paramsText.isEmpty ? nil :
            richText.renderText(paramsText, fontSize: line2FontSize,
                                colorHex: "#FFFFFF", bold: false, maxWidth: maxTextW)

        // ── 6. Stack text, overlay at bottom-center ───────────────────────────
        let lines: [CGImage] = [modelLine, paramsLine].compactMap { $0 }
        guard !lines.isEmpty else {
            var result = ctx; result.layers[0] = withPhoto; return result
        }

        let textBlockH = lines.map { CGFloat($0.height) }.reduce(0, +)
            + textSpacing * CGFloat(lines.count - 1)
        let textBlockW = lines.map { CGFloat($0.width) }.max() ?? 0

        guard let textCtx = CGContextHelpers.createContext(width: Int(ceil(textBlockW)),
                                                           height: Int(ceil(textBlockH))) else {
            throw ProcessorError.cgContextCreationFailed
        }
        var ty: CGFloat = 0
        for line in lines {
            let lx = (textBlockW - CGFloat(line.width)) / 2
            CGContextHelpers.draw(line, in: textCtx,
                                  at: CGRect(x: lx, y: ty, width: CGFloat(line.width), height: CGFloat(line.height)))
            ty += CGFloat(line.height) + textSpacing
        }
        guard let textBlock = textCtx.makeImage() else {
            var result = ctx; result.layers[0] = withPhoto; return result
        }

        let bottomMargin = sh * 0.04
        let textX = (CGFloat(bgW) - CGFloat(textBlock.width)) / 2
        let textY = CGFloat(bgH) - CGFloat(textBlock.height) - bottomMargin

        guard let finalCtx = CGContextHelpers.createContext(width: bgW, height: bgH) else {
            throw ProcessorError.cgContextCreationFailed
        }
        CGContextHelpers.draw(withPhoto, in: finalCtx,
                              at: CGRect(x: 0, y: 0, width: CGFloat(bgW), height: CGFloat(bgH)))
        CGContextHelpers.draw(textBlock, in: finalCtx,
                              at: CGRect(x: textX, y: textY,
                                         width: CGFloat(textBlock.width),
                                         height: CGFloat(textBlock.height)))

        guard let final = finalCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers[0] = final
        return newCtx
    }

    // MARK: - Nikon model name: split at first "Z", color "Z" red

    private func renderModelLine(_ model: String?, fontSize: CGFloat, maxWidth: CGFloat) -> CGImage? {
        let text = model?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !text.isEmpty else { return nil }

        // Find first uppercase Z that looks like a series name (preceded by space or start)
        // e.g. "NIKON Z6" → "NIKON "(white) + "Z"(red) + "6"(white)
        if let zRange = firstSeriesZ(in: text) {
            let before = String(text[text.startIndex..<zRange.lowerBound])
            let after  = String(text[zRange.upperBound...])
            return renderSegments(
                segments: [(before, "#FFFFFF", true), ("Z", "#FF0000", true), (after, "#FFFFFF", true)],
                fontSize: fontSize,
                spacing: fontSize * 0.1,
                maxWidth: maxWidth
            )
        }

        // Fallback: whole model in white bold
        return RichTextProcessor().renderText(text, fontSize: fontSize,
                                              colorHex: "#FFFFFF", bold: true,
                                              maxWidth: maxWidth)
    }

    /// Returns the range of the first Z that looks like a Nikon Z-series designator.
    private func firstSeriesZ(in text: String) -> Range<String.Index>? {
        var idx = text.startIndex
        while idx < text.endIndex {
            if text[idx] == "Z" {
                let isAtStart   = idx == text.startIndex
                let prevIsSpace = !isAtStart && text[text.index(before: idx)] == " "
                if isAtStart || prevIsSpace {
                    return idx..<text.index(after: idx)
                }
            }
            idx = text.index(after: idx)
        }
        return nil
    }

    /// Renders multiple (text, colorHex, bold) segments side-by-side into a single CGImage.
    private func renderSegments(
        segments: [(String, String, Bool)],
        fontSize: CGFloat,
        spacing: CGFloat,
        maxWidth: CGFloat
    ) -> CGImage? {
        var segImages: [CGImage] = []
        for (text, colorHex, bold) in segments where !text.isEmpty {
            if let img = RichTextProcessor().renderText(text, fontSize: fontSize, colorHex: colorHex, bold: bold, maxWidth: maxWidth) {
                segImages.append(img)
            }
        }
        guard !segImages.isEmpty else { return nil }

        let totalW = segImages.map { CGFloat($0.width) }.reduce(0, +) + spacing * CGFloat(segImages.count - 1)
        let totalH = segImages.map { CGFloat($0.height) }.max() ?? fontSize * 1.5

        guard let ctx = CGContextHelpers.createContext(width: Int(ceil(totalW)), height: Int(ceil(totalH))) else { return nil }
        var x: CGFloat = 0
        for img in segImages {
            let iy = (totalH - CGFloat(img.height)) / 2
            CGContextHelpers.draw(img, in: ctx, at: CGRect(x: x, y: iy, width: CGFloat(img.width), height: CGFloat(img.height)))
            x += CGFloat(img.width) + spacing
        }
        return ctx.makeImage()
    }

    // MARK: - Params text

    private func buildParamsText(_ exif: ExifData, opts: ExifFieldOptions) -> String {
        var parts: [String] = []
        if opts.showFocalLength, let v = exif.focalLength { parts.append(v) }
        if opts.showAperture,   let v = exif.fNumber      { parts.append(v) }
        if opts.showShutter,    let v = exif.exposureTime { parts.append(v) }
        if opts.showISO,        let v = exif.iso          { parts.append(v) }
        return parts.joined(separator: "  ")
    }
}

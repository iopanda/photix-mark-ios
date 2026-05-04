import Foundation
import CoreGraphics

/// Full-fidelity port of the web's blurBackground template pipeline:
///
///  1. Blur source → scale up by `bg_scale` → blurred background canvas
///  2. Scale source down by `photo_scale` (0.88) → sharp foreground
///  3. Composite: sharp photo centered-top on blurred background
///  4. Render two text lines (camera model bold + shooting params) in white
///  5. Stack text lines vertically with spacing, overlay at bottom-center
///
/// stepConfig:
///   blur_radius  (Double fraction, default 0.05)
///   bg_scale     (Double multiplier, default 1.15)
///   photo_scale  (Double multiplier, default 0.88)
///   text_spacing (Double fraction of source height, default 0.02)
public struct BlurBackgroundCompositeProcessor: ImageProcessor {
    public let name = "blur_background_composite"
    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let blurFraction  = ctx.stepConfig["blur_radius"]?.doubleValue  ?? ctx.userOptions.blur?.radiusFraction ?? 0.05
        let bgScale       = CGFloat(ctx.stepConfig["bg_scale"]?.doubleValue   ?? 1.15)
        let photoScale    = CGFloat(ctx.stepConfig["photo_scale"]?.doubleValue ?? 0.88)
        let textSpacingFr = ctx.stepConfig["text_spacing"]?.doubleValue ?? 0.02

        let sw = CGFloat(source.width)
        let sh = CGFloat(source.height)
        let blurRadius = CGContextHelpers.resolve(blurFraction, reference: sh)
        let textSpacing = CGContextHelpers.resolve(textSpacingFr, reference: sh)

        // ── 1. Blurred background (source scaled up, then blurred) ──────────
        let bgW = Int(sw * bgScale)
        let bgH = Int(sh * bgScale)
        guard let bgCtx = CGContextHelpers.createContext(width: bgW, height: bgH) else {
            throw ProcessorError.cgContextCreationFailed
        }
        CGContextHelpers.draw(source, in: bgCtx, at: CGRect(x: 0, y: 0, width: CGFloat(bgW), height: CGFloat(bgH)))
        guard let bgRaw = bgCtx.makeImage(),
              let bgBlurred = CGContextHelpers.blur(bgRaw, radius: blurRadius) else {
            throw ProcessorError.cgContextCreationFailed
        }

        // ── 2. Sharp foreground (source scaled down) ─────────────────────────
        let fgW = Int(sw * photoScale)
        let fgH = Int(sh * photoScale)
        guard let fgCtx = CGContextHelpers.createContext(width: fgW, height: fgH) else {
            throw ProcessorError.cgContextCreationFailed
        }
        CGContextHelpers.draw(source, in: fgCtx, at: CGRect(x: 0, y: 0, width: CGFloat(fgW), height: CGFloat(fgH)))
        guard let foreground = fgCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }

        // ── 3. Composite: photo centered, slightly above center (web: weights [0,-5]) ──
        let photoOffsetY = sh * 0.03   // ~3% upward shift
        let photoX = (CGFloat(bgW) - CGFloat(fgW)) / 2
        let photoCenterY = (CGFloat(bgH) - CGFloat(fgH)) / 2 - photoOffsetY
        let photoY = max(0, photoCenterY)

        guard let compositeCtx = CGContextHelpers.createContext(width: bgW, height: bgH) else {
            throw ProcessorError.cgContextCreationFailed
        }
        CGContextHelpers.draw(bgBlurred, in: compositeCtx,
                              at: CGRect(x: 0, y: 0, width: CGFloat(bgW), height: CGFloat(bgH)))
        CGContextHelpers.draw(foreground, in: compositeCtx,
                              at: CGRect(x: photoX, y: photoY, width: CGFloat(fgW), height: CGFloat(fgH)))
        guard let withPhoto = compositeCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }

        // ── 4. Build text layers ──────────────────────────────────────────────
        let renderer = TemplateRenderer(exif: ctx.exif, customLogos: ctx.customLogos, exifFields: ctx.userOptions.exifFields)
        let richText = RichTextProcessor()

        let cameraText = buildCameraText(ctx.exif)
        let paramsText = buildParamsText(ctx.exif, opts: ctx.userOptions.exifFields)

        let line1FontSize = CGContextHelpers.resolve(0.04, reference: sh)
        let line2FontSize = CGContextHelpers.resolve(0.03, reference: sh)
        _ = renderer  // renderer available for future template expressions

        let line1 = richText.renderText(cameraText, fontSize: line1FontSize,
                                        colorHex: "#FFFFFF", bold: true,
                                        maxWidth: CGFloat(bgW) * 0.85)
        let line2 = paramsText.isEmpty ? nil :
            richText.renderText(paramsText, fontSize: line2FontSize,
                                colorHex: "#FFFFFF", bold: false,
                                maxWidth: CGFloat(bgW) * 0.85)

        // ── 5. Stack text vertically, overlay at bottom-center ───────────────
        let lines: [CGImage] = [line1, line2].compactMap { $0 }
        guard !lines.isEmpty else {
            var result = ctx
            result.layers[0] = withPhoto
            return result
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
            let lw = CGFloat(line.width)
            let lh = CGFloat(line.height)
            let tx = (textBlockW - lw) / 2
            CGContextHelpers.draw(line, in: textCtx,
                                  at: CGRect(x: tx, y: ty, width: lw, height: lh))
            ty += lh + textSpacing
        }
        guard let textBlock = textCtx.makeImage() else {
            var result = ctx
            result.layers[0] = withPhoto
            return result
        }

        // Overlay text block at bottom-center with small margin
        let bottomMargin = sh * 0.04
        let tx = (CGFloat(bgW) - CGFloat(textBlock.width)) / 2
        let textY = CGFloat(bgH) - CGFloat(textBlock.height) - bottomMargin

        guard let finalCtx = CGContextHelpers.createContext(width: bgW, height: bgH) else {
            throw ProcessorError.cgContextCreationFailed
        }
        CGContextHelpers.draw(withPhoto, in: finalCtx,
                              at: CGRect(x: 0, y: 0, width: CGFloat(bgW), height: CGFloat(bgH)))
        CGContextHelpers.draw(textBlock, in: finalCtx,
                              at: CGRect(x: tx, y: textY, width: CGFloat(textBlock.width), height: CGFloat(textBlock.height)))

        guard let final = finalCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers[0] = final
        return newCtx
    }

    // MARK: - Text helpers

    private func buildCameraText(_ exif: ExifData) -> String {
        let parts = [exif.make, exif.model].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }

    private func buildParamsText(_ exif: ExifData, opts: ExifFieldOptions) -> String {
        var parts: [String] = []
        if opts.showFocalLength, let v = exif.focalLength { parts.append(v) }
        if opts.showAperture,   let v = exif.fNumber      { parts.append(v) }
        if opts.showShutter,    let v = exif.exposureTime { parts.append(v) }
        if opts.showISO,        let v = exif.iso          { parts.append(v) }
        return parts.joined(separator: "  ")
    }
}

import Foundation
import CoreGraphics

/// Builds: [logo bar] + [source image] + [info bar] stacked vertically with white padding.
/// Mirrors web's centeredWatermark (顶部版式) and centeredWatermark2 (底部版式).
///
/// stepConfig:
///   logo_position  ("top" | "bottom", default "top")
///   padding        (Double fraction of source height, default 0.03)
///   bar_height     (Double fraction of source height, default 0.10)
///   logo_height    (Double fraction of bar_height, default 0.60)
///   font_size      (Double fraction of info bar height, default 0.22)
public struct CenteredLayoutProcessor: ImageProcessor {
    public let name = "centered_layout"
    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let sw = CGFloat(source.width)
        let sh = CGFloat(source.height)
        let paddingFrac  = ctx.stepConfig["padding"]?.doubleValue  ?? 0.03
        let barHeightFrac = ctx.stepConfig["bar_height"]?.doubleValue ?? 0.10
        let logoPosition = ctx.stepConfig["logo_position"]?.stringValue ?? "top"
        let fontSizeFrac  = ctx.stepConfig["font_size"]?.doubleValue ?? 0.22

        let padding  = CGContextHelpers.resolve(paddingFrac,   reference: sh)
        let logoBarH = CGContextHelpers.resolve(barHeightFrac, reference: sh)
        let infoBarH = logoBarH * 1.1
        let totalW   = sw + padding * 2
        let totalH   = padding * 2 + logoBarH + sh + infoBarH

        guard let canvas = CGContextHelpers.createContext(width: Int(totalW), height: Int(totalH)) else {
            throw ProcessorError.cgContextCreationFailed
        }
        canvas.setFillColor(CGContextHelpers.color(hex: "#FFFFFF"))
        canvas.fill(CGRect(x: 0, y: 0, width: totalW, height: totalH))

        // Y offsets (top-down)
        let logoBarY: CGFloat
        let photoY:   CGFloat
        let infoBarY: CGFloat
        if logoPosition == "bottom" {
            // source image first, then logo bar, then info bar
            photoY   = padding
            logoBarY = padding + sh
            infoBarY = padding + sh + logoBarH
        } else {
            logoBarY = padding
            photoY   = padding + logoBarH
            infoBarY = padding + logoBarH + sh
        }

        // Draw source image (with side padding)
        CGContextHelpers.draw(source, in: canvas,
                              at: CGRect(x: padding, y: photoY, width: sw, height: sh))

        // Logo bar (centered logo)
        let resolver = LogoResolver(customLogos: ctx.customLogos)
        if ctx.userOptions.logo.enabled, let logo = resolver.resolve(brand: ctx.exif.make) {
            let logoH    = logoBarH * 0.6
            let aspect   = CGFloat(logo.width) / max(CGFloat(logo.height), 1)
            let logoW    = logoH * aspect
            let logoX    = (totalW - logoW) / 2
            let logoBarCenterY = logoBarY + logoBarH / 2

            CGContextHelpers.draw(logo, in: canvas,
                                  at: CGRect(x: logoX, y: logoBarCenterY - logoH / 2,
                                             width: logoW, height: logoH))
        }

        return try finalizeWithInfo(
            canvas: canvas, ctx: ctx, sw: totalW, sh: totalH,
            infoBarY: infoBarY, infoBarH: infoBarH,
            fontSizeFrac: fontSizeFrac
        )
    }

    private func finalizeWithInfo(
        canvas: CGContext,
        ctx: ProcessorContext,
        sw: CGFloat, sh: CGFloat,
        infoBarY: CGFloat, infoBarH: CGFloat,
        fontSizeFrac: CGFloat
    ) throws -> ProcessorContext {
        guard let baseImage = canvas.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        guard let finalCtx = CGContextHelpers.createContext(width: Int(sw), height: Int(sh)) else {
            throw ProcessorError.cgContextCreationFailed
        }
        CGContextHelpers.draw(baseImage, in: finalCtx, at: CGRect(x: 0, y: 0, width: sw, height: sh))

        let fontSize       = infoBarH * fontSizeFrac
        let secFontSize    = fontSize * 0.85
        let cameraText     = buildCameraText(ctx.exif)
        let paramsText     = buildParams(ctx.exif, opts: ctx.userOptions.exifFields)
        let textColorHex   = ctx.userOptions.colors.textColorHex
        let secColorHex    = ctx.userOptions.colors.secondaryTextColorHex

        // Center camera text in the info bar (top-left convention for y)
        if !cameraText.isEmpty {
            let maxTW = sw * 0.85
            if let img = RichTextProcessor().renderText(cameraText, fontSize: fontSize, colorHex: textColorHex, bold: true, maxWidth: maxTW) {
                let lineH = infoBarH * 0.45
                let tx = (sw - CGFloat(img.width)) / 2
                let ty = infoBarY + (infoBarH - CGFloat(img.height)) / 2 - lineH * 0.3
                CGContextHelpers.draw(img, in: finalCtx, at: CGRect(x: tx, y: ty, width: CGFloat(img.width), height: CGFloat(img.height)))
            }
            if !paramsText.isEmpty {
                if let img2 = RichTextProcessor().renderText(paramsText, fontSize: secFontSize, colorHex: secColorHex, bold: false, maxWidth: sw * 0.85) {
                    let tx2 = (sw - CGFloat(img2.width)) / 2
                    let ty2 = infoBarY + infoBarH * 0.55
                    CGContextHelpers.draw(img2, in: finalCtx, at: CGRect(x: tx2, y: ty2, width: CGFloat(img2.width), height: CGFloat(img2.height)))
                }
            }
        }

        guard let result = finalCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers[0] = result
        return newCtx
    }

    private func buildCameraText(_ exif: ExifData) -> String {
        [exif.make, exif.model]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func buildParams(_ exif: ExifData, opts: ExifFieldOptions) -> String {
        var parts: [String] = []
        if opts.showFocalLength, let v = exif.focalLength { parts.append(v) }
        if opts.showAperture,   let v = exif.fNumber      { parts.append(v) }
        if opts.showShutter,    let v = exif.exposureTime { parts.append(v) }
        if opts.showISO,        let v = exif.iso          { parts.append(v) }
        return parts.joined(separator: "   ")
    }
}

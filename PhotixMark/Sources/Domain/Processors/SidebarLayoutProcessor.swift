import Foundation
import CoreGraphics

/// Left: source image. Right: white vertical sidebar with model, params, logo.
/// Mirrors web's sidebarWatermark (杂志版式). Outer white padding applied uniformly.
///
/// stepConfig:
///   padding       (Double fraction of source height, default 0.03)
///   sidebar_width (Double fraction of source height, default 0.13)  — matches web's 0.12–0.15
public struct SidebarLayoutProcessor: ImageProcessor {
    public let name = "sidebar_layout"
    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let sw = CGFloat(source.width)
        let sh = CGFloat(source.height)
        let paddingFrac = ctx.stepConfig["padding"]?.doubleValue     ?? 0.03
        let sidebarFrac = ctx.stepConfig["sidebar_width"]?.doubleValue ?? 0.13

        let padding  = CGContextHelpers.resolve(paddingFrac,  reference: sh)
        let sidebarW = CGContextHelpers.resolve(sidebarFrac,  reference: sh)
        let totalW   = padding * 2 + sw + sidebarW
        let totalH   = padding * 2 + sh

        guard let canvas = CGContextHelpers.createContext(width: Int(totalW), height: Int(totalH)) else {
            throw ProcessorError.cgContextCreationFailed
        }
        canvas.setFillColor(CGContextHelpers.color(hex: "#FFFFFF"))
        canvas.fill(CGRect(x: 0, y: 0, width: totalW, height: totalH))

        // Source image (left, with padding)
        CGContextHelpers.draw(source, in: canvas,
                              at: CGRect(x: padding, y: padding, width: sw, height: sh))

        // Sidebar content (right of image, inside padding)
        let sidebarX = padding + sw
        let sidebarY = padding

        // Thin vertical separator line between photo and sidebar.
        // In CGContext y-up, top of sidebar maps to: canvas.height - sidebarY
        // Bottom of sidebar maps to: canvas.height - (sidebarY + sh)
        let lineColor = CGContextHelpers.color(hex: "#E5E5E5")
        canvas.setStrokeColor(lineColor)
        canvas.setLineWidth(1)
        let cgBottom = CGFloat(canvas.height) - (sidebarY + sh)
        let cgTop    = CGFloat(canvas.height) - sidebarY
        canvas.move(to: CGPoint(x: sidebarX, y: cgBottom))
        canvas.addLine(to: CGPoint(x: sidebarX, y: cgTop))
        canvas.strokePath()

        let innerX   = sidebarX + sidebarW * 0.12
        let innerW   = sidebarW * 0.76
        let fontSize = sidebarW * 0.14
        let textColorHex = ctx.userOptions.colors.textColorHex
        let secColorHex  = ctx.userOptions.colors.secondaryTextColorHex

        // Model name (top-aligned, top-left y convention)
        var contentY = sidebarY + sh * 0.06
        let model = ctx.exif.model ?? ctx.exif.make ?? ""
        if !model.isEmpty {
            drawSidebarText(model, x: innerX, y: contentY, width: innerW,
                            fontSize: fontSize * 0.75, colorHex: textColorHex, bold: true,
                            into: canvas)
            contentY += fontSize * 1.2
        }

        // Divider (thin horizontal rule inside sidebar)
        contentY += sh * 0.03
        // In CGContext y-up, convert top-left y to bottom-left y:
        let dividerCGY = CGFloat(canvas.height) - contentY
        canvas.setStrokeColor(lineColor)
        canvas.setLineWidth(0.5)
        canvas.move(to: CGPoint(x: innerX, y: dividerCGY))
        canvas.addLine(to: CGPoint(x: innerX + innerW, y: dividerCGY))
        canvas.strokePath()
        contentY += sh * 0.03

        // Each param on its own line
        let params = buildParamPairs(ctx.exif, opts: ctx.userOptions.exifFields)
        for (value, unit) in params {
            drawSidebarParam(value: value, unit: unit, x: innerX, y: contentY,
                             width: innerW, fontSize: fontSize,
                             textColorHex: textColorHex, secColorHex: secColorHex,
                             into: canvas)
            contentY += fontSize * 2.0
        }

        // Logo at bottom of sidebar
        let resolver = LogoResolver(customLogos: ctx.customLogos)
        if ctx.userOptions.logo.enabled, let logo = resolver.resolve(brand: ctx.exif.make) {
            let logoH  = sidebarW * 0.28
            let aspect = CGFloat(logo.width) / max(CGFloat(logo.height), 1)
            let logoW  = min(logoH * aspect, innerW)
            let logoX  = innerX + (innerW - logoW) / 2
            let logoY  = sidebarY + sh - sh * 0.1 - logoH
            CGContextHelpers.draw(logo, in: canvas,
                                  at: CGRect(x: logoX, y: logoY, width: logoW, height: logoH))
        }

        guard let result = canvas.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers[0] = result
        return newCtx
    }

    private func drawSidebarText(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat,
                                  fontSize: CGFloat, colorHex: String, bold: Bool,
                                  into canvas: CGContext) {
        if let img = RichTextProcessor().renderText(text, fontSize: fontSize, colorHex: colorHex, bold: bold, maxWidth: width) {
            let iw = min(CGFloat(img.width), width)
            CGContextHelpers.draw(img, in: canvas, at: CGRect(x: x, y: y, width: iw, height: CGFloat(img.height)))
        }
    }

    private func drawSidebarParam(value: String, unit: String, x: CGFloat, y: CGFloat,
                                   width: CGFloat, fontSize: CGFloat,
                                   textColorHex: String, secColorHex: String,
                                   into canvas: CGContext) {
        var curX = x
        if let vImg = RichTextProcessor().renderText(value, fontSize: fontSize * 1.1, colorHex: textColorHex, bold: true, maxWidth: width) {
            CGContextHelpers.draw(vImg, in: canvas, at: CGRect(x: curX, y: y, width: CGFloat(vImg.width), height: CGFloat(vImg.height)))
            curX += CGFloat(vImg.width) + 2
        }
        if !unit.isEmpty,
           let uImg = RichTextProcessor().renderText(unit, fontSize: fontSize * 0.55, colorHex: secColorHex, bold: false, maxWidth: width - (curX - x)) {
            CGContextHelpers.draw(uImg, in: canvas, at: CGRect(x: curX, y: y + fontSize * 0.4, width: CGFloat(uImg.width), height: CGFloat(uImg.height)))
        }
    }

    private func buildParamPairs(_ exif: ExifData, opts: ExifFieldOptions) -> [(String, String)] {
        var result: [(String, String)] = []
        if opts.showFocalLength, let v = exif.focalLength {
            let parts = v.components(separatedBy: "mm")
            result.append((parts[0].trimmingCharacters(in: .whitespaces), "mm"))
        }
        if opts.showAperture, let v = exif.fNumber {
            result.append((v, ""))
        }
        if opts.showShutter, let v = exif.exposureTime {
            result.append((v, "s"))
        }
        if opts.showISO, let v = exif.iso {
            result.append((v, "ISO"))
        }
        return result
    }
}

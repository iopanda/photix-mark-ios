import Foundation
import CoreGraphics

/// The most complex processor — builds a structured watermark bar with flexible layout sections.
/// Mirrors web's flexLayout.ts.
/// stepConfig: sections ([{type, content}]), direction ("vertical"|"horizontal"),
///             bg_color, padding_fraction
public struct FlexLayoutProcessor: ImageProcessor {
    public let name = "flex_layout"

    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let renderer = TemplateRenderer(exif: ctx.exif, customLogos: ctx.customLogos, exifFields: ctx.userOptions.exifFields)
        let opts = ctx.userOptions
        let sourceW = CGFloat(source.width)
        let sourceH = CGFloat(source.height)

        let bgHex = ctx.stepConfig["bg_color"]?.stringValue ?? opts.background.backgroundColorHex
        let paddingFrac = ctx.stepConfig["padding_fraction"]?.doubleValue ?? opts.layout.paddingFraction
        let padding = CGContextHelpers.resolve(paddingFrac, reference: sourceH)

        // Build section images
        guard let sections = ctx.stepConfig["sections"]?.arrayValue, !sections.isEmpty else {
            return ctx
        }

        var sectionImages: [CGImage] = []
        for section in sections {
            guard let dict = section.dictValue else { continue }
            let type_ = dict["type"]?.stringValue ?? "text"
            if let img = buildSection(type_, config: dict, ctx: ctx, renderer: renderer,
                                      refWidth: sourceW, refHeight: sourceH, padding: padding) {
                sectionImages.append(img)
            }
        }

        guard !sectionImages.isEmpty else { return ctx }

        // Lay out sections horizontally inside a bar
        let barH = sectionImages.map { CGFloat($0.height) }.max().map { $0 + padding * 2 } ?? sourceH * 0.12
        let barW = sourceW

        guard let barCtx = CGContextHelpers.createContext(width: Int(barW), height: Int(barH)) else {
            throw ProcessorError.cgContextCreationFailed
        }
        barCtx.setFillColor(CGContextHelpers.color(hex: bgHex))
        barCtx.fill(CGRect(x: 0, y: 0, width: barW, height: barH))

        let sectionWidth = barW / CGFloat(sectionImages.count)
        for (i, img) in sectionImages.enumerated() {
            let iw = CGFloat(img.width)
            let ih = CGFloat(img.height)
            let sx = CGFloat(i) * sectionWidth + (sectionWidth - iw) / 2
            let sy = (barH - ih) / 2
            CGContextHelpers.draw(img, in: barCtx, at: CGRect(x: sx, y: sy, width: iw, height: ih))
        }

        guard let bar = barCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }

        // Stack source + bar
        let totalH = sourceH + barH
        guard let finalCtx = CGContextHelpers.createContext(width: Int(sourceW), height: Int(totalH)) else {
            throw ProcessorError.cgContextCreationFailed
        }
        CGContextHelpers.draw(source, in: finalCtx, at: CGRect(x: 0, y: 0, width: sourceW, height: sourceH))
        CGContextHelpers.draw(bar, in: finalCtx, at: CGRect(x: 0, y: sourceH, width: barW, height: barH))

        guard let result = finalCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers = [result]
        return newCtx
    }

    // MARK: - Section builders

    private func buildSection(
        _ type: String,
        config: [String: StepValue],
        ctx: ProcessorContext,
        renderer: TemplateRenderer,
        refWidth: CGFloat,
        refHeight: CGFloat,
        padding: CGFloat
    ) -> CGImage? {
        switch type {
        case "logo":
            return buildLogoSection(config: config, ctx: ctx, refHeight: refHeight)
        case "text_stack":
            return buildTextStackSection(config: config, ctx: ctx, renderer: renderer, refHeight: refHeight)
        default:
            return nil
        }
    }

    private func buildLogoSection(config: [String: StepValue], ctx: ProcessorContext, refHeight: CGFloat) -> CGImage? {
        let logoResolver = LogoResolver(customLogos: ctx.customLogos)
        guard let logo = logoResolver.resolve(brand: ctx.exif.make) else { return nil }

        let maxH = refHeight * 0.08
        let aspect = CGFloat(logo.width) / max(CGFloat(logo.height), 1)
        let targetH = maxH
        let targetW = targetH * aspect

        guard let imgCtx = CGContextHelpers.createContext(width: Int(targetW), height: Int(targetH)) else { return nil }
        CGContextHelpers.draw(logo, in: imgCtx, at: CGRect(x: 0, y: 0, width: targetW, height: targetH))
        return imgCtx.makeImage()
    }

    private func buildTextStackSection(
        config: [String: StepValue],
        ctx: ProcessorContext,
        renderer: TemplateRenderer,
        refHeight: CGFloat
    ) -> CGImage? {
        guard let lines = config["lines"]?.arrayValue else { return nil }

        let richText = RichTextProcessor()
        var renderedLines: [CGImage] = []

        for line in lines {
            guard let dict = line.dictValue,
                  let template = dict["text"]?.stringValue else { continue }
            let text = renderer.render(template)
            guard !text.isEmpty else { continue }

            let sizeFrac = dict["font_size"]?.doubleValue ?? 0.025
            let fontSize = CGContextHelpers.resolve(sizeFrac, reference: refHeight)
            let colorHex = dict["color"]?.stringValue ?? ctx.userOptions.colors.textColorHex
            let bold = dict["bold"]?.boolValue ?? false

            if let img = richText.renderText(text, fontSize: fontSize, colorHex: colorHex, bold: bold, maxWidth: refHeight * 2) {
                renderedLines.append(img)
            }
        }

        guard !renderedLines.isEmpty else { return nil }

        let maxW = renderedLines.map { CGFloat($0.width) }.max() ?? 0
        let totalH = renderedLines.map { CGFloat($0.height) }.reduce(0, +)

        guard let stackCtx = CGContextHelpers.createContext(width: Int(maxW), height: Int(totalH)) else { return nil }
        var y: CGFloat = 0
        for img in renderedLines {
            CGContextHelpers.draw(img, in: stackCtx, at: CGRect(x: 0, y: y, width: CGFloat(img.width), height: CGFloat(img.height)))
            y += CGFloat(img.height)
        }
        return stackCtx.makeImage()
    }
}

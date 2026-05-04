import Foundation
import CoreGraphics
import CoreText

/// Renders a single text string as a new image layer.
/// stepConfig: text (template string), font_size (Double, fraction of ref height),
///             color (hex), bold (Bool), align ("left"|"center"|"right")
public struct RichTextProcessor: ImageProcessor {
    public let name = "rich_text"

    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let renderer = TemplateRenderer(exif: ctx.exif, customLogos: ctx.customLogos, exifFields: ctx.userOptions.exifFields)
        let template = ctx.stepConfig["text"]?.stringValue ?? ""
        let text = renderer.render(template)
        guard !text.isEmpty else { return ctx }

        let refHeight = CGFloat(source.height)
        let sizeFrac = ctx.stepConfig["font_size"]?.doubleValue ?? 0.03
        let fontSize = CGContextHelpers.resolve(sizeFrac, reference: refHeight)
        let colorHex = ctx.stepConfig["color"]?.stringValue
            ?? ctx.userOptions.colors.textColorHex
        let isBold = ctx.stepConfig["bold"]?.boolValue ?? false

        let textImage = renderText(
            text,
            fontSize: fontSize,
            colorHex: colorHex,
            bold: isBold,
            maxWidth: CGFloat(source.width) * 0.9
        )

        var newCtx = ctx
        if let img = textImage {
            newCtx.layers.append(img)
        }
        return newCtx
    }

    internal func renderText(
        _ text: String,
        fontSize: CGFloat,
        colorHex: String,
        bold: Bool,
        maxWidth: CGFloat
    ) -> CGImage? {
        let font  = CGContextHelpers.ctFont(size: fontSize, bold: bold)
        let color = CGContextHelpers.color(hex: colorHex)
        return CGContextHelpers.renderText(text, font: font, color: color, maxWidth: maxWidth)
    }
}

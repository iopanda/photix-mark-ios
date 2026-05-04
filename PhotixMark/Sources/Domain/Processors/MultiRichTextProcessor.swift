import Foundation
import CoreGraphics

/// Renders multiple text segments side-by-side into a single image layer.
/// stepConfig: segments ([{text, color, bold, font_size}]), spacing (Double, fraction),
///             bg_color (hex)
public struct MultiRichTextProcessor: ImageProcessor {
    public let name = "multi_rich_text"

    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let renderer = TemplateRenderer(exif: ctx.exif, customLogos: ctx.customLogos, exifFields: ctx.userOptions.exifFields)
        let refHeight = CGFloat(source.height)

        guard let segmentsValue = ctx.stepConfig["segments"]?.arrayValue else { return ctx }

        let spacingFrac = ctx.stepConfig["spacing"]?.doubleValue ?? 0.01
        let spacing = CGContextHelpers.resolve(spacingFrac, reference: refHeight)
        let bgHex = ctx.stepConfig["bg_color"]?.stringValue
            ?? ctx.userOptions.background.backgroundColorHex

        struct Segment {
            let text: String
            let image: CGImage
        }

        let richText = RichTextProcessor()
        var segments: [Segment] = []

        for item in segmentsValue {
            guard let dict = item.dictValue else { continue }
            let template = dict["text"]?.stringValue ?? ""
            let text = renderer.render(template)
            guard !text.isEmpty else { continue }

            let sizeFrac = dict["font_size"]?.doubleValue ?? 0.03
            let fontSize = CGContextHelpers.resolve(sizeFrac, reference: refHeight)
            let colorHex = dict["color"]?.stringValue ?? ctx.userOptions.colors.textColorHex
            let bold = dict["bold"]?.boolValue ?? false

            if let img = richText.renderText(text, fontSize: fontSize, colorHex: colorHex, bold: bold, maxWidth: CGFloat(source.width)) {
                segments.append(Segment(text: text, image: img))
            }
        }

        guard !segments.isEmpty else { return ctx }

        let totalW = segments.map { CGFloat($0.image.width) }.reduce(0, +) + spacing * CGFloat(segments.count - 1)
        let maxH = segments.map { CGFloat($0.image.height) }.max() ?? 0

        guard let cgCtx = CGContextHelpers.createContext(width: Int(ceil(totalW)), height: Int(ceil(maxH))) else {
            throw ProcessorError.cgContextCreationFailed
        }

        cgCtx.setFillColor(CGContextHelpers.color(hex: bgHex))
        cgCtx.fill(CGRect(x: 0, y: 0, width: Int(ceil(totalW)), height: Int(ceil(maxH))))

        var x: CGFloat = 0
        for seg in segments {
            let iw = CGFloat(seg.image.width)
            let ih = CGFloat(seg.image.height)
            let iy = (maxH - ih) / 2
            CGContextHelpers.draw(seg.image, in: cgCtx, at: CGRect(x: x, y: iy, width: iw, height: ih))
            x += iw + spacing
        }

        guard let result = cgCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers.append(result)
        return newCtx
    }
}

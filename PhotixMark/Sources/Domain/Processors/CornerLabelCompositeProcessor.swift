import Foundation
import CoreGraphics

/// Overlays datetime + shooting params as white text at the bottom-right corner
/// of the source image. No extra bar is appended.
/// Mirrors web's folderNameParams template (极简角标).
public struct CornerLabelCompositeProcessor: ImageProcessor {
    public let name = "corner_label_composite"
    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard let source = ctx.layers.first else { throw ProcessorError.invalidLayer }

        let sw = CGFloat(source.width)
        let sh = CGFloat(source.height)
        let marginX = sw * 0.04
        let marginY = sh * 0.03
        let fontSize = CGContextHelpers.resolve(0.025, reference: sh)

        let datetime = ctx.exif.dateTimeOriginal ?? ""
        let params   = buildParams(ctx.exif, opts: ctx.userOptions.exifFields)
        let lines    = [datetime, params].filter { !$0.isEmpty }
        guard !lines.isEmpty else { return ctx }

        let richText = RichTextProcessor()
        let maxW     = sw * 0.6
        let lineImages = lines.compactMap {
            richText.renderText($0, fontSize: fontSize, colorHex: "#FFFFFF", bold: false, maxWidth: maxW)
        }
        guard !lineImages.isEmpty else { return ctx }

        let lineSpacing = fontSize * 0.3
        let blockH = lineImages.map { CGFloat($0.height) }.reduce(0, +)
            + lineSpacing * CGFloat(lineImages.count - 1)

        guard let finalCtx = CGContextHelpers.createContext(width: Int(sw), height: Int(sh)) else {
            throw ProcessorError.cgContextCreationFailed
        }
        CGContextHelpers.draw(source, in: finalCtx,
                              at: CGRect(x: 0, y: 0, width: sw, height: sh))

        var ty = sh - blockH - marginY
        for img in lineImages {
            let ix = sw - CGFloat(img.width) - marginX
            CGContextHelpers.draw(img, in: finalCtx,
                                  at: CGRect(x: ix, y: ty, width: CGFloat(img.width), height: CGFloat(img.height)))
            ty += CGFloat(img.height) + lineSpacing
        }

        guard let result = finalCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        var newCtx = ctx
        newCtx.layers[0] = result
        return newCtx
    }

    private func buildParams(_ exif: ExifData, opts: ExifFieldOptions) -> String {
        var parts: [String] = []
        if opts.showFocalLength, let v = exif.focalLength { parts.append(v) }
        if opts.showAperture,   let v = exif.fNumber      { parts.append(v) }
        if opts.showShutter,    let v = exif.exposureTime { parts.append(v) }
        if opts.showISO,        let v = exif.iso          { parts.append(v) }
        return parts.joined(separator: "  ")
    }
}

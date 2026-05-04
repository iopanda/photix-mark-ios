import Foundation
import CoreGraphics

/// Concatenates all layers vertically (default) or horizontally.
/// stepConfig: direction ("vertical" | "horizontal"), bg_color (String hex), layer_indices ([Int])
public struct ConcatProcessor: ImageProcessor {
    public let name = "concat"

    public init() {}

    public func process(_ ctx: ProcessorContext) async throws -> ProcessorContext {
        guard ctx.layers.count > 1 else { return ctx }

        let direction = ctx.stepConfig["direction"]?.stringValue ?? "vertical"
        let bgHex = ctx.stepConfig["bg_color"]?.stringValue
            ?? ctx.userOptions.background.backgroundColorHex

        let indices: [Int]
        if let arr = ctx.stepConfig["layer_indices"]?.arrayValue {
            indices = arr.compactMap { $0.doubleValue.map { Int($0) } }
        } else {
            indices = Array(0..<ctx.layers.count)
        }

        let layers = indices.compactMap { ctx.layers[safe: $0] }
        guard !layers.isEmpty else { return ctx }

        let merged: CGImage
        if direction == "horizontal" {
            merged = try concatenateHorizontal(layers, bgHex: bgHex)
        } else {
            merged = try concatenateVertical(layers, bgHex: bgHex)
        }

        var newCtx = ctx
        newCtx.layers = [merged]
        return newCtx
    }

    private func concatenateVertical(_ layers: [CGImage], bgHex: String) throws -> CGImage {
        let totalW = layers.map { $0.width }.max() ?? 0
        let totalH = layers.map { $0.height }.reduce(0, +)

        guard let cgCtx = CGContextHelpers.createContext(width: totalW, height: totalH) else {
            throw ProcessorError.cgContextCreationFailed
        }

        cgCtx.setFillColor(CGContextHelpers.color(hex: bgHex))
        cgCtx.fill(CGRect(x: 0, y: 0, width: totalW, height: totalH))

        var y: CGFloat = 0
        for layer in layers {
            CGContextHelpers.draw(layer, in: cgCtx, at: CGRect(x: 0, y: y, width: CGFloat(layer.width), height: CGFloat(layer.height)))
            y += CGFloat(layer.height)
        }

        guard let result = cgCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        return result
    }

    private func concatenateHorizontal(_ layers: [CGImage], bgHex: String) throws -> CGImage {
        let totalW = layers.map { $0.width }.reduce(0, +)
        let totalH = layers.map { $0.height }.max() ?? 0

        guard let cgCtx = CGContextHelpers.createContext(width: totalW, height: totalH) else {
            throw ProcessorError.cgContextCreationFailed
        }

        cgCtx.setFillColor(CGContextHelpers.color(hex: bgHex))
        cgCtx.fill(CGRect(x: 0, y: 0, width: totalW, height: totalH))

        var x: CGFloat = 0
        for layer in layers {
            CGContextHelpers.draw(layer, in: cgCtx, at: CGRect(x: x, y: 0, width: CGFloat(layer.width), height: CGFloat(layer.height)))
            x += CGFloat(layer.width)
        }

        guard let result = cgCtx.makeImage() else { throw ProcessorError.cgContextCreationFailed }
        return result
    }
}

// MARK: - Collection safe subscript
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

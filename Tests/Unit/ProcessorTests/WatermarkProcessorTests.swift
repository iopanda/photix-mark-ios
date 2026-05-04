import XCTest
import CoreGraphics
@testable import PhotixMark

final class WatermarkProcessorTests: XCTestCase {

    private func makeTestImage(width: Int = 400, height: Int = 300) -> CGImage {
        let ctx = CGContextHelpers.createContext(width: width, height: height)!
        ctx.setFillColor(CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()!
    }

    func test_watermark_outputTallerThanInput() async throws {
        let image = makeTestImage()
        let exif = ExifData(make: "Sony", model: "A7 IV", lensModel: "FE 50mm F1.8",
                            focalLength: "50mm", fNumber: "f/1.8",
                            exposureTime: "1/125s", iso: "ISO 200",
                            dateTimeOriginal: "2024/01/15 10:30")
        let ctx = ProcessorContext(sourceImage: image, exif: exif, userOptions: TemplateUserOptions())
        let processor = WatermarkProcessor()
        let result = try await processor.process(ctx)

        let out = result.layers[0]
        XCTAssertEqual(out.width, 400)
        XCTAssertGreaterThan(out.height, 300, "Watermark bar should make image taller")
    }

    func test_watermark_widthPreserved() async throws {
        let image = makeTestImage(width: 600, height: 400)
        let ctx = ProcessorContext(sourceImage: image, exif: .empty, userOptions: TemplateUserOptions())
        let processor = WatermarkProcessor()
        let result = try await processor.process(ctx)
        XCTAssertEqual(result.layers[0].width, 600)
    }
}

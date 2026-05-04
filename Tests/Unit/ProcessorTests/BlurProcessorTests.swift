import XCTest
import CoreGraphics
@testable import PhotixMark

final class BlurProcessorTests: XCTestCase {

    private func makeTestImage(width: Int = 100, height: Int = 100) -> CGImage {
        let ctx = CGContextHelpers.createContext(width: width, height: height)!
        ctx.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()!
    }

    func test_blur_outputSameSize() async throws {
        let image = makeTestImage(width: 200, height: 150)
        let ctx = ProcessorContext(
            sourceImage: image,
            exif: .empty,
            userOptions: TemplateUserOptions()
        )
        let processor = BlurProcessor()
        let result = try await processor.process(ctx)
        XCTAssertEqual(result.layers[0].width, 200)
        XCTAssertEqual(result.layers[0].height, 150)
    }

    func test_blur_zeroRadius_returnsOriginal() async throws {
        let image = makeTestImage()
        var ctx = ProcessorContext(sourceImage: image, exif: .empty, userOptions: TemplateUserOptions())
        ctx.stepConfig["blur_radius"] = .double(0)
        let processor = BlurProcessor()
        let result = try await processor.process(ctx)
        XCTAssertEqual(result.layers.count, 1)
    }
}

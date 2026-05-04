import XCTest
@testable import PhotixMark

final class TemplateRendererTests: XCTestCase {

    private func makeRenderer(exif: ExifData = .empty) -> TemplateRenderer {
        TemplateRenderer(exif: exif)
    }

    // MARK: - Basic variable resolution

    func test_render_make() {
        let exif = ExifData(make: "Sony")
        let r = makeRenderer(exif: exif)
        XCTAssertEqual(r.render("{{make}}"), "Sony")
    }

    func test_render_model() {
        let exif = ExifData(model: "A7 IV")
        let r = makeRenderer(exif: exif)
        XCTAssertEqual(r.render("{{model}}"), "A7 IV")
    }

    func test_render_missingVariable_returnsEmpty() {
        let r = makeRenderer()
        XCTAssertEqual(r.render("{{make}}"), "")
    }

    // MARK: - Default filter

    func test_render_defaultFilter_usedWhenNil() {
        let r = makeRenderer()
        XCTAssertEqual(r.render("{{make|default(\"Unknown\")}}"), "Unknown")
    }

    func test_render_defaultFilter_notUsedWhenPresent() {
        let exif = ExifData(make: "Nikon")
        let r = makeRenderer(exif: exif)
        XCTAssertEqual(r.render("{{make|default(\"Unknown\")}}"), "Nikon")
    }

    // MARK: - Multiple variables in one template

    func test_render_multiple() {
        let exif = ExifData(focalLength: "50mm", fNumber: "f/1.8", exposureTime: "1/125s", iso: "ISO 200")
        let r = makeRenderer(exif: exif)
        let result = r.render("{{focalLength}}  {{fNumber}}  {{exposureTime}}  {{iso}}")
        XCTAssertEqual(result, "50mm  f/1.8  1/125s  ISO 200")
    }

    // MARK: - Logo filter

    func test_isLogoExpression() {
        XCTAssertTrue(TemplateRenderer.isLogoExpression("{{make|logo}}"))
        XCTAssertFalse(TemplateRenderer.isLogoExpression("{{make}}"))
    }

    func test_resolveLogoBrand() {
        let exif = ExifData(make: "Sony")
        let r = makeRenderer(exif: exif)
        XCTAssertEqual(r.resolveLogoBrand("{{make|logo}}"), "sony")
    }
}

import XCTest
@testable import PhotixMark

final class ExifNormalizerTests: XCTestCase {

    // MARK: - formatShutter

    func test_formatShutter_subSecond() {
        XCTAssertEqual(ExifNormalizer.formatShutter(1.0 / 125.0), "1/125s")
    }

    func test_formatShutter_oneSecond() {
        XCTAssertEqual(ExifNormalizer.formatShutter(1.0), "1s")
    }

    func test_formatShutter_30seconds() {
        XCTAssertEqual(ExifNormalizer.formatShutter(30.0), "30s")
    }

    func test_formatShutter_halfSecond() {
        XCTAssertEqual(ExifNormalizer.formatShutter(0.5), "1/2s")
    }

    // MARK: - formatFNumber

    func test_formatFNumber_integer() {
        XCTAssertEqual(ExifNormalizer.formatFNumber(11.0), "f/11")
    }

    func test_formatFNumber_decimal() {
        XCTAssertEqual(ExifNormalizer.formatFNumber(2.8), "f/2.8")
    }

    func test_formatFNumber_single() {
        XCTAssertEqual(ExifNormalizer.formatFNumber(1.4), "f/1.4")
    }

    // MARK: - formatFocalLength

    func test_formatFocalLength_integer() {
        XCTAssertEqual(ExifNormalizer.formatFocalLength(50.0), "50mm")
    }

    func test_formatFocalLength_decimal() {
        XCTAssertEqual(ExifNormalizer.formatFocalLength(35.5), "35.5mm")
    }

    // MARK: - formatDateTime

    func test_formatDateTime_standard() {
        let result = ExifNormalizer.formatDateTime("2024:01:15 10:30:00")
        XCTAssertEqual(result, "2024/01/15 10:30")
    }

    func test_formatDateTime_malformed_passthrough() {
        let raw = "not-a-date"
        XCTAssertEqual(ExifNormalizer.formatDateTime(raw), raw)
    }

    // MARK: - ExifData merging

    func test_exifData_merging_overridesWin() {
        let base = ExifData(make: "Sony", model: "A7 IV", iso: "ISO 100")
        let overrides = ExifData(model: "A7R V")
        let merged = base.merging(overrides)
        XCTAssertEqual(merged.make, "Sony")
        XCTAssertEqual(merged.model, "A7R V")
        XCTAssertEqual(merged.iso, "ISO 100")
    }

    func test_exifData_merging_nilOverrideKeepsBase() {
        let base = ExifData(make: "Canon")
        let overrides = ExifData(make: nil)
        let merged = base.merging(overrides)
        XCTAssertEqual(merged.make, "Canon")
    }
}

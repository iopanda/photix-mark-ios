import Foundation
import ImageIO

/// Ports the EXIF normalization logic from the web's exif.ts and useExif.ts.
public struct ExifNormalizer {

    // MARK: - Public API

    public static func normalize(raw: [String: Any]) -> ExifData {
        let tiff = raw[kCGImagePropertyTIFFDictionary as String] as? [String: Any] ?? [:]
        let exif = raw[kCGImagePropertyExifDictionary as String] as? [String: Any] ?? [:]

        let make = (tiff[kCGImagePropertyTIFFMake as String] as? String).map { cleanMakeString($0) }
        let model = tiff[kCGImagePropertyTIFFModel as String] as? String
        let lensModel = exif[kCGImagePropertyExifLensModel as String] as? String

        let focalLength: String?
        if let fl = exif[kCGImagePropertyExifFocalLength as String] as? Double {
            focalLength = formatFocalLength(fl)
        } else {
            focalLength = nil
        }

        let fNumber: String?
        if let fn = exif[kCGImagePropertyExifFNumber as String] as? Double {
            fNumber = formatFNumber(fn)
        } else {
            fNumber = nil
        }

        let exposureTime: String?
        if let et = exif[kCGImagePropertyExifExposureTime as String] as? Double {
            exposureTime = formatShutter(et)
        } else {
            exposureTime = nil
        }

        let iso: String?
        if let isoRatings = exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int],
           let firstISO = isoRatings.first {
            iso = "ISO \(firstISO)"
        } else if let isoValue = exif[kCGImagePropertyExifISOSpeedRatings as String] as? Int {
            iso = "ISO \(isoValue)"
        } else {
            iso = nil
        }

        let dateTimeOriginal: String?
        if let rawDate = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            dateTimeOriginal = formatDateTime(rawDate)
        } else {
            dateTimeOriginal = nil
        }

        return ExifData(
            make: make,
            model: model,
            lensModel: lensModel,
            focalLength: focalLength,
            fNumber: fNumber,
            exposureTime: exposureTime,
            iso: iso,
            dateTimeOriginal: dateTimeOriginal
        )
    }

    // MARK: - Formatters

    /// "1/125s", "1s", "30s"
    public static func formatShutter(_ seconds: Double) -> String {
        if seconds >= 1 {
            let rounded = Int(seconds.rounded())
            return "\(rounded)s"
        }
        let denominator = Int((1.0 / seconds).rounded())
        return "1/\(denominator)s"
    }

    /// "f/2.8", "f/11"
    public static func formatFNumber(_ value: Double) -> String {
        if value == value.rounded() {
            return "f/\(Int(value))"
        }
        return String(format: "f/%.1f", value)
    }

    /// "35mm", "50.0mm" → "50mm"
    public static func formatFocalLength(_ mm: Double) -> String {
        if mm == mm.rounded() {
            return "\(Int(mm))mm"
        }
        return String(format: "%.1fmm", mm)
    }

    /// "2024:01:15 10:30:00" → "2024/01/15 10:30"
    public static func formatDateTime(_ raw: String) -> String {
        let parts = raw.components(separatedBy: " ")
        guard parts.count >= 2 else { return raw }
        let datePart = parts[0].replacingOccurrences(of: ":", with: "/")
        let timePart = String(parts[1].prefix(5))
        return "\(datePart) \(timePart)"
    }

    // MARK: - Private helpers

    private static func cleanMakeString(_ make: String) -> String {
        make.trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
}

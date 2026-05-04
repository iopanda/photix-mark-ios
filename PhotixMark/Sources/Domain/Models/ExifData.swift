import Foundation

public struct ExifData: Codable, Equatable, Sendable {
    public var make: String?
    public var model: String?
    public var lensModel: String?
    public var focalLength: String?
    public var fNumber: String?
    public var exposureTime: String?
    public var iso: String?
    public var dateTimeOriginal: String?

    public init(
        make: String? = nil,
        model: String? = nil,
        lensModel: String? = nil,
        focalLength: String? = nil,
        fNumber: String? = nil,
        exposureTime: String? = nil,
        iso: String? = nil,
        dateTimeOriginal: String? = nil
    ) {
        self.make = make
        self.model = model
        self.lensModel = lensModel
        self.focalLength = focalLength
        self.fNumber = fNumber
        self.exposureTime = exposureTime
        self.iso = iso
        self.dateTimeOriginal = dateTimeOriginal
    }

    public static let empty = ExifData()

    /// Returns a new ExifData where non-nil fields in `overrides` win.
    public func merging(_ overrides: ExifData) -> ExifData {
        ExifData(
            make: overrides.make ?? make,
            model: overrides.model ?? model,
            lensModel: overrides.lensModel ?? lensModel,
            focalLength: overrides.focalLength ?? focalLength,
            fNumber: overrides.fNumber ?? fNumber,
            exposureTime: overrides.exposureTime ?? exposureTime,
            iso: overrides.iso ?? iso,
            dateTimeOriginal: overrides.dateTimeOriginal ?? dateTimeOriginal
        )
    }
}

public enum ExifField: String, CaseIterable, Identifiable {
    case make, model, lensModel, focalLength, fNumber, exposureTime, iso, dateTimeOriginal

    public var id: String { rawValue }

    public var displayLabel: String {
        switch self {
        case .make: return "Brand"
        case .model: return "Model"
        case .lensModel: return "Lens"
        case .focalLength: return "Focal Length"
        case .fNumber: return "Aperture"
        case .exposureTime: return "Shutter"
        case .iso: return "ISO"
        case .dateTimeOriginal: return "Date / Time"
        }
    }

    public func value(from exif: ExifData) -> String? {
        switch self {
        case .make: return exif.make
        case .model: return exif.model
        case .lensModel: return exif.lensModel
        case .focalLength: return exif.focalLength
        case .fNumber: return exif.fNumber
        case .exposureTime: return exif.exposureTime
        case .iso: return exif.iso
        case .dateTimeOriginal: return exif.dateTimeOriginal
        }
    }

    public func applying(_ value: String?, to exif: inout ExifData) {
        let trimmed = value.flatMap { $0.isEmpty ? nil : $0 }
        switch self {
        case .make: exif.make = trimmed
        case .model: exif.model = trimmed
        case .lensModel: exif.lensModel = trimmed
        case .focalLength: exif.focalLength = trimmed
        case .fNumber: exif.fNumber = trimmed
        case .exposureTime: exif.exposureTime = trimmed
        case .iso: exif.iso = trimmed
        case .dateTimeOriginal: exif.dateTimeOriginal = trimmed
        }
    }
}

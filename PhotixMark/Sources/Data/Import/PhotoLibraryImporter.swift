#if os(iOS)
import Foundation
import Photos
import PhotosUI
import CoreGraphics
import ImageIO

// MARK: - PHPickerResult → PhotoItem conversion

public struct PhotoLibraryImporter {

    /// Max dimension (pixels) for the in-memory working copy.
    /// 2048px is sufficient for watermarking while keeping each image ~16 MB (vs ~64 MB at 4096px).
    static let maxDimension: Int = 2048

    public init() {}

    /// Loads PhotoItems + EXIF from PHPickerResults.
    public func load(_ results: [PHPickerResult]) async -> [(item: PhotoItem, exif: ExifData)] {
        var output: [(PhotoItem, ExifData)] = []
        for result in results {
            if let loaded = await load(result) {
                output.append(loaded)
            }
        }
        return output
    }

    private func load(_ result: PHPickerResult) async -> (PhotoItem, ExifData)? {
        let provider = result.itemProvider
        let typeIdentifier = "public.image"
        guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else { return nil }

        // Load raw image data once — used for both EXIF extraction and decoding.
        // This avoids a second full download that PHAssetResourceManager would otherwise trigger.
        let rawData = await withCheckedContinuation { (cont: CheckedContinuation<Data?, Never>) in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                cont.resume(returning: data)
            }
        }

        guard let data = rawData,
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        // Decode at capped resolution to keep memory bounded (~64 MB per image at 4096px)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,   // applies EXIF orientation
            kCGImageSourceThumbnailMaxPixelSize: Self.maxDimension
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        // Extract EXIF from the same source — no second download needed
        let exif = ExifNormalizer.normalize(raw: (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]) ?? [:])

        let filename = provider.suggestedName.map { "\($0).jpg" } ?? "photo_\(UUID().uuidString).jpg"
        let item = PhotoItem(cgImage: cgImage, originalFilename: filename)
        return (item, exif)
    }
}
#endif

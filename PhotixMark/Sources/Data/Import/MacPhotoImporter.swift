#if os(macOS)
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public struct MacPhotoImporter {

    static let maxDimension: Int = 2048

    public init() {}

    /// Opens NSOpenPanel and returns selected file URLs.
    @MainActor
    public func pickFiles() async -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.jpeg, .png, .heic, .tiff, .rawImage, .image]
        panel.title = "Select Photos"
        let response = await panel.begin()
        guard response == .OK else { return [] }
        return panel.urls
    }

    /// Loads PhotoItems + EXIF from file URLs.
    public func load(_ urls: [URL]) async -> [(item: PhotoItem, exif: ExifData)] {
        var output: [(PhotoItem, ExifData)] = []
        for url in urls {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { continue }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: Self.maxDimension
            ]
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { continue }
            let raw = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] ?? [:]
            let exif = ExifNormalizer.normalize(raw: raw)
            let item = PhotoItem(cgImage: cgImage, originalFilename: url.lastPathComponent)
            output.append((item, exif))
        }
        return output
    }
}
#endif

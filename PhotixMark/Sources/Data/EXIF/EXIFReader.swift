import Foundation
import ImageIO
#if os(iOS)
import Photos
#endif

public struct EXIFReader {

    public init() {}

    // MARK: - Read from URL (file-based import, JPG/PNG)

    public func read(from url: URL) async -> ExifData {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return .empty }
        return extractExif(from: source)
    }

    // MARK: - Read from Data (e.g., HEIC loaded via PHImageManager)

    public func read(from data: Data) async -> ExifData {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return .empty }
        return extractExif(from: source)
    }

    #if os(iOS)
    // MARK: - Read from PHAsset

    public func read(from asset: PHAsset) async -> ExifData {
        guard let resource = PHAssetResource.assetResources(for: asset).first else { return .empty }
        return await withCheckedContinuation { continuation in
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            var data = Data()
            PHAssetResourceManager.default().requestData(for: resource, options: options) { chunk in
                data.append(chunk)
            } completionHandler: { error in
                if error != nil {
                    continuation.resume(returning: .empty)
                    return
                }
                guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                    continuation.resume(returning: .empty)
                    return
                }
                continuation.resume(returning: self.extractExif(from: source))
            }
        }
    }
    #endif

    // MARK: - Private

    private func extractExif(from source: CGImageSource) -> ExifData {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return .empty
        }
        return ExifNormalizer.normalize(raw: props)
    }
}

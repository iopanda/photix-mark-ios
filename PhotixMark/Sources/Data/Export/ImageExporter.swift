import Foundation
import CoreGraphics
import ImageIO
#if os(iOS)
import Photos
import UIKit
#endif

public struct ImageExporter {

    public init() {}

    /// Converts a CGImage to JPEG Data at the given quality (0.0–1.0).
    public static func jpegData(from image: CGImage, quality: CGFloat = 0.98) -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            data, "public.jpeg" as CFString, 1, nil
        ) else { return nil }
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(dest, image, options as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }

    #if os(iOS)
    public enum ExportError: Error, LocalizedError {
        case authorizationDenied
        case saveFailed(Error)

        public var errorDescription: String? {
            switch self {
            case .authorizationDenied: return "Photo library access is required to save images."
            case .saveFailed(let e): return "Failed to save image: \(e.localizedDescription)"
            }
        }
    }

    /// Saves one or more JPEG blobs to the photo library.
    public func saveToPhotoLibrary(_ items: [ProcessedResult]) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ExportError.authorizationDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            for item in items {
                guard let uiImage = UIImage(data: item.jpegData) else { continue }
                PHAssetCreationRequest.creationRequestForAsset(from: uiImage)
            }
        }
    }
    #endif
}

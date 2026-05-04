import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public struct ProcessedResult: Sendable {
    public let id: UUID
    public let jpegData: Data
    public let originalFilename: String

    public init(id: UUID, jpegData: Data, originalFilename: String) {
        self.id = id
        self.jpegData = jpegData
        self.originalFilename = originalFilename
    }
}

public struct BatchProgress: Sendable {
    public let completed: Int
    public let total: Int
    public var fraction: Double { Double(completed) / max(Double(total), 1) }
}

public actor BatchProcessingService {
    public static let shared = BatchProcessingService()
    private init() {}

    public func processBatch(
        items: [(id: UUID, image: CGImage, exif: ExifData, filename: String, template: TemplateConfig, userOptions: TemplateUserOptions)],
        customLogos: [String: Data] = [:]
    ) -> AsyncThrowingStream<(BatchProgress, ProcessedResult?), Error> {
        AsyncThrowingStream { continuation in
            Task {
                let total = items.count
                var completed = 0
                for item in items {
                    do {
                        let result = try await ImageProcessingService.shared.runPipelineForTemplate(
                            source: item.image,
                            exif: item.exif,
                            userOptions: item.userOptions,
                            template: item.template,
                            customLogos: customLogos
                        )
                        let jpegData = cgImageToJPEGData(result, quality: 0.92) ?? Data()
                        let processed = ProcessedResult(
                            id: item.id,
                            jpegData: jpegData,
                            originalFilename: item.filename
                        )
                        completed += 1
                        let progress = BatchProgress(completed: completed, total: total)
                        continuation.yield((progress, processed))
                    } catch {
                        continuation.finish(throwing: error)
                        return
                    }
                }
                continuation.finish()
            }
        }
    }

    private func cgImageToJPEGData(_ image: CGImage, quality: CGFloat) -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil) else {
            return nil
        }
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(dest, image, options as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }
}

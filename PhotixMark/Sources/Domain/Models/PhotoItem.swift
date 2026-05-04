import Foundation
import CoreGraphics

public struct PhotoItem: Identifiable, Sendable {
    public let id: UUID
    public let cgImage: CGImage
    public let originalFilename: String

    public init(id: UUID = UUID(), cgImage: CGImage, originalFilename: String) {
        self.id = id
        self.cgImage = cgImage
        self.originalFilename = originalFilename
    }
}

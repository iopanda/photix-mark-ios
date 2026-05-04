import Foundation

public struct BrandLogo: Identifiable, Sendable {
    public let id: UUID
    public var brand: String
    public var imageData: Data

    public init(id: UUID = UUID(), brand: String, imageData: Data) {
        self.id = id
        self.brand = brand
        self.imageData = imageData
    }
}

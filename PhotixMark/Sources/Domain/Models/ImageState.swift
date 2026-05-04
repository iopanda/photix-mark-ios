import Foundation

public struct ImageState: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var templateId: String
    public var userOptions: TemplateUserOptions
    public var exifOverrides: ExifData

    public init(
        id: UUID = UUID(),
        templateId: String = "noProcess",
        userOptions: TemplateUserOptions = TemplateUserOptions(),
        exifOverrides: ExifData = .empty
    ) {
        self.id = id
        self.templateId = templateId
        self.userOptions = userOptions
        self.exifOverrides = exifOverrides
    }
}

import Foundation

public struct NoProcessTemplate {
    public static let config = TemplateConfig(
        id: "noProcess",
        name: "Original",
        description: "Output the original photo without any modifications",
        previewAssetName: nil,
        processors: .fixed([]),
        defaultOptions: TemplateUserOptions()
    )
}

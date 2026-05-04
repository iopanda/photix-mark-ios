import Foundation

public struct Standard1Template {
    public static let config = TemplateConfig(
        id: "standard1",
        name: "Classic",
        description: "Four-corner watermark: camera + lens on the left, params + date on the right, brand logo on the far right",
        previewAssetName: "template_standard1",
        processors: .fixed([
            ProcessorStep(processorName: "watermark", stepConfig: [
                "left_top": .dict(["text": .string("{{model|default(\"Unknown Camera\")}}")]),
                "left_bottom": .dict(["text": .string("{{lensModel|default(\"\")}}")]),
                "right_top": .dict(["text": .string("{{focalLength}}  {{fNumber}}  {{exposureTime}}  {{iso}}")]),
                "right_bottom": .dict(["text": .string("{{dateTimeOriginal|default(\"\")}}")]),
                "logo_enabled": .bool(true)
            ])
        ]),
        defaultOptions: TemplateUserOptions(
            exifFields: ExifFieldOptions(),
            logo: LogoOptions(enabled: true),
            border: BorderOptions(enabled: true)
        )
    )
}

import Foundation

public struct Standard2Template {
    public static let config = TemplateConfig(
        id: "standard2",
        name: "Framed",
        description: "Rounded corners and shadow with brand name + model on the left, params on the right with logo",
        previewAssetName: "template_standard2",
        processors: .fixed([
            ProcessorStep(processorName: "rounded_corner", stepConfig: ["corner_radius": .double(0.01)]),
            ProcessorStep(processorName: "shadow",         stepConfig: ["shadow_radius": .double(0.006), "shadow_color": .string("#00000026")]),
            ProcessorStep(processorName: "watermark", stepConfig: [
                "left_top":    .dict(["text": .string("{{make|default(\"\")}} {{model|default(\"\")}}"), "bold": .bool(true)]),
                "left_bottom": .dict(["text": .string("{{lensModel|default(\"\")}}")]),
                "right_top":   .dict(["text": .string("{{focalLength}}  {{fNumber}}  {{exposureTime}}")]),
                "right_bottom":.dict(["text": .string("{{iso}}  {{dateTimeOriginal|default(\"\")}}")]),
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

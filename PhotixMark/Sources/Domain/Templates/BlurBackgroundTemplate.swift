import Foundation

public struct BlurBackgroundTemplate {
    public static let config = TemplateConfig(
        id: "blurBackground",
        name: "Artistic",
        description: "Photo with rounded corners and shadow, centered on a blurred version of itself",
        previewAssetName: "template_blur_bg",
        processors: .fixed([
            ProcessorStep(processorName: "rounded_corner",           stepConfig: ["corner_radius": .double(0.02)]),
            ProcessorStep(processorName: "shadow",                   stepConfig: ["shadow_radius": .double(0.015)]),
            ProcessorStep(processorName: "blur_background_composite",stepConfig: ["blur_radius": .double(0.05), "bg_scale": .double(1.15)])
        ]),
        defaultOptions: TemplateUserOptions(
            exifFields: ExifFieldOptions(),
            shadow: ShadowOptions(enabled: true),
            blur: BlurOptions(radiusFraction: 0.05)
        )
    )
}

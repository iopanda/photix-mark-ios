import Foundation

public struct NikonBlurTemplate {
    public static let config = TemplateConfig(
        id: "nikonBlur",
        name: "Z Series",
        description: "Nikon-inspired design: sharp photo on blurred background with yellow accent watermark",
        previewAssetName: "template_nikon_blur",
        processors: .fixed([
            ProcessorStep(processorName: "rounded_corner",       stepConfig: ["corner_radius": .double(0.02)]),
            ProcessorStep(processorName: "shadow",               stepConfig: ["shadow_radius": .double(0.01)]),
            ProcessorStep(processorName: "nikon_blur_composite", stepConfig: ["blur_radius": .double(0.05), "bg_scale": .double(1.15)])
        ]),
        defaultOptions: TemplateUserOptions(
            exifFields: ExifFieldOptions(),
            logo: LogoOptions(enabled: false),
            shadow: ShadowOptions(enabled: true),
            blur: BlurOptions(radiusFraction: 0.05)
        )
    )
}

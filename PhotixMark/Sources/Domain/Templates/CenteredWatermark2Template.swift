import Foundation

public struct CenteredWatermark2Template {
    public static let config = TemplateConfig(
        id: "centeredWatermark2",
        name: "Logo Bottom",
        description: "Photo on top, logo bar then camera info centered below",
        previewAssetName: "template_centered2",
        processors: .fixed([
            ProcessorStep(processorName: "centered_layout", stepConfig: [
                "logo_position": .string("bottom"),
                "padding":       .double(0.03),
                "bar_height":    .double(0.08),
                "font_size":     .double(0.22)
            ])
        ]),
        defaultOptions: TemplateUserOptions(
            exifFields: ExifFieldOptions(
                showBrand: true, showModel: true, showLens: false,
                showFocalLength: true, showAperture: true, showShutter: true,
                showISO: true, showDateTime: false
            ),
            logo: LogoOptions(enabled: true),
            colors: ColorOptions(textColorHex: "#000000", secondaryTextColorHex: "#666666"),
            background: BackgroundOptions(backgroundColorHex: "#FFFFFF")
        )
    )
}

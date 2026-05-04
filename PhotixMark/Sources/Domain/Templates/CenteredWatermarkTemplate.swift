import Foundation

public struct CenteredWatermarkTemplate {
    public static let config = TemplateConfig(
        id: "centeredWatermark",
        name: "Logo Top",
        description: "Logo bar on top, photo in the middle, camera info centered at the bottom",
        previewAssetName: "template_centered",
        processors: .fixed([
            ProcessorStep(processorName: "centered_layout", stepConfig: [
                "logo_position": .string("top"),
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

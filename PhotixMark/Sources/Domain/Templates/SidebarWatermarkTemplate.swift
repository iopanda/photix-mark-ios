import Foundation

public struct SidebarWatermarkTemplate {
    public static let config = TemplateConfig(
        id: "sidebarWatermark",
        name: "Magazine",
        description: "Photo on the left, white sidebar with params and logo on the right",
        previewAssetName: "template_sidebar",
        processors: .responsive(
            landscape: [
                ProcessorStep(processorName: "sidebar_layout", stepConfig: [
                    "padding":       .double(0.03),
                    "sidebar_width": .double(0.15)
                ])
            ],
            portrait: [
                ProcessorStep(processorName: "sidebar_layout", stepConfig: [
                    "padding":       .double(0.03),
                    "sidebar_width": .double(0.12)
                ])
            ],
            square: nil
        ),
        defaultOptions: TemplateUserOptions(
            exifFields: ExifFieldOptions(
                showBrand: false, showModel: true, showLens: false,
                showFocalLength: true, showAperture: true, showShutter: true,
                showISO: true, showDateTime: false
            ),
            logo: LogoOptions(enabled: true),
            colors: ColorOptions(textColorHex: "#000000", secondaryTextColorHex: "#999999"),
            background: BackgroundOptions(backgroundColorHex: "#FFFFFF")
        )
    )
}

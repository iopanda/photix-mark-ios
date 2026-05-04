import Foundation

public struct LogoCenteredTemplate {
    public static let config = TemplateConfig(
        id: "logoCentered",
        name: "Brand Mark",
        description: "Only the brand logo centered below the photo — no text",
        previewAssetName: "template_logo_centered",
        processors: .fixed([
            ProcessorStep(processorName: "logo_centered_bar", stepConfig: [:])
        ]),
        defaultOptions: TemplateUserOptions(
            exifFields: ExifFieldOptions(
                showBrand: false, showModel: false, showLens: false,
                showFocalLength: false, showAperture: false, showShutter: false,
                showISO: false, showDateTime: false
            ),
            logo: LogoOptions(enabled: true)
        )
    )
}

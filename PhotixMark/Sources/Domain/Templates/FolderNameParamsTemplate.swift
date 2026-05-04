import Foundation

public struct FolderNameParamsTemplate {
    public static let config = TemplateConfig(
        id: "folderNameParams",
        name: "Minimal",
        description: "Date and shooting params overlaid at the bottom-right corner of the photo",
        previewAssetName: "template_folder_name",
        processors: .fixed([
            ProcessorStep(processorName: "corner_label_composite", stepConfig: [:])
        ]),
        defaultOptions: TemplateUserOptions(
            exifFields: ExifFieldOptions(
                showBrand: false, showModel: false, showLens: false,
                showFocalLength: true, showAperture: true, showShutter: true,
                showISO: true, showDateTime: true
            ),
            logo: LogoOptions(enabled: false)
        )
    )
}

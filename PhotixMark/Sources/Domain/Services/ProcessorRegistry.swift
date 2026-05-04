import Foundation

/// Central registry for all processors and templates.
public final class ProcessorRegistry: @unchecked Sendable {
    public static let shared = ProcessorRegistry()
    private var processors: [String: any ImageProcessor] = [:]
    private var _templates: [TemplateConfig] = []

    private init() {}

    public func register(_ processor: some ImageProcessor) {
        processors[processor.name] = processor
    }

    public func processor(named name: String) -> (any ImageProcessor)? {
        processors[name]
    }

    public var allTemplates: [TemplateConfig] { _templates }

    public func template(id: String) -> TemplateConfig? {
        _templates.first { $0.id == id }
    }

    public func registerAll() {
        registerProcessors()
        registerTemplates()
    }

    private func registerProcessors() {
        register(BlurProcessor())
        register(ShadowProcessor())
        register(RoundedCornerProcessor())
        register(MarginProcessor())
        register(RichTextProcessor())
        register(MultiRichTextProcessor())
        register(WatermarkProcessor())
        register(ConcatProcessor())
        register(ResizeProcessor())
        register(CropProcessor())
        register(AlignmentProcessor())
        register(FlexLayoutProcessor())
        register(BlurBackgroundCompositeProcessor())
        register(NikonBlurCompositeProcessor())
        register(CornerLabelCompositeProcessor())
        register(LogoCenteredBarProcessor())
        register(CenteredLayoutProcessor())
        register(SidebarLayoutProcessor())
    }

    private func registerTemplates() {
        _templates = [
            NoProcessTemplate.config,
            Standard1Template.config,
            Standard2Template.config,
            LogoCenteredTemplate.config,
            BlurBackgroundTemplate.config,
            NikonBlurTemplate.config,
            FolderNameParamsTemplate.config,
            CenteredWatermarkTemplate.config,
            CenteredWatermark2Template.config,
            SidebarWatermarkTemplate.config
        ]
    }
}

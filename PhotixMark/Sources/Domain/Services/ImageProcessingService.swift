import Foundation
import CoreGraphics

/// Runs a processor pipeline for a single image.
public actor ImageProcessingService {
    public static let shared = ImageProcessingService()

    private init() {}

    public func runPipeline(
        source: CGImage,
        exif: ExifData,
        userOptions: TemplateUserOptions,
        steps: [ProcessorStep],
        customLogos: [String: Data] = [:]
    ) async throws -> CGImage {
        var ctx = ProcessorContext(
            sourceImage: source,
            exif: exif,
            userOptions: userOptions,
            customLogos: customLogos
        )

        for step in steps {
            guard let processor = ProcessorRegistry.shared.processor(named: step.processorName) else {
                continue
            }
            ctx.stepConfig = step.stepConfig
            ctx = try await processor.process(ctx)
        }

        guard let result = ctx.layers.last else {
            throw ProcessorError.invalidLayer
        }
        return result
    }

    public func runPipelineForTemplate(
        source: CGImage,
        exif: ExifData,
        userOptions: TemplateUserOptions,
        template: TemplateConfig,
        customLogos: [String: Data] = [:]
    ) async throws -> CGImage {
        let size = CGSize(width: source.width, height: source.height)
        let steps = template.processors.steps(for: size)
        return try await runPipeline(
            source: source,
            exif: exif,
            userOptions: userOptions,
            steps: steps,
            customLogos: customLogos
        )
    }
}

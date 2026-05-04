#if os(macOS)
import AppKit
import CoreGraphics
import UniformTypeIdentifiers

public struct MacImageExporter {

    public enum ExportError: Error, LocalizedError {
        case cancelled
        case writeFailed(String)

        public var errorDescription: String? {
            switch self {
            case .cancelled:           return "Export cancelled"
            case .writeFailed(let m):  return "Write failed: \(m)"
            }
        }
    }

    public init() {}

    @MainActor
    public func export(_ results: [ProcessedResult]) async throws {
        if results.count == 1, let result = results.first {
            try await exportSingle(result)
        } else {
            try await exportBatch(results)
        }
    }

    @MainActor
    private func exportSingle(_ result: ProcessedResult) async throws {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.jpeg]
        panel.nameFieldStringValue = result.originalFilename
        panel.title = "Save Photo"
        let response = await panel.begin()
        guard response == .OK, let url = panel.url else { throw ExportError.cancelled }
        do {
            try result.jpegData.write(to: url)
        } catch {
            throw ExportError.writeFailed(error.localizedDescription)
        }
    }

    @MainActor
    private func exportBatch(_ results: [ProcessedResult]) async throws {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Save \(results.count) Photos Here"
        panel.title = "Choose Export Folder"
        let response = await panel.begin()
        guard response == .OK, let dir = panel.url else { throw ExportError.cancelled }
        for result in results {
            let dest = dir.appendingPathComponent(result.originalFilename)
            do {
                try result.jpegData.write(to: dest)
            } catch {
                throw ExportError.writeFailed("\(result.originalFilename): \(error.localizedDescription)")
            }
        }
    }
}
#endif

import Foundation
import SwiftUI
import CoreGraphics
import ImageIO
#if os(iOS)
import Photos
import PhotosUI
#endif

// Wraps CGImage for NSCache (which requires AnyObject values).
private final class CachedImage {
    let image: CGImage
    init(_ image: CGImage) { self.image = image }
}

@MainActor
public final class EditorViewModel: ObservableObject {

    // MARK: - Photo items
    @Published public var photoItems: [PhotoItem] = []
    @Published public var currentIndex: Int = 0

    // MARK: - Per-image state
    @Published public var exifCache: [UUID: ExifData] = [:]
    /// Stores processed results as compressed JPEG data (~3 MB each) instead of raw CGImage (~50 MB each).
    /// This is the authoritative store; cgImageCache is a decode-on-demand layer that evicts under pressure.
    @Published public var processedCache: [UUID: Data] = [:]
    private let cgImageCache = NSCache<NSUUID, CachedImage>()
    @Published public var imageStates: [UUID: ImageState] = [:]

    // MARK: - Current UI state (mirrors the active photo's imageState)
    @Published public var selectedTemplateId: String = "noProcess"
    @Published public var currentOptions: TemplateUserOptions = TemplateUserOptions()

    // MARK: - Brand logos
    @Published public var customLogos: [String: Data] = [:]
    @Published public var detectedBrands: [String] = []

    // MARK: - UI state
    @Published public var processingProgress: BatchProgress?
    @Published public var isProcessing: Bool = false
    @Published public var toastMessage: ToastMessage?
    @Published public var showImageSelector: Bool = false
    @Published public var selectedForApply: Set<UUID> = []

    // MARK: - Dependencies
    #if os(iOS)
    private let importer = PhotoLibraryImporter()
    private let exporter = ImageExporter()
    #elseif os(macOS)
    private let exporter = MacImageExporter()
    #endif
    private let logoRepo  = BrandLogoRepository()

    // MARK: - Computed helpers

    public var currentItem: PhotoItem? { photoItems[safe: currentIndex] }

    public var currentEffectiveExif: ExifData {
        guard let item = currentItem else { return .empty }
        return effectiveExif(for: item.id)
    }

    // MARK: - Init

    public init() {
        customLogos = logoRepo.loadAll()
        cgImageCache.totalCostLimit = 200 * 1024 * 1024  // 200 MB decoded image budget
        cgImageCache.countLimit = 8
    }

    // MARK: - CGImage decode cache

    /// Returns a CGImage for `id`, decoding from JPEG data if not already cached.
    public func cgImage(for id: UUID) -> CGImage? {
        if let cached = cgImageCache.object(forKey: id as NSUUID) {
            return cached.image
        }
        guard let data = processedCache[id],
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let img = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        let cost = img.width * img.height * 4
        cgImageCache.setObject(CachedImage(img), forKey: id as NSUUID, cost: cost)
        return img
    }

    // MARK: - Import

    #if os(iOS)
    public func importPhotos(_ results: [PHPickerResult]) async {
        isProcessing = true
        let loaded = await importer.load(results)
        for (item, exif) in loaded {
            photoItems.append(item)
            exifCache[item.id] = exif
            // New photos inherit the currently active template/options as a convenience.
            imageStates[item.id] = ImageState(templateId: selectedTemplateId, userOptions: currentOptions)
        }
        updateDetectedBrands()
        isProcessing = false
        if !loaded.isEmpty {
            toastMessage = ToastMessage(text: String(format: String(localized: "%lld photo(s) imported"), loaded.count), kind: .success)
        }
    }
    #elseif os(macOS)
    public func importPhotos(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        isProcessing = true
        let macImporter = MacPhotoImporter()
        let loaded = await macImporter.load(urls)
        for (item, exif) in loaded {
            photoItems.append(item)
            exifCache[item.id] = exif
            imageStates[item.id] = ImageState(templateId: selectedTemplateId, userOptions: currentOptions)
        }
        updateDetectedBrands()
        isProcessing = false
        if !loaded.isEmpty {
            toastMessage = ToastMessage(text: String(format: String(localized: "%lld photo(s) imported"), loaded.count), kind: .success)
        }
    }
    #endif

    // MARK: - Photo switching

    /// Called whenever currentIndex changes. Restores the UI state for the newly active photo
    /// and generates its preview if not already cached.
    public func switchToCurrentItem() {
        guard let item = currentItem else { return }
        let state = imageStates[item.id] ?? ImageState()
        selectedTemplateId = state.templateId
        currentOptions = state.userOptions
        if processedCache[item.id] == nil {
            Task { await generatePreview(for: item) }
        }
    }

    // MARK: - Template selection (per-photo)

    /// Saves the selected template to the current photo's state only.
    public func selectTemplate(_ id: String) {
        guard let item = currentItem else { return }
        let opts = ProcessorRegistry.shared.template(id: id)?.defaultOptions ?? TemplateUserOptions()
        selectedTemplateId = id
        currentOptions = opts
        imageStates[item.id, default: ImageState()].templateId = id
        imageStates[item.id, default: ImageState()].userOptions = opts
        processedCache.removeValue(forKey: item.id)
        cgImageCache.removeObject(forKey: item.id as NSUUID)
    }

    // MARK: - Options update (per-photo)

    /// Persists changed options to the current photo's state and re-renders preview.
    /// currentOptions is already updated by the SwiftUI binding before this is called.
    public func saveOptions(_ options: TemplateUserOptions) {
        guard let item = currentItem else { return }
        imageStates[item.id, default: ImageState()].userOptions = options
        processedCache.removeValue(forKey: item.id)
        cgImageCache.removeObject(forKey: item.id as NSUUID)
        Task { await generatePreview(for: item) }
    }

    // MARK: - Preview (single image)

    public func generatePreview(for item: PhotoItem) async {
        let state = imageStates[item.id] ?? ImageState()
        guard let template = ProcessorRegistry.shared.template(id: state.templateId) else { return }
        let exif = effectiveExif(for: item.id)
        do {
            let result = try await ImageProcessingService.shared.runPipelineForTemplate(
                source: item.cgImage,
                exif: exif,
                userOptions: state.userOptions,
                template: template,
                customLogos: customLogos
            )
            guard let jpegData = ImageExporter.jpegData(from: result, quality: 0.92) else { return }
            processedCache[item.id] = jpegData
            // Warm the decode cache for immediate display.
            let cost = result.width * result.height * 4
            cgImageCache.setObject(CachedImage(result), forKey: item.id as NSUUID, cost: cost)
        } catch {
            toastMessage = ToastMessage(text: String(format: String(localized: "Preview failed: %@"), error.localizedDescription), kind: .error)
        }
    }

    // MARK: - Apply to all / selected

    public func applyToAll() async {
        await applyToItems(photoItems)
    }

    public func applyToSelected() async {
        let items = photoItems.filter { selectedForApply.contains($0.id) }
        await applyToItems(items)
    }

    private func applyToItems(_ items: [PhotoItem]) async {
        guard !items.isEmpty else { return }

        isProcessing = true
        processingProgress = BatchProgress(completed: 0, total: items.count)

        defer {
            isProcessing = false
            processingProgress = nil
        }

        // Each photo uses its own saved template and options.
        let batchItems: [(id: UUID, image: CGImage, exif: ExifData, filename: String, template: TemplateConfig, userOptions: TemplateUserOptions)] = items.compactMap { item in
            let state = imageStates[item.id] ?? ImageState()
            guard let template = ProcessorRegistry.shared.template(id: state.templateId) else { return nil }
            return (id: item.id, image: item.cgImage,
                    exif: effectiveExif(for: item.id),
                    filename: item.originalFilename,
                    template: template,
                    userOptions: state.userOptions)
        }

        let stream = await BatchProcessingService.shared.processBatch(
            items: batchItems,
            customLogos: customLogos
        )

        do {
            for try await (progress, result) in stream {
                processingProgress = progress
                if let result {
                    processedCache[result.id] = result.jpegData
                    cgImageCache.removeObject(forKey: result.id as NSUUID)
                }
            }
            toastMessage = ToastMessage(text: String(format: String(localized: "Done! %lld photo(s) processed"), items.count), kind: .success)
        } catch {
            toastMessage = ToastMessage(text: error.localizedDescription, kind: .error)
        }
    }

    // MARK: - Export

    public func exportAll() async {
        let results: [ProcessedResult] = photoItems.compactMap { item in
            if let jpegData = processedCache[item.id] {
                return ProcessedResult(id: item.id, jpegData: jpegData, originalFilename: item.originalFilename)
            }
            // Fall back to original image if not yet processed.
            guard let jpegData = ImageExporter.jpegData(from: item.cgImage) else { return nil }
            return ProcessedResult(id: item.id, jpegData: jpegData, originalFilename: item.originalFilename)
        }
        guard !results.isEmpty else {
            toastMessage = ToastMessage(text: String(localized: "Nothing to export"), kind: .info)
            return
        }
        do {
            #if os(iOS)
            try await exporter.saveToPhotoLibrary(results)
            toastMessage = ToastMessage(text: String(format: String(localized: "%lld photo(s) saved to library"), results.count), kind: .success)
            #elseif os(macOS)
            try await exporter.export(results)
            toastMessage = ToastMessage(text: String(format: String(localized: "%lld photo(s) exported"), results.count), kind: .success)
            #endif
        } catch {
            toastMessage = ToastMessage(text: error.localizedDescription, kind: .error)
        }
    }

    public func exportCurrent() async {
        guard let item = currentItem else {
            toastMessage = ToastMessage(text: String(localized: "Nothing to export"), kind: .info)
            return
        }
        let jpegData: Data
        if let cached = processedCache[item.id] {
            jpegData = cached
        } else if let fallback = ImageExporter.jpegData(from: item.cgImage) {
            jpegData = fallback
        } else {
            toastMessage = ToastMessage(text: String(localized: "Nothing to export"), kind: .info)
            return
        }
        let result = ProcessedResult(id: item.id, jpegData: jpegData, originalFilename: item.originalFilename)
        do {
            #if os(iOS)
            try await exporter.saveToPhotoLibrary([result])
            toastMessage = ToastMessage(text: String(localized: "Saved to photo library"), kind: .success)
            #elseif os(macOS)
            try await exporter.export([result])
            toastMessage = ToastMessage(text: String(localized: "Saved"), kind: .success)
            #endif
        } catch {
            toastMessage = ToastMessage(text: error.localizedDescription, kind: .error)
        }
    }

    // MARK: - Remove photo

    public func removePhoto(id: UUID) {
        guard let idx = photoItems.firstIndex(where: { $0.id == id }) else { return }
        photoItems.remove(at: idx)
        exifCache.removeValue(forKey: id)
        processedCache.removeValue(forKey: id)
        cgImageCache.removeObject(forKey: id as NSUUID)
        imageStates.removeValue(forKey: id)
        if !photoItems.isEmpty {
            currentIndex = min(currentIndex, photoItems.count - 1)
        } else {
            currentIndex = 0
        }
        updateDetectedBrands()
    }

    // MARK: - EXIF overrides

    public func updateExifOverrides(_ overrides: ExifData) {
        guard let item = currentItem else { return }
        imageStates[item.id, default: ImageState()].exifOverrides = overrides
        processedCache.removeValue(forKey: item.id)
        cgImageCache.removeObject(forKey: item.id as NSUUID)
        Task { await generatePreview(for: item) }
    }

    // MARK: - Custom logos

    public func uploadLogo(brand: String, data: Data) {
        customLogos[brand] = data
        try? logoRepo.save(imageData: data, for: brand)
        processedCache.removeAll()
        cgImageCache.removeAllObjects()
    }

    // MARK: - Private helpers

    private func effectiveExif(for id: UUID) -> ExifData {
        let base = exifCache[id] ?? .empty
        let overrides = imageStates[id]?.exifOverrides ?? .empty
        return base.merging(overrides)
    }

    private func updateDetectedBrands() {
        var brands: Set<String> = []
        for exif in exifCache.values {
            if let make = exif.make?.lowercased() { brands.insert(make) }
        }
        detectedBrands = brands.sorted()
    }
}

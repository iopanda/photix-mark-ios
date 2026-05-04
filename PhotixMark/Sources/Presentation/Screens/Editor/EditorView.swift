import SwiftUI
#if os(iOS)
import PhotosUI
#endif

struct EditorView: View {
    @ObservedObject var viewModel: EditorViewModel

    @State private var selectedTab: EditorTab = .templates
    @State private var exifEditorItem: PhotoItem?
    @State private var showImageSelector = false
    @State private var showAddPhotoPicker = false
    @State private var showTemplateConfig = false
    #if os(macOS)
    @State private var panelWidth: CGFloat = 220
    private let panelMinWidth: CGFloat = 140
    private let panelMaxWidth: CGFloat = 400
    #endif

    enum EditorTab: String, CaseIterable {
        case templates = "Templates"
        case brand     = "Brand Logo"
        case apply     = "Apply"
        case export    = "Export"

        var icon: String {
            switch self {
            case .templates: return "sparkles"
            case .brand:     return "photo.badge.arrow.down"
            case .apply:     return "wand.and.stars"
            case .export:    return "square.and.arrow.down"
            }
        }
    }

    var body: some View {
        #if os(macOS)
        macLayout
        #else
        iosLayout
        #endif
    }

    // MARK: - macOS: VSCode-style activity bar + panel + main

    #if os(macOS)
    private var macLayout: some View {
        HStack(spacing: 0) {
            // Column 1: narrow activity bar (icons only)
            macActivityBar

            Divider()

            // Column 2: resizable panel
            macPanel
                .frame(width: panelWidth)
                .background(AppTheme.secondaryBg)

            // Drag handle between panel and photo
            macResizeHandle

            // Column 3: photo preview
            carouselArea
                .layoutPriority(1)
        }
        .navigationTitle("PhotixMark")
        .toolbar { addButton }
        .sheet(item: $exifEditorItem)           { (item: PhotoItem) in exifSheet(for: item) }
        .sheet(isPresented: $showImageSelector) { selectorSheet }
        .sheet(isPresented: $showTemplateConfig) { templateConfigSheet }
        .overlay { ProcessingOverlayView(progress: viewModel.processingProgress) }
        .toast($viewModel.toastMessage)
        .onChange(of: viewModel.currentIndex) { _ in viewModel.switchToCurrentItem() }
        .onChange(of: viewModel.currentOptions) { opts in viewModel.saveOptions(opts) }
    }

    /// Narrow icon-only dock (like VSCode activity bar).
    private var macActivityBar: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 8)
            ForEach(EditorTab.allCases, id: \.self) { tab in
                Button { selectedTab = tab } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                            .frame(width: 28, height: 28)
                    }
                    .foregroundColor(selectedTab == tab ? .accentColor : Color(nsColor: .secondaryLabelColor))
                    .frame(width: 52, height: 52)
                    .background(
                        selectedTab == tab
                            ? Color.accentColor.opacity(0.10)
                            : Color.clear
                    )
                    .overlay(
                        Rectangle()
                            .frame(width: 3)
                            .foregroundColor(selectedTab == tab ? .accentColor : .clear),
                        alignment: .leading
                    )
                }
                .buttonStyle(.plain)
                .help(tab.rawValue)
            }
            Spacer()
        }
        .frame(width: 52)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    /// Thin draggable divider between the panel and the photo area.
    private var macResizeHandle: some View {
        Color(nsColor: .separatorColor)
            .frame(width: 1)
            .overlay(
                Color.clear
                    .frame(width: 8)          // wider invisible hit area
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                let newW = panelWidth + value.translation.width
                                panelWidth = min(panelMaxWidth, max(panelMinWidth, newW))
                            }
                    )
                    .cursor(.resizeLeftRight)
            )
    }

    /// Panel right of the activity bar — content depends on selected tab.
    @ViewBuilder
    private var macPanel: some View {
        switch selectedTab {
        case .templates:
            macTemplatePanel
        case .brand:
            brandTab
        case .apply:
            applyTab
        case .export:
            exportTab
        }
    }

    /// Vertical scrollable template list with settings button at the top.
    private var macTemplatePanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Templates")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Button { showTemplateConfig = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Template Settings")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Vertical template list
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(ProcessorRegistry.shared.allTemplates) { template in
                        macTemplateRow(template)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func macTemplateRow(_ template: TemplateConfig) -> some View {
        let isSelected = template.id == viewModel.selectedTemplateId
        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(nsColor: .controlBackgroundColor))
                .frame(width: 40, height: 30)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
            Text(template.name)
                .font(.subheadline)
                .foregroundColor(isSelected ? .accentColor : .primary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            isSelected ? Color.accentColor.opacity(0.08) : Color.clear
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectTemplate(template.id)
            guard let item = viewModel.currentItem else { return }
            Task { await viewModel.generatePreview(for: item) }
        }
    }
    #endif

    // MARK: - iOS layout (unchanged)

    private var iosLayout: some View {
        VStack(spacing: 0) {
            carouselArea
                .layoutPriority(1)

            Divider()

            if selectedTab != .templates {
                Divider()
                tabContent
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
            }

            templateStrip
            tabBar
        }
        .navigationTitle("PhotixMark")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { addButton }
        #if os(iOS)
        .sheet(isPresented: $showAddPhotoPicker) { addPhotoPicker }
        #endif
        .sheet(item: $exifEditorItem)           { (item: PhotoItem) in exifSheet(for: item) }
        .sheet(isPresented: $showImageSelector) { selectorSheet }
        .sheet(isPresented: $showTemplateConfig) { templateConfigSheet }
        .overlay { ProcessingOverlayView(progress: viewModel.processingProgress) }
        .toast($viewModel.toastMessage)
        .onChange(of: viewModel.currentIndex) { _ in viewModel.switchToCurrentItem() }
        .onChange(of: viewModel.currentOptions) { opts in viewModel.saveOptions(opts) }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var carouselArea: some View {
        if viewModel.photoItems.isEmpty {
            emptyState
        } else {
            ImageCarouselView(
                items: viewModel.photoItems,
                resolveImage: { id in viewModel.cgImage(for: id) },
                currentIndex: $viewModel.currentIndex,
                onTapExif: { item in exifEditorItem = item },
                onRemove: { id in viewModel.removePhoto(id: id) },
                onAdd: {
                    #if os(iOS)
                    showAddPhotoPicker = true
                    #elseif os(macOS)
                    Task {
                        let importer = MacPhotoImporter()
                        let urls = await importer.pickFiles()
                        await viewModel.importPhotos(urls)
                    }
                    #endif
                }
            )
            .frame(maxWidth: .infinity)
        }
    }

    // Template selector strip — horizontal scroll only, no config here
    private var templateStrip: some View {
        TemplateSelectorView(
            templates: ProcessorRegistry.shared.allTemplates,
            selectedId: viewModel.selectedTemplateId,
            onSelect: { id in
                viewModel.selectTemplate(id)
                guard let item = viewModel.currentItem else { return }
                Task { await viewModel.generatePreview(for: item) }
            }
        )
        .background(AppTheme.background)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(EditorTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = (selectedTab == tab && tab == .templates) ? .templates : tab
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.icon).font(.system(size: 18))
                        Text(tab.rawValue).font(.caption2)
                    }
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(AppTheme.secondaryBg)
        .overlay(Divider(), alignment: .top)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .templates: templatesTab
        case .brand:     brandTab
        case .apply:     applyTab
        case .export:    exportTab
        }
    }

    private var templatesTab: some View { EmptyView() }

    @ViewBuilder
    private var templateConfigSheet: some View {
        NavigationStack {
            if let template = ProcessorRegistry.shared.template(id: viewModel.selectedTemplateId) {
                TemplateConfigView(options: $viewModel.currentOptions, template: template)
                    .navigationTitle(template.name)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showTemplateConfig = false }
                        }
                    }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }

    private var brandTab: some View {
        BrandLogoView(
            detectedBrands: viewModel.detectedBrands,
            customLogos: $viewModel.customLogos,
            onUpload: viewModel.uploadLogo,
            onDelete: { _ in }
        )
    }

    private var applyTab: some View {
        VStack(spacing: 16) {
            if let progress = viewModel.processingProgress {
                ProcessingProgressView(progress: progress)
            }
            Button("Apply to All Photos") { Task { await viewModel.applyToAll() } }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isProcessing || viewModel.photoItems.isEmpty)
            Button("Apply to Selected…") { viewModel.selectedForApply = []; showImageSelector = true }
                .buttonStyle(.bordered)
                .disabled(viewModel.isProcessing || viewModel.photoItems.isEmpty)
            Spacer()
        }
        .padding()
    }

    private var exportTab: some View {
        VStack(spacing: 16) {
            Button("Save Current to Photos") { Task { await viewModel.exportCurrent() } }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.currentItem == nil)
            Button("Save All to Photos") { Task { await viewModel.exportAll() } }
                .buttonStyle(.bordered)
                .disabled(viewModel.photoItems.isEmpty)
            #if os(iOS)
            Text("Photos will be saved to your iOS Photo Library.")
            #else
            Text("Photos will be exported as JPEG files.")
            #endif
            Spacer()
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 48)).foregroundColor(.secondary)
            Text("Import photos to get started").font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar / sheets

    private var addButton: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            if selectedTab == .templates {
                Button { showTemplateConfig = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
            Button {
                #if os(iOS)
                showAddPhotoPicker = true
                #elseif os(macOS)
                Task {
                    let importer = MacPhotoImporter()
                    let urls = await importer.pickFiles()
                    await viewModel.importPhotos(urls)
                }
                #endif
            } label: {
                Image(systemName: "plus.circle")
            }
        }
    }

    #if os(iOS)
    private var addPhotoPicker: some View {
        PHPickerRepresentable(maxSelection: 50) { results in
            Task { await viewModel.importPhotos(results) }
        }
        .ignoresSafeArea()
    }
    #endif

    @ViewBuilder
    private func exifSheet(for item: PhotoItem) -> some View {
        #if os(macOS)
        NavigationStack {
            ExifEditorView(exif: Binding(
                get: { (viewModel.exifCache[item.id] ?? .empty).merging(viewModel.imageStates[item.id]?.exifOverrides ?? .empty) },
                set: { viewModel.updateExifOverrides($0) }
            ))
        }
        #else
        ExifEditorView(exif: Binding(
            get: { (viewModel.exifCache[item.id] ?? .empty).merging(viewModel.imageStates[item.id]?.exifOverrides ?? .empty) },
            set: { viewModel.updateExifOverrides($0) }
        ))
        #endif
    }

    private var selectorSheet: some View {
        ImageSelectorView(
            items: viewModel.photoItems,
            resolveImage: { id in viewModel.cgImage(for: id) },
            selectedIds: $viewModel.selectedForApply,
            onApply: { Task { await viewModel.applyToSelected() } }
        )
    }
}

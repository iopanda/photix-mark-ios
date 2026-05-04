import SwiftUI
#if os(iOS)
import PhotosUI
#endif

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showPicker = false
    @State private var editorVM: EditorViewModel?
    @State private var showEditor = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
                    .padding(.top, 40)

                Text("PhotixMark")
                    .font(.largeTitle.bold())

                Text("Add beautiful EXIF watermarks to your photos — 100% on device.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)

            // Feature grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                FeatureCell(icon: "camera.fill",        title: "EXIF Metadata",   subtitle: "Auto-reads camera info")
                FeatureCell(icon: "photo.stack",        title: "Batch Process",   subtitle: "Handle multiple photos")
                FeatureCell(icon: "paintbrush.pointed", title: "10 Templates",    subtitle: "Beautiful preset styles")
                FeatureCell(icon: "lock.shield",        title: "100% Private",    subtitle: "No data leaves your device")
            }
            .padding(.horizontal, 24)

            Spacer()

            // Import button
            Button {
                showPicker = true
            } label: {
                Label("Import from Photos", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("")
        #if os(iOS)
        .navigationBarHidden(true)
        .sheet(isPresented: $showPicker) {
            PHPickerRepresentable(maxSelection: 50) { results in
                guard !results.isEmpty else { return }
                let vm = EditorViewModel()
                editorVM = vm
                showEditor = true
                Task { await vm.importPhotos(results) }
            }
            .ignoresSafeArea()
        }
        #else
        .onChange(of: showPicker) { shouldShow in
            guard shouldShow else { return }
            showPicker = false
            Task {
                let importer = MacPhotoImporter()
                let urls = await importer.pickFiles()
                guard !urls.isEmpty else { return }
                let vm = EditorViewModel()
                editorVM = vm
                showEditor = true
                await vm.importPhotos(urls)
            }
        }
        #endif
        .navigationDestination(isPresented: $showEditor) {
            if let vm = editorVM {
                EditorView(viewModel: vm)
            }
        }
    }
}

private struct FeatureCell: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.secondaryBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

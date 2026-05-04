import SwiftUI

struct ImageSelectorView: View {
    let items: [PhotoItem]
    let resolveImage: (UUID) -> CGImage?
    @Binding var selectedIds: Set<UUID>
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 90))]

    var body: some View {
        NavigationStack {
            photoGrid
                .navigationTitle("Select Photos")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar { toolbarContent }
        }
    }

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items, id: \.id) { item in
                    photoCell(item)
                }
            }
            .padding(12)
        }
    }

    private func photoCell(_ item: PhotoItem) -> some View {
        let isSelected = selectedIds.contains(item.id)
        return ZStack(alignment: .topTrailing) {
            Image(decorative: resolveImage(item.id) ?? item.cgImage, scale: 1)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .opacity(isSelected ? 1 : 0.6)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .padding(4)
            }
        }
        .onTapGesture {
            if isSelected { selectedIds.remove(item.id) }
            else { selectedIds.insert(item.id) }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(String(format: String(localized: "Apply (%lld)"), selectedIds.count)) { onApply(); dismiss() }
                .disabled(selectedIds.isEmpty)
        }
    }
}

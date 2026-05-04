import SwiftUI

struct ImageCarouselView: View {
    let items: [PhotoItem]
    /// Returns the processed CGImage for a photo id, or nil to fall back to the original.
    let resolveImage: (UUID) -> CGImage?
    @Binding var currentIndex: Int
    let onTapExif: (PhotoItem) -> Void
    var onRemove: ((UUID) -> Void)? = nil
    var onAdd: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Main pager
            #if os(iOS)
            TabView(selection: $currentIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ImagePreviewView(
                        image: resolveImage(item.id) ?? item.cgImage,
                        onTapExif: { onTapExif(item) }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #else
            // macOS: plain display of current item only (no TabView to avoid indicator dot)
            if let item = items[safe: currentIndex] {
                ImagePreviewView(
                    image: resolveImage(item.id) ?? item.cgImage,
                    onTapExif: { onTapExif(item) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(currentIndex)
            }
            #endif

            // Thumbnail strip — always visible so the "+" add button is accessible
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            ThumbnailCell(
                                image: resolveImage(item.id) ?? item.cgImage,
                                isSelected: index == currentIndex,
                                onRemove: onRemove.map { cb in { cb(item.id) } }
                            )
                            .id(index)
                            .onTapGesture { currentIndex = index }
                        }

                        if let onAdd {
                            AddPhotoCell(onAdd: onAdd)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: currentIndex) { idx in
                    withAnimation { proxy.scrollTo(idx, anchor: .center) }
                }
            }
            .frame(height: 72)
            .background(AppTheme.secondaryBg)
        }
    }
}

private struct ThumbnailCell: View {
    let image: CGImage
    let isSelected: Bool
    var onRemove: (() -> Void)? = nil

    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(decorative: image, scale: 1)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 2)
                )

            // Delete button — shown on hover (macOS) or always visible (iOS)
            if let onRemove, isHovered || isAlwaysVisible {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white, Color.black.opacity(0.6))
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
                .transition(.opacity)
            }
        }
        .onHover { isHovered = $0 }
    }

    private var isAlwaysVisible: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }
}

private struct AddPhotoCell: View {
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                .foregroundColor(.secondary.opacity(0.6))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.secondary)
                )
        }
        .buttonStyle(.plain)
    }
}

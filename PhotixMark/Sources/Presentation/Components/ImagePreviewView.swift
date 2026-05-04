import SwiftUI

struct ImagePreviewView: View {
    let image: CGImage
    let onTapExif: () -> Void

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            Image(decorative: image, scale: 1)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in scale = max(1, value) }
                        .onEnded { _ in
                            if scale < 1.05 { withAnimation { scale = 1; offset = .zero } }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1 { offset = value.translation }
                        }
                        .onEnded { _ in
                            if scale <= 1 { withAnimation { offset = .zero } }
                        }
                )
                .overlay(alignment: .topTrailing) {
                    Button {
                        onTapExif()
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                            .padding(10)
                    }
                }
        }
    }
}

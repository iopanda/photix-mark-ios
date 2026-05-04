import SwiftUI
import PhotosUI
import CoreGraphics
import ImageIO

struct BrandLogoView: View {
    let detectedBrands: [String]
    @Binding var customLogos: [String: Data]
    let onUpload: (String, Data) -> Void
    let onDelete: (String) -> Void

    @State private var selectedBrand: String?
    @State private var photoPickerItem: PhotosPickerItem?

    var body: some View {
        List {
            if detectedBrands.isEmpty {
                Text("No brands detected in imported photos.")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                Section("Detected Brands") {
                    ForEach(detectedBrands, id: \.self) { brand in
                        BrandLogoRow(
                            brand: brand,
                            logoData: customLogos[brand.lowercased()],
                            onPickTap: { selectedBrand = brand }
                        )
                    }
                }
            }

            Section("Default Logo") {
                BrandLogoRow(
                    brand: "default",
                    logoData: customLogos["default"],
                    onPickTap: { selectedBrand = "default" }
                )
            }
        }
        .photosPicker(
            isPresented: Binding(
                get: { selectedBrand != nil },
                set: { if !$0 { selectedBrand = nil } }
            ),
            selection: $photoPickerItem,
            matching: .images
        )
        .onChange(of: photoPickerItem) { item in
            guard let item, let brand = selectedBrand else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    onUpload(brand.lowercased(), data)
                }
                photoPickerItem = nil
                selectedBrand = nil
            }
        }
    }
}

private struct BrandLogoRow: View {
    let brand: String
    let logoData: Data?
    let onPickTap: () -> Void

    var body: some View {
        HStack {
            // Logo preview
            Group {
                if let data = logoData, let cg = cgImage(from: data) {
                    Image(decorative: cg, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if let cg = bundledCGImage(named: "logo_\(brand.lowercased())") {
                    Image(decorative: cg, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "photo.badge.plus")
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 44, height: 28)
            .padding(.trailing, 4)

            Text(brand.capitalized)
                .font(.body)

            Spacer()

            Button("Change") { onPickTap() }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private func cgImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func bundledCGImage(named name: String) -> CGImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

import SwiftUI
import CoreGraphics
import ImageIO

struct TemplateSelectorView: View {
    let templates: [TemplateConfig]
    let selectedId: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(templates) { template in
                    TemplateCardView(
                        template: template,
                        isSelected: template.id == selectedId
                    )
                    .onTapGesture { onSelect(template.id) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

struct TemplateCardView: View {
    let template: TemplateConfig
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.secondaryBg)
                    .frame(width: 80, height: 60)

                if let assetName = template.previewAssetName,
                   let url = Bundle.main.url(forResource: assetName, withExtension: "jpg") ??
                             Bundle.main.url(forResource: assetName, withExtension: "png"),
                   let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                   let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                    Image(decorative: cg, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
            )

            Text(template.name)
                .font(.caption2)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .lineLimit(1)
                .frame(width: 80)
        }
    }
}

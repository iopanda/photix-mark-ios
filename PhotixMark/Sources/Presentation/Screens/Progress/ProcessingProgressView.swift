import SwiftUI

struct ProcessingProgressView: View {
    let progress: BatchProgress

    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress.fraction, total: 1.0)
                .progressViewStyle(.linear)
                .tint(.accentColor)

            Text(verbatim: "\(progress.completed) / \(progress.total)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.secondaryBg)
        )
        .padding(.horizontal, 24)
    }
}

struct ProcessingOverlayView: View {
    let progress: BatchProgress?

    var body: some View {
        if let progress {
            ZStack {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text(String(format: String(localized: "Processing %lld / %lld"), progress.completed, progress.total))
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
            }
        }
    }
}

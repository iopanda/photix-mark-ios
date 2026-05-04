#if os(iOS)
import SwiftUI
import PhotosUI
import UIKit

/// Wraps PHPickerViewController so we get PHPickerResult with assetIdentifier,
/// which is required to read EXIF via PHAsset.
struct PHPickerRepresentable: UIViewControllerRepresentable {
    let maxSelection: Int
    let onPick: ([PHPickerResult]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = maxSelection
        config.filter = .images
        // This is critical: gives us assetIdentifier so EXIF can be read
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: ([PHPickerResult]) -> Void
        init(onPick: @escaping ([PHPickerResult]) -> Void) { self.onPick = onPick }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            onPick(results)
        }
    }
}
#endif

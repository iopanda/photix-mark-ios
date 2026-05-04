import SwiftUI

struct ExifEditorView: View {
    @Binding var exif: ExifData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        #if os(macOS)
        macBody
        #else
        iosBody
        #endif
    }

    // macOS: Form with .grouped style — sizes correctly inside a sheet without NavigationStack
    #if os(macOS)
    private var macBody: some View {
        Form {
            Section("Camera") {
                ExifFieldRow(field: .make,  exif: $exif)
                ExifFieldRow(field: .model, exif: $exif)
            }
            Section("Lens") {
                ExifFieldRow(field: .lensModel,   exif: $exif)
                ExifFieldRow(field: .focalLength, exif: $exif)
            }
            Section("Exposure") {
                ExifFieldRow(field: .fNumber,      exif: $exif)
                ExifFieldRow(field: .exposureTime, exif: $exif)
                ExifFieldRow(field: .iso,          exif: $exif)
            }
            Section("Date & Time") {
                ExifFieldRow(field: .dateTimeOriginal, exif: $exif)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .keyboardShortcut(.return, modifiers: [])
            }
        }
        .navigationTitle("Edit EXIF")
    }
    #endif

    // iOS: NavigationStack + Form (unchanged)
    private var iosBody: some View {
        NavigationStack {
            Form {
                Section("Camera") {
                    ExifFieldRow(field: .make,  exif: $exif)
                    ExifFieldRow(field: .model, exif: $exif)
                }
                Section("Lens") {
                    ExifFieldRow(field: .lensModel,   exif: $exif)
                    ExifFieldRow(field: .focalLength, exif: $exif)
                }
                Section("Exposure") {
                    ExifFieldRow(field: .fNumber,     exif: $exif)
                    ExifFieldRow(field: .exposureTime, exif: $exif)
                    ExifFieldRow(field: .iso,         exif: $exif)
                }
                Section("Date & Time") {
                    ExifFieldRow(field: .dateTimeOriginal, exif: $exif)
                }
            }
            .navigationTitle("Edit EXIF")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ExifFieldRow: View {
    let field: ExifField
    @Binding var exif: ExifData

    var body: some View {
        HStack {
            Text(field.displayLabel)
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            TextField("Optional", text: Binding(
                get: { field.value(from: exif) ?? "" },
                set: { newVal in
                    var copy = exif
                    field.applying(newVal, to: &copy)
                    exif = copy
                }
            ))
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
        }
    }
}

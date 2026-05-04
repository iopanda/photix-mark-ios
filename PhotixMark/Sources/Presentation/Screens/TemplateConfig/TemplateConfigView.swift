import SwiftUI

struct TemplateConfigView: View {
    @Binding var options: TemplateUserOptions
    let template: TemplateConfig

    var body: some View {
        Form {
            exifFieldsSection
            colorsSection
            if template.defaultOptions.logo.enabled {
                logoSection
            }
            if template.defaultOptions.shadow != nil {
                shadowSection
            }
            if template.defaultOptions.blur != nil {
                blurSection
            }
            layoutSection
        }
    }

    // MARK: - Sections

    private var exifFieldsSection: some View {
        Section("Visible EXIF Fields") {
            Toggle("Brand",        isOn: $options.exifFields.showBrand)
            Toggle("Model",        isOn: $options.exifFields.showModel)
            Toggle("Lens",         isOn: $options.exifFields.showLens)
            Toggle("Focal Length", isOn: $options.exifFields.showFocalLength)
            Toggle("Aperture",     isOn: $options.exifFields.showAperture)
            Toggle("Shutter",      isOn: $options.exifFields.showShutter)
            Toggle("ISO",          isOn: $options.exifFields.showISO)
            Toggle("Date / Time",  isOn: $options.exifFields.showDateTime)
        }
    }

    private var colorsSection: some View {
        Section("Colors") {
            ColorRow(label: "Text Color", hex: $options.colors.textColorHex)
            ColorRow(label: "Secondary Text", hex: $options.colors.secondaryTextColorHex)
            ColorRow(label: "Background", hex: $options.background.backgroundColorHex)
        }
    }

    private var logoSection: some View {
        Section("Logo") {
            Toggle("Show Logo", isOn: $options.logo.enabled)
        }
    }

    private var shadowSection: some View {
        Section("Shadow") {
            Toggle("Enable Shadow", isOn: Binding(
                get: { options.shadow?.enabled ?? false },
                set: { options.shadow = ShadowOptions(enabled: $0) }
            ))
        }
    }

    private var blurSection: some View {
        Section("Blur") {
            if var blur = options.blur {
                VStack(alignment: .leading) {
                    Text(String(format: String(localized: "Blur Radius: %@"), String(format: "%.2f", blur.radiusFraction)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: Binding(
                        get: { blur.radiusFraction },
                        set: { blur.radiusFraction = $0; options.blur = blur }
                    ), in: 0.01...0.1)
                }
            }
        }
    }

    private var layoutSection: some View {
        Section("Layout") {
            VStack(alignment: .leading) {
                Text(String(format: String(localized: "Padding: %@"), String(format: "%.2f", options.layout.paddingFraction)))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $options.layout.paddingFraction, in: 0.01...0.08)
            }
        }
    }
}

// MARK: - Color row using system ColorPicker

private struct ColorRow: View {
    let label: String
    @Binding var hex: String

    var body: some View {
        ColorPicker(label, selection: Binding(
            get: { Color(hex: hex) },
            set: { newColor in
                // Use SwiftUI Color's cgColor property — available on both iOS 14+ and macOS 11+
                if let cgColor = newColor.cgColor,
                   let components = cgColor.components,
                   components.count >= 3 {
                    let r = Int((components[0] * 255).rounded())
                    let g = Int((components[1] * 255).rounded())
                    let b = Int((components[2] * 255).rounded())
                    hex = String(format: "#%02X%02X%02X", r, g, b)
                }
            }
        ))
    }
}

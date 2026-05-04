import Foundation

/// Ports the web's templateRenderer.ts — resolves {{variable|filter}} expressions.
public struct TemplateRenderer {

    private let exif: ExifData
    private let customLogos: [String: Data]
    private let exifFields: ExifFieldOptions?

    public init(exif: ExifData, customLogos: [String: Data] = [:], exifFields: ExifFieldOptions? = nil) {
        self.exif = exif
        self.customLogos = customLogos
        self.exifFields = exifFields
    }

    /// Resolves a template string like "{{Make}} {{Model}}" or "{{FNumber|default('f/1.8')}}".
    public func render(_ template: String) -> String {
        var result = template
        let pattern = #"\{\{([^}]+)\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return template }
        let nsTemplate = template as NSString
        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))

        for match in matches.reversed() {
            let fullRange = match.range
            let innerRange = match.range(at: 1)
            guard let innerSwiftRange = Range(innerRange, in: template) else { continue }
            let expression = String(template[innerSwiftRange])
            let resolved = resolveExpression(expression)
            result = (result as NSString).replacingCharacters(in: fullRange, with: resolved)
            _ = nsTemplate
        }
        return result
    }

    // MARK: - Expression resolution

    private func resolveExpression(_ expression: String) -> String {
        let parts = expression.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let varName = parts.first else { return "" }

        let rawValue = resolveVariable(varName)

        // Apply filters in order
        var value = rawValue
        for filter in parts.dropFirst() {
            value = applyFilter(filter, to: value, raw: rawValue)
        }
        return value ?? ""
    }

    private func resolveVariable(_ name: String) -> String? {
        let f = exifFields
        switch name.lowercased() {
        case "make":             return (f == nil || f!.showBrand)        ? exif.make            : nil
        case "model":            return (f == nil || f!.showModel)        ? exif.model           : nil
        case "lensmodel":        return (f == nil || f!.showLens)         ? exif.lensModel       : nil
        case "focallength":      return (f == nil || f!.showFocalLength)  ? exif.focalLength     : nil
        case "fnumber":          return (f == nil || f!.showAperture)     ? exif.fNumber         : nil
        case "exposuretime":     return (f == nil || f!.showShutter)      ? exif.exposureTime    : nil
        case "iso":              return (f == nil || f!.showISO)          ? exif.iso             : nil
        case "datetimeoriginal": return (f == nil || f!.showDateTime)     ? exif.dateTimeOriginal: nil
        default:                 return nil
        }
    }

    private func applyFilter(_ filter: String, to value: String?, raw: String?) -> String? {
        if filter.hasPrefix("default(") {
            if let v = value, !v.isEmpty { return v }
            let defaultVal = filter
                .dropFirst("default(".count)
                .dropLast()
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            return defaultVal
        }

        switch filter {
        case "logo":
            // Return brand key for logo lookup (not a string replacement but a signal)
            return value?.lowercased()
        case "shutter":
            return value
        case "datetime":
            return value
        case "upper":
            return value?.uppercased()
        case "lower":
            return value?.lowercased()
        default:
            return value
        }
    }

    // MARK: - Logo resolution helpers

    /// Returns true if the expression resolves to a logo reference.
    public static func isLogoExpression(_ template: String) -> Bool {
        template.contains("|logo")
    }

    /// Extracts the brand key from a logo template expression.
    public func resolveLogoBrand(_ template: String) -> String? {
        let rendered = render(template)
        return rendered.isEmpty ? nil : rendered
    }
}

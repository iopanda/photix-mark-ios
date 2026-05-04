import Foundation
import SwiftUI

// MARK: - Template processors

public enum TemplateProcessors: Sendable {
    case fixed([ProcessorStep])
    case responsive(landscape: [ProcessorStep], portrait: [ProcessorStep], square: [ProcessorStep]?)

    public func steps(for size: CGSize) -> [ProcessorStep] {
        switch self {
        case .fixed(let steps):
            return steps
        case .responsive(let landscape, let portrait, let square):
            let ratio = size.width / max(size.height, 1)
            if abs(ratio - 1.0) < 0.05, let sq = square { return sq }
            return ratio > 1.0 ? landscape : portrait
        }
    }
}

// MARK: - User-configurable options (what the config panel exposes)

public struct ExifFieldOptions: Codable, Equatable, Sendable {
    public var showBrand: Bool = true
    public var showModel: Bool = true
    public var showLens: Bool = true
    public var showFocalLength: Bool = true
    public var showAperture: Bool = true
    public var showShutter: Bool = true
    public var showISO: Bool = true
    public var showDateTime: Bool = true

    public init(
        showBrand: Bool = true, showModel: Bool = true, showLens: Bool = true,
        showFocalLength: Bool = true, showAperture: Bool = true, showShutter: Bool = true,
        showISO: Bool = true, showDateTime: Bool = true
    ) {
        self.showBrand = showBrand; self.showModel = showModel; self.showLens = showLens
        self.showFocalLength = showFocalLength; self.showAperture = showAperture
        self.showShutter = showShutter; self.showISO = showISO; self.showDateTime = showDateTime
    }
}

public struct LogoOptions: Codable, Equatable, Sendable {
    public var enabled: Bool = true
    public var position: LogoPosition = .rightCenter

    public enum LogoPosition: String, Codable, Sendable {
        case rightCenter, rightTop, rightBottom, leftCenter, center
    }

    public init(enabled: Bool = true, position: LogoPosition = .rightCenter) {
        self.enabled = enabled
        self.position = position
    }
}

public struct ColorOptions: Codable, Equatable, Sendable {
    public var textColorHex: String = "#242424"
    public var secondaryTextColorHex: String = "#666666"

    public init(textColorHex: String = "#242424", secondaryTextColorHex: String = "#666666") {
        self.textColorHex = textColorHex
        self.secondaryTextColorHex = secondaryTextColorHex
    }
}

public struct BackgroundOptions: Codable, Equatable, Sendable {
    public var backgroundColorHex: String = "#FFFFFF"

    public init(backgroundColorHex: String = "#FFFFFF") {
        self.backgroundColorHex = backgroundColorHex
    }
}

public struct BorderOptions: Codable, Equatable, Sendable {
    public var enabled: Bool = true
    public var colorHex: String = "#E5E5E5"
    public var radiusFraction: Double = 0.0

    public init(enabled: Bool = true, colorHex: String = "#E5E5E5", radiusFraction: Double = 0.0) {
        self.enabled = enabled; self.colorHex = colorHex; self.radiusFraction = radiusFraction
    }
}

public struct ShadowOptions: Codable, Equatable, Sendable {
    public var enabled: Bool = false
    public var colorHex: String = "#00000026"
    public var radiusFraction: Double = 0.006

    public init(enabled: Bool = false, colorHex: String = "#00000026", radiusFraction: Double = 0.006) {
        self.enabled = enabled; self.colorHex = colorHex; self.radiusFraction = radiusFraction
    }
}

public struct BlurOptions: Codable, Equatable, Sendable {
    public var radiusFraction: Double = 0.03

    public init(radiusFraction: Double = 0.03) {
        self.radiusFraction = radiusFraction
    }
}

public struct LayoutOptions: Codable, Equatable, Sendable {
    public var paddingFraction: Double = 0.03

    public init(paddingFraction: Double = 0.03) {
        self.paddingFraction = paddingFraction
    }
}

public struct TemplateUserOptions: Codable, Equatable, Sendable {
    public var exifFields: ExifFieldOptions
    public var logo: LogoOptions
    public var colors: ColorOptions
    public var background: BackgroundOptions
    public var layout: LayoutOptions
    public var border: BorderOptions?
    public var shadow: ShadowOptions?
    public var blur: BlurOptions?

    public init(
        exifFields: ExifFieldOptions = ExifFieldOptions(),
        logo: LogoOptions = LogoOptions(),
        colors: ColorOptions = ColorOptions(),
        background: BackgroundOptions = BackgroundOptions(),
        layout: LayoutOptions = LayoutOptions(),
        border: BorderOptions? = nil,
        shadow: ShadowOptions? = nil,
        blur: BlurOptions? = nil
    ) {
        self.exifFields = exifFields; self.logo = logo; self.colors = colors
        self.background = background; self.layout = layout
        self.border = border; self.shadow = shadow; self.blur = blur
    }
}

// MARK: - TemplateConfig

public struct TemplateConfig: Identifiable, Sendable {
    public let id: String
    public var name: String
    public var description: String
    public var previewAssetName: String?
    public var processors: TemplateProcessors
    public var defaultOptions: TemplateUserOptions

    public init(
        id: String,
        name: String,
        description: String,
        previewAssetName: String? = nil,
        processors: TemplateProcessors,
        defaultOptions: TemplateUserOptions = TemplateUserOptions()
    ) {
        self.id = id; self.name = name; self.description = description
        self.previewAssetName = previewAssetName; self.processors = processors
        self.defaultOptions = defaultOptions
    }
}

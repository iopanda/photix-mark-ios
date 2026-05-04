import Foundation
import CoreGraphics
import ImageIO
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Resolves brand name → logo CGImage, checking custom uploads first then bundled assets.
public struct LogoResolver {

    /// Known brand name → asset name mapping (mirrors web's logoMapper.ts)
    private static let brandAssetMap: [String: String] = [
        "apple": "logo_apple",
        "canon": "logo_canon",
        "dji": "logo_dji",
        "fujifilm": "logo_fujifilm",
        "fuji": "logo_fujifilm",
        "hasselblad": "logo_hasselblad",
        "huawei": "logo_huawei",
        "leica": "logo_leica",
        "nikon": "logo_nikon",
        "olympus": "logo_olympus",
        "panasonic": "logo_panasonic",
        "pentax": "logo_pentax",
        "ricoh": "logo_ricoh",
        "sony": "logo_sony",
        "xiaomi": "logo_huawei"
    ]

    private let customLogos: [String: Data]

    public init(customLogos: [String: Data] = [:]) {
        self.customLogos = customLogos
    }

    /// Resolves logo for a given brand key (lowercased brand name).
    public func resolve(brand: String?) -> CGImage? {
        guard let brand = brand?.lowercased().trimmingCharacters(in: .whitespaces) else {
            return bundledLogo(named: "logo_default")
        }
        if let data = customLogos[brand], let img = cgImage(from: data) { return img }
        for (key, assetName) in Self.brandAssetMap {
            if brand.contains(key) || key.contains(brand) {
                if let img = bundledLogo(named: assetName) { return img }
            }
        }
        return bundledLogo(named: "logo_default")
    }

    private func bundledLogo(named name: String) -> CGImage? {
        // Assets.xcassets images are compiled into Assets.car and can only be
        // accessed via UIImage(named:) on iOS or NSImage(named:) on macOS.
        // Bundle.main.url(forResource:) does NOT find them.
        #if os(iOS)
        return UIImage(named: name)?.cgImage
        #elseif os(macOS)
        return NSImage(named: name)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return nil
        #endif
    }

    private func cgImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    public static var allKnownBrands: [String] {
        Array(brandAssetMap.keys).sorted()
    }
}

import Foundation

/// Persists custom brand logos to the app's Documents directory.
public final class BrandLogoRepository {

    private let directory: URL

    public init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = docs.appendingPathComponent("BrandLogos", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func save(imageData: Data, for brand: String) throws {
        let url = fileURL(for: brand)
        try imageData.write(to: url)
    }

    public func load(for brand: String) -> Data? {
        let url = fileURL(for: brand)
        return try? Data(contentsOf: url)
    }

    public func delete(for brand: String) throws {
        let url = fileURL(for: brand)
        try FileManager.default.removeItem(at: url)
    }

    public func loadAll() -> [String: Data] {
        var result: [String: Data] = [:]
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return result
        }
        for file in files {
            let brand = file.deletingPathExtension().lastPathComponent
            if let data = try? Data(contentsOf: file) {
                result[brand] = data
            }
        }
        return result
    }

    private func fileURL(for brand: String) -> URL {
        let safeName = brand.lowercased().replacingOccurrences(of: " ", with: "_")
        return directory.appendingPathComponent("\(safeName).png")
    }
}

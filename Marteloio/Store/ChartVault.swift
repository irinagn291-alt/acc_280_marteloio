import Foundation

/// Role: Store. Projects ChartRecord to UserDefaults plus an atomic Application Support file.
/// Isolated by ChartStore. UserDefaults is not Sendable, so this type is not.
struct ChartVault {
    var directory: URL
    var defaults: UserDefaults

    var fileURL: URL {
        directory.appendingPathComponent("chart.json", isDirectory: false)
    }

    var backupURL: URL {
        directory.appendingPathComponent("chart.json.backup", isDirectory: false)
    }

    var catalogCacheURL: URL {
        directory.appendingPathComponent("catalog-cache.json", isDirectory: false)
    }

    func load() -> (record: ChartRecord, warning: StoreWarning?) {
        if let record = decode(defaults.data(forKey: ChartKey.record)) {
            return (record, nil)
        }
        if let record = decode(read(fileURL)) {
            return (record, nil)
        }
        if let record = decode(defaults.data(forKey: ChartKey.backup)) {
            return (record, .recoveredFromBackup)
        }
        if let record = decode(read(backupURL)) {
            return (record, .recoveredFromBackup)
        }
        let hadPayload = defaults.data(forKey: ChartKey.record) != nil
            || FileManager.default.fileExists(atPath: fileURL.path)
        if hadPayload {
            return (.empty, .startedFresh)
        }
        return (.empty, nil)
    }

    func save(_ record: ChartRecord) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try ChartCodec.encode(record)
        if let current = defaults.data(forKey: ChartKey.record) {
            defaults.set(current, forKey: ChartKey.backup)
        }
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.copyItem(at: fileURL, to: backupURL)
        }
        defaults.set(data, forKey: ChartKey.record)
        try data.write(to: fileURL, options: .atomic)
    }

    func saveCatalog(_ titles: [CatalogTitle]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try ChartCodec.encoder().encode(titles)
        try data.write(to: catalogCacheURL, options: .atomic)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var url = catalogCacheURL
        try? url.setResourceValues(values)
    }

    func loadCatalog() -> [CatalogTitle] {
        guard let data = read(catalogCacheURL) else { return [] }
        return (try? ChartCodec.decoder().decode([CatalogTitle].self, from: data)) ?? []
    }

    func wipe() throws {
        defaults.removeObject(forKey: ChartKey.record)
        defaults.removeObject(forKey: ChartKey.backup)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
        if FileManager.default.fileExists(atPath: catalogCacheURL.path) {
            try FileManager.default.removeItem(at: catalogCacheURL)
        }
    }

    func demoPlanted() -> Bool {
        defaults.object(forKey: ChartKey.demo) != nil
    }

    func markDemoPlanted() {
        defaults.set(true, forKey: ChartKey.demo)
    }

    private func decode(_ data: Data?) -> ChartRecord? {
        guard let data else { return nil }
        return try? ChartCodec.decode(data)
    }

    private func read(_ url: URL) -> Data? {
        try? Data(contentsOf: url)
    }
}

enum StoreWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedFresh
}

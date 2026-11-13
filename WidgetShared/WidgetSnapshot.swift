import Foundation
import WidgetKit
import OSLog

struct WidgetCandle: Codable, Equatable, Sendable {
    var open: Double; var high: Double; var low: Double; var close: Double
}

/// A small, read-only projection of the app's saved state. No credentials or full saves are shared.
struct WidgetSnapshot: Codable, Equatable, Sendable {
    var version = 1
    var title: String
    var value: String
    var label: String
    var detail: String
    var footnote: String
    var progress: Double = 0
    var values: [Double] = []
    var symbols: [String] = []
    var candles: [WidgetCandle] = []
    var updatedAt = Date()
    var isEmpty = false

    var isValid: Bool {
        version == 1 && progress.isFinite && (0...1).contains(progress)
            && values.allSatisfy(\.isFinite) && values.count <= 24 && symbols.count <= 6
            && candles.count <= 24 && candles.allSatisfy { c in
                [c.open,c.high,c.low,c.close].allSatisfy(\.isFinite)
                    && c.high >= max(c.open,c.close) && c.low <= min(c.open,c.close)
            }
            && [title,value,label,detail,footnote].allSatisfy { $0.count <= 300 }
    }
    static var empty: WidgetSnapshot {
        WidgetSnapshot(title: WidgetIdentity.displayName, value: "—", label: "Open the app to begin",
                       detail: WidgetIdentity.emptyHint, footnote: "Your progress will appear here", isEmpty: true)
    }
}

enum WidgetStore {
    static let filename = "widget-snapshot-v1.json"
    static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetIdentity.group)?
            .appendingPathComponent(filename)
    }
    static func read(from url: URL? = fileURL) -> WidgetSnapshot? {
        guard let url, let data = try? Data(contentsOf: url), data.count < 64_000,
              let value = try? JSONDecoder().decode(WidgetSnapshot.self, from: data), value.isValid else { return nil }
        return value
    }
    /// Atomic replacement prevents the extension from reading a half-written snapshot.
    @discardableResult static func write(_ value: WidgetSnapshot, to url: URL) throws -> Bool {
        guard value.isValid else { throw CocoaError(.coderInvalidValue) }
        if var old = read(from: url) {
            old.updatedAt = value.updatedAt
            if old == value { return false }
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(value).write(to: url, options: .atomic)
        return true
    }
    static var isIsolatedCapture: Bool {
        let args = ProcessInfo.processInfo.arguments
        let flag = ProcessInfo.processInfo.environment["APPSTORE_SCREENSHOTS"]?.lowercased() ?? ""
        return args.contains("-ReviewScreen") || args.contains("-AppStoreScreenshots") || ["1","true","yes"].contains(flag)
    }
    static func publish(_ value: WidgetSnapshot) {
        // Screenshot fixtures must never replace a user's real widget data.
        guard !isIsolatedCapture, ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        guard let url = fileURL else {
            Logger(subsystem: WidgetIdentity.kind, category: "WidgetSync").error("App Group container unavailable; verify signing entitlements")
            return
        }
        do {
            if try write(value, to: url) { WidgetCenter.shared.reloadTimelines(ofKind: WidgetIdentity.kind) }
        } catch {
            Logger(subsystem: WidgetIdentity.kind, category: "WidgetSync").error("Widget snapshot could not be saved")
        }
    }
}

struct ProgressEntry: TimelineEntry {
    var date: Date
    var snapshot: WidgetSnapshot
}
struct ProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProgressEntry { ProgressEntry(date: Date(), snapshot: .empty) }
    func getSnapshot(in context: Context, completion: @escaping (ProgressEntry) -> Void) {
        completion(entry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressEntry>) -> Void) {
        let value = entry()
        completion(Timeline(entries: [value], policy: .after(value.date.addingTimeInterval(1800))))
    }
    func entry(at date: Date = Date(), from url: URL? = WidgetStore.fileURL) -> ProgressEntry {
        ProgressEntry(date: date, snapshot: WidgetStore.read(from: url) ?? .empty)
    }
}

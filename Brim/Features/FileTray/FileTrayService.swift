import AppKit
import Observation

/// One file held in the tray. The tray stores a reference, never a copy.
struct TrayItem: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let bookmark: Data
    let icon: NSImage

    var name: String { url.lastPathComponent }

    static func == (lhs: TrayItem, rhs: TrayItem) -> Bool { lhs.id == rhs.id }
}

/// Files the user has dropped on the notch. Kept as bookmarks so they survive
/// restarts, and still resolve if a file is moved or renamed.
@Observable
final class FileTrayService {
    private(set) var items: [TrayItem] = []

    /// Oldest items drop off once the tray holds this many.
    let capacity = 30

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "fileTray.bookmarks"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(_ urls: [URL]) {
        let existing = Set(items.map(\.url.standardizedFileURL))
        let added = urls
            .filter { $0.isFileURL && !existing.contains($0.standardizedFileURL) }
            .compactMap { Self.makeItem(for: $0) }
        guard !added.isEmpty else { return }
        items.append(contentsOf: added)
        if items.count > capacity { items.removeFirst(items.count - capacity) }
        save()
    }

    func remove(_ item: TrayItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    func open(_ item: TrayItem) {
        NSWorkspace.shared.open(item.url)
    }

    // MARK: - Persistence

    private func load() {
        let bookmarks = defaults.array(forKey: storageKey) as? [Data] ?? []
        items = bookmarks.compactMap { bookmark in
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: bookmark, options: [.withoutUI],
                                     relativeTo: nil, bookmarkDataIsStale: &isStale),
                  FileManager.default.fileExists(atPath: url.path)
            else { return nil } // the file was deleted: drop it
            return isStale ? Self.makeItem(for: url) : Self.makeItem(for: url, bookmark: bookmark)
        }
        save()
    }

    private func save() {
        defaults.set(items.map(\.bookmark), forKey: storageKey)
    }

    private static func makeItem(for url: URL, bookmark: Data? = nil) -> TrayItem? {
        guard let bookmark = bookmark ?? (try? url.bookmarkData()) else { return nil }
        return TrayItem(id: UUID(), url: url, bookmark: bookmark,
                        icon: NSWorkspace.shared.icon(forFile: url.path))
    }
}

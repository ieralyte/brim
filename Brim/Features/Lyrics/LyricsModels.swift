import Foundation

/// One timed line of lyrics. Empty `text` marks an instrumental gap.
nonisolated struct LyricLine: Equatable, Sendable {
    let time: TimeInterval
    let text: String
}

/// What LRCLIB knows about a song.
nonisolated enum LyricsResult: Equatable, Sendable {
    case synced([LyricLine])
    /// Lyrics exist but without timings, so Brim can't follow along.
    case unsynced([String])
    case instrumental
    case notFound
}

/// Parses LRC text: lines like `[01:23.45] words`, possibly with several timestamps
/// per line. Metadata tags such as `[ar:Artist]` are ignored.
nonisolated enum LRCParser {
    private static let timestamp = #/\[(\d{1,3}):(\d{1,2}(?:[.:]\d{1,3})?)\]/#

    static func parse(_ lrc: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        for rawLine in lrc.split(whereSeparator: \.isNewline) {
            let line = String(rawLine)
            let stamps = line.matches(of: timestamp)
            guard let last = stamps.last else { continue }
            let text = String(line[last.range.upperBound...]).trimmingCharacters(in: .whitespaces)
            for stamp in stamps {
                guard let minutes = Double(stamp.output.1),
                      let seconds = Double(stamp.output.2.replacingOccurrences(of: ":", with: "."))
                else { continue }
                lines.append(LyricLine(time: minutes * 60 + seconds, text: text))
            }
        }
        return lines.sorted { $0.time < $1.time }
    }
}

// Writes App Store demo data in the app's real storage format.
// Built by build.sh together with the app's own model/storage sources,
// so the JSON is produced by the same Codable code the app decodes with.
//
// Usage: seed <en|de> <outDir>
//   <outDir>/Notes/*.json, <outDir>/.index/tags/*.json, <outDir>/tags.json

import Foundation

struct DemoDay {
    /// Preferred position in the date list (0 = today). Mapped to a real date by `demoDates`.
    let slot: Int
    let blocks: [Block]
}

struct DemoContent {
    let tags: [Tag]
    let days: [DemoDay]
}

/// Eight distinct days, all inside the current month, today first.
/// Prefers past days; fills with upcoming days when today is early in the month.
func demoDates(count: Int, today: Date = Date(), calendar: Calendar = .current) -> [Date] {
    let start = calendar.startOfDay(for: today)
    let month = calendar.component(.month, from: start)
    let preferred = [0, -1, -3, -5, -6, -8, -9, -11, 1, 2, 4, 5, 7, 8, 10, 12, 14]
    var result: [Date] = []
    for offset in preferred where result.count < count {
        guard let d = calendar.date(byAdding: .day, value: offset, to: start),
              calendar.component(.month, from: d) == month else { continue }
        result.append(d)
    }
    var extra = 15
    while result.count < count, extra < 31 {
        if let d = calendar.date(byAdding: .day, value: extra, to: start),
           calendar.component(.month, from: d) == month { result.append(d) }
        extra += 1
    }
    precondition(result.count == count, "could not place \(count) days in the current month")
    return result
}

func todo(_ text: String, done: Bool, id: String, due: Date? = nil, tags: [UUID] = []) -> Block {
    Block(text: text, tagIds: tags, content: .todo(TodoBlockContent(
        isCompleted: done, remindersId: "demo-\(id)", dueDate: due, hasTime: false
    )))
}

func note(_ text: String, _ tags: [UUID] = []) -> Block {
    Block(text: text, tagIds: tags)
}

@main
struct Seed {
    static func main() async throws {
        let args = CommandLine.arguments
        guard args.count == 3, ["en", "de"].contains(args[1]) else {
            FileHandle.standardError.write(Data("usage: seed <en|de> <outDir>\n".utf8))
            exit(2)
        }
        let out = URL(fileURLWithPath: args[2], isDirectory: true)
        let fm = FileManager.default
        for sub in ["Notes", ".index", "tags.json"] {
            try? fm.removeItem(at: out.appendingPathComponent(sub))
        }
        try fm.createDirectory(at: out, withIntermediateDirectories: true)

        let dates = demoDates(count: 8)
        let content = args[1] == "en" ? englishContent(dates: dates) : germanContent(dates: dates)

        // Same encoder as TagStore.Disk (JSONEncoder defaults).
        try JSONEncoder().encode(content.tags).write(to: out.appendingPathComponent("tags.json"))

        let store = NotesStore(root: out)
        for day in content.days {
            try await store.save(day.blocks, date: dates[day.slot])
        }

        // Read everything back through the app's own loader as a self-check.
        var blockCount = 0
        for day in content.days {
            blockCount += try await store.load(date: dates[day.slot]).count
        }
        let untagged = await store.untaggedNotes().flatMap(\.blocks).count
        print("seeded \(args[1]): \(content.days.count) days, \(blockCount) blocks, \(content.tags.count) tags, \(untagged) untagged → \(out.path)")
    }
}

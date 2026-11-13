import Foundation

struct Platform: Codable, Equatable, Identifiable {
    var id: Int
    var x: Double
    var width: Double
    var perfect: Bool
}

struct Placement: Codable, Equatable, Identifiable {
    var id: Int
    var offset: Double
    var accuracy: Double
    var remaining: Double
    var perfect: Bool
    var missed: Bool
    var restored: Bool
}

struct GameRun: Codable, Equatable, Identifiable {
    var id = UUID()
    var startedAt = Date()
    var seed: UInt64
    var dailyKey: String?
    var location: Int
    var skin: Int
    var platforms = [Platform(id: 0, x: 160, width: 180, perfect: false)]
    var placements: [Placement] = []
    var streak = 0
    var bestStreak = 0
    var finished = false
    var elapsed: Double = 0

    var floors: Int { platforms.count - 1 }
    var top: Platform { platforms.last! }
    var accuracy: Double { placements.isEmpty ? 0 : placements.map(\.accuracy).reduce(0, +) / Double(placements.count) }
    var perfectCount: Int { placements.filter(\.perfect).count }
    var speed: Double { min(205, 76 + Double(floors) * 4.4) * (0.92 + Double(randomWord(floor: floors) % 161) / 1000) }
    var fromLeft: Bool { randomWord(floor: floors) & 1 == 0 }

    func randomWord(floor: Int) -> UInt64 {
        var n = seed &+ UInt64(floor) &* 0x9E3779B97F4A7C15
        n = (n ^ (n >> 30)) &* 0xBF58476D1CE4E5B9
        n = (n ^ (n >> 27)) &* 0x94D049BB133111EB
        return n ^ (n >> 31)
    }

    func movingX(at time: Double) -> Double {
        let travel = 320.0
        let distance = (max(0, time) * speed).truncatingRemainder(dividingBy: travel * 2)
        let x = distance <= travel ? distance : travel * 2 - distance
        return fromLeft ? x : travel - x
    }

    @discardableResult mutating func place(at x: Double) -> Placement? {
        guard !finished, x.isFinite else { return nil }
        let previous = top
        let offset = x - previous.x
        let overlap = max(0, previous.width - abs(offset))
        let missed = overlap <= 0
        let perfect = !missed && abs(offset) <= 6
        streak = perfect ? streak + 1 : 0
        bestStreak = max(bestStreak, streak)
        let restored = perfect && streak.isMultiple(of: 5) && previous.width < 180
        let width = missed ? 0 : perfect ? min(180, previous.width + (restored ? 12 : 0)) : overlap
        let placement = Placement(id: placements.count + 1, offset: offset,
                                  accuracy: perfect ? 1 : overlap / previous.width,
                                  remaining: width, perfect: perfect, missed: missed, restored: restored)
        placements.append(placement)
        if missed { finished = true }
        else {
            platforms.append(Platform(id: platforms.count, x: perfect ? previous.x : (x + previous.x) / 2,
                                      width: width, perfect: perfect))
        }
        elapsed = 0
        return placement
    }

    static func dayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    static func new(daily: Bool, location: Int, skin: Int, date: Date = Date()) -> GameRun {
        let key = dayKey(date)
        return GameRun(startedAt: date, seed: daily ? UInt64(key)! : UInt64.random(in: 1...UInt64.max),
                       dailyKey: daily ? key : nil, location: location, skin: skin)
    }
}

struct Preferences: Codable, Equatable {
    var sound = true
    var haptics = true
    var reduceMotion = false
    var location = 0
    var skin = 0
}

struct ProgressData: Codable, Equatable {
    var version = 1
    var preferences = Preferences()
    var history: [GameRun] = []
    var active: GameRun?
    var attempts = 0
    var totalFloors = 0
    var totalPerfect = 0
    var bestFloors = 0
    var bestAccuracy: Double = 0
    var bestStreak = 0
    var completedDays: [String] = []

    mutating func record(_ run: GameRun) {
        guard run.finished, !history.contains(where: { $0.id == run.id }) else { return }
        attempts += 1
        totalFloors += run.floors
        totalPerfect += run.perfectCount
        bestFloors = max(bestFloors, run.floors)
        bestAccuracy = max(bestAccuracy, run.accuracy)
        bestStreak = max(bestStreak, run.bestStreak)
        if let day = run.dailyKey, run.floors >= 20, !completedDays.contains(day) {
            completedDays.append(day)
        }
        history.insert(run, at: 0)
        history = Array(history.prefix(50))
        active = nil
    }

    func locationUnlocked(_ index: Int) -> Bool { bestFloors >= [0, 10, 20, 35][index] }
    func skinUnlocked(_ index: Int) -> Bool {
        switch index {
        case 1: totalPerfect >= 30
        case 2: bestFloors >= 10
        case 3: bestStreak >= 15
        default: true
        }
    }
}

struct LocalStorage {
    var url: URL
    func load() throws -> ProgressData {
        guard FileManager.default.fileExists(atPath: url.path) else { return ProgressData() }
        let value = try JSONDecoder().decode(ProgressData.self, from: Data(contentsOf: url))
        guard value.version == 1,
              (0...3).contains(value.preferences.location), (0...3).contains(value.preferences.skin),
              value.history.allSatisfy({ valid($0) && $0.finished }),
              value.active.map({ valid($0) && !$0.finished }) ?? true else {
            throw CocoaError(.coderReadCorrupt)
        }
        return value
    }
    private func valid(_ run: GameRun) -> Bool {
        !run.platforms.isEmpty && (0...3).contains(run.location) && (0...3).contains(run.skin)
            && run.elapsed.isFinite && run.elapsed >= 0
            && run.platforms.enumerated().allSatisfy { index, platform in
                platform.id == index && platform.x.isFinite && (0...320).contains(platform.x)
                    && platform.width.isFinite && platform.width > 0 && platform.width <= 180
            }
            && run.placements.enumerated().allSatisfy { index, placement in
                placement.id == index + 1 && index < run.platforms.count
                    && (0...1).contains(placement.accuracy) && (0...180).contains(placement.remaining) && placement.offset.isFinite
            }
    }
    func save(_ value: ProgressData) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(value).write(to: url, options: .atomic)
    }
}

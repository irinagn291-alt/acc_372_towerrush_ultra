import XCTest
@testable import TowerRush

final class GameEngineTests: XCTestCase {
    func testOverlapCutsWidthAndMovesCentre() {
        var run = GameRun(seed: 42, location: 0, skin: 0)
        let p = run.place(at: 200)!
        XCTAssertEqual(p.remaining, 140)
        XCTAssertEqual(p.accuracy, 140.0 / 180, accuracy: 0.0001)
        XCTAssertEqual(run.top.x, 180)
        XCTAssertEqual(run.floors, 1)
        XCTAssertEqual(run.streak, 0)
    }
    func testTouchingEdgesIsMissAndTerminal() {
        var run = GameRun(seed: 42, location: 0, skin: 0)
        XCTAssertTrue(run.place(at: 340)!.missed)
        XCTAssertTrue(run.finished)
        XCTAssertEqual(run.floors, 0)
        XCTAssertEqual(run.accuracy, 0)
        XCTAssertNil(run.place(at: 160))
    }
    func testPerfectToleranceAndSnap() {
        var run = GameRun(seed: 1, location: 0, skin: 0)
        XCTAssertTrue(run.place(at: 166)!.perfect)
        XCTAssertEqual(run.top.x, 160)
        XCTAssertEqual(run.top.width, 180)
        XCTAssertFalse(run.place(at: 166.01)!.perfect)
        XCTAssertEqual(run.streak, 0)
    }
    func testFivePerfectRestoresWidthWithCap() {
        var run = GameRun(seed: 1, location: 0, skin: 0)
        run.place(at: 200)
        for _ in 0..<4 { XCTAssertFalse(run.place(at: run.top.x)!.restored) }
        XCTAssertTrue(run.place(at: run.top.x)!.restored)
        XCTAssertEqual(run.top.width, 152)
        for _ in 0..<25 { run.place(at: run.top.x) }
        XCTAssertEqual(run.top.width, 180)
        XCTAssertEqual(run.bestStreak, 30)
    }
    func testNarrowPlatformMissCannotCountAsPerfect() {
        var run = GameRun(seed: 1, location: 0, skin: 0)
        run.place(at: 338)
        XCTAssertEqual(run.top.width, 2)
        let miss = run.place(at: run.top.x + 3)!
        XCTAssertTrue(miss.missed)
        XCTAssertFalse(miss.perfect)
        XCTAssertEqual(miss.accuracy, 0)
    }
    func testInvalidSavedLocationFailsSafely() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storage = LocalStorage(url: folder.appendingPathComponent("progress.json"))
        var progress = ProgressData()
        progress.active = GameRun(seed: 1, location: 99, skin: 0)
        try storage.save(progress)
        XCTAssertThrowsError(try storage.load())
    }
    func testMeanIncludesMiss() {
        var run = GameRun(seed: 1, location: 0, skin: 0)
        run.place(at: 160)
        run.place(at: 1000)
        XCTAssertEqual(run.accuracy, 0.5)
    }
    func testDailySequenceIsUTCAndReproducible() {
        let date = ISO8601DateFormatter().date(from: "2026-11-13T23:59:59Z")!
        var a = GameRun.new(daily: true, location: 0, skin: 0, date: date)
        var b = GameRun.new(daily: true, location: 3, skin: 2, date: date)
        XCTAssertEqual(a.dailyKey, "20261113")
        XCTAssertEqual(a.seed, 20261113)
        for floor in 0..<80 {
            XCTAssertEqual(a.randomWord(floor: floor), b.randomWord(floor: floor))
            XCTAssertEqual(a.movingX(at: 1.25), b.movingX(at: 1.25))
            XCTAssertLessThanOrEqual(a.speed, 205 * 1.08)
            a.place(at: a.top.x); b.place(at: b.top.x)
        }
        XCTAssertNotEqual(a.seed, GameRun.new(daily: true, location: 0, skin: 0, date: date.addingTimeInterval(1)).seed)
    }
    func testMovementReflectsAtBounds() {
        let run = GameRun(seed: 9, location: 0, skin: 0)
        XCTAssertEqual(run.movingX(at: 0), run.fromLeft ? 0 : 320)
        XCTAssertEqual(run.movingX(at: 320 / run.speed), run.fromLeft ? 320 : 0, accuracy: 0.00001)
        XCTAssertEqual(run.movingX(at: 640 / run.speed), run.movingX(at: 0), accuracy: 0.00001)
        XCTAssertEqual(run.movingX(at: -100), run.movingX(at: 0))
    }
    func testProgressAndUnlocksAreAchievementBasedAndIdempotent() {
        var progress = ProgressData()
        XCTAssertFalse(progress.locationUnlocked(1))
        XCTAssertFalse(progress.skinUnlocked(3))
        var run = GameRun.new(daily: true, location: 0, skin: 0)
        for _ in 0..<35 { run.place(at: 160) }
        run.place(at: 1000)
        progress.record(run); progress.record(run)
        XCTAssertEqual(progress.attempts, 1)
        XCTAssertEqual(progress.totalFloors, 35)
        XCTAssertEqual(progress.totalPerfect, 35)
        XCTAssertEqual(progress.completedDays, [run.dailyKey!])
        for index in 0...3 { XCTAssertTrue(progress.locationUnlocked(index)); XCTAssertTrue(progress.skinUnlocked(index)) }
    }
    func testIncompleteRunDoesNotRecord() {
        var progress = ProgressData()
        progress.record(GameRun(seed: 0, location: 0, skin: 0))
        XCTAssertEqual(progress.attempts, 0)
    }
    func testStorageRoundTripAndCorruption() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storage = LocalStorage(url: folder.appendingPathComponent("progress.json"))
        XCTAssertEqual(try storage.load(), ProgressData())
        var progress = ProgressData()
        var run = GameRun(seed: 200, location: 1, skin: 2)
        run.place(at: 180); run.elapsed = 1.2
        progress.active = run
        progress.preferences.sound = false
        try storage.save(progress)
        XCTAssertEqual(try storage.load(), progress)
        try Data("broken".utf8).write(to: storage.url)
        XCTAssertThrowsError(try storage.load())
    }
    @MainActor func testPauseResumePersistsAndRestoresPaused() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storage = LocalStorage(url: folder.appendingPathComponent("progress.json"))
        let store = TowerStore(storage: storage)
        store.load(); store.start(daily: true)
        store.turnStart = Date().addingTimeInterval(-0.8)
        store.pause()
        let frozen = store.elapsed()
        XCTAssertTrue(store.paused)
        XCTAssertEqual(store.elapsed(at: Date().addingTimeInterval(10)), frozen, accuracy: 0.001)
        let restored = TowerStore(storage: storage); restored.load()
        XCTAssertTrue(restored.paused)
        XCTAssertEqual(restored.game, store.game)
        restored.resume()
        XCTAssertFalse(restored.paused)
        XCTAssertEqual(restored.elapsed(), frozen, accuracy: 0.05)
    }
    @MainActor func testFailedWriteCanRetryWithoutLosingInMemoryProgress() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        try Data("obstruction".utf8).write(to: folder)
        let storage = LocalStorage(url: folder.appendingPathComponent("progress.json"))
        let store = TowerStore(storage: storage)
        store.start(daily: false)
        XCTAssertNotNil(store.saveError)
        let runID = store.game?.id
        try FileManager.default.removeItem(at: folder)
        store.persist()
        XCTAssertNil(store.saveError)
        XCTAssertEqual(try storage.load().active?.id, runID)
    }
    @MainActor func testCorruptSaveIsNotOverwritten() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let storage = LocalStorage(url: folder.appendingPathComponent("progress.json"))
        let original = Data("invalid file retained".utf8)
        try original.write(to: storage.url)
        let store = TowerStore(storage: storage); store.load(); store.persist()
        XCTAssertTrue(store.loadFailed)
        XCTAssertNotNil(store.saveError)
        XCTAssertEqual(try Data(contentsOf: storage.url), original)
    }
}

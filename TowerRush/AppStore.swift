import SwiftUI
import Observation
import AudioToolbox

@MainActor @Observable final class TowerStore {
    var data = ProgressData()
    var loaded = false
    var saveError: String?
    var loadFailed = false
    var game: GameRun?
    var paused = true
    var turnStart = Date()
    var result: GameRun?
    var feedback = "Find your rhythm"
    var flash = false
    var tab = 0
    private let storage: LocalStorage

    #if DEBUG && targetEnvironment(simulator)
    let captureScreen: String?
    #endif

    init(storage: LocalStorage? = nil) {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        #if DEBUG && targetEnvironment(simulator)
        let screen = CaptureLaunch.screen
        captureScreen = screen
        if screen != nil {
            self.storage = LocalStorage(url: folder.appendingPathComponent("TowerRush/screenshot-demo/progress.json"))
            return
        }
        #endif
        self.storage = storage ?? LocalStorage(url: folder.appendingPathComponent("TowerRush/progress.json"))
    }

    func load() {
        #if DEBUG && targetEnvironment(simulator)
        if let captureScreen {
            prepareCapture(captureScreen)
            loaded = true
            return
        }
        #endif
        do {
            data = try storage.load()
            game = data.active
            paused = true
            loadFailed = false
            saveError = nil; publishWidget()
        } catch {
            loadFailed = true
            saveError = "Your saved progress could not be opened. Retry to keep your original file safe."
        }
        loaded = true
    }

    func persist() {
        guard !loadFailed else { return }
        do { try storage.save(data); saveError = nil; publishWidget() }
        catch { saveError = "Progress could not be saved. Keep the app open and try again." }
    }

    func start(daily: Bool) {
        game = .new(daily: daily, location: data.preferences.location, skin: data.preferences.skin)
        result = nil
        paused = false
        turnStart = Date()
        feedback = daily ? "Today's shared sequence" : "Line it up. Make it count."
        data.active = game
        persist()
    }

    func elapsed(at date: Date = Date()) -> Double {
        #if DEBUG && targetEnvironment(simulator)
        if captureScreen != nil { return game?.elapsed ?? 0 }
        #endif
        return (game?.elapsed ?? 0) + (paused ? 0 : max(0, date.timeIntervalSince(turnStart)))
    }

    func pause() {
        guard var run = game, !paused else { return }
        run.elapsed = elapsed()
        game = run
        paused = true
        data.active = run
        persist()
    }

    func resume() { guard game != nil else { return }; turnStart = Date(); paused = false }

    func place() {
        guard var run = game, !paused else { return }
        let x = run.movingX(at: elapsed())
        guard let placement = run.place(at: x) else { return }
        turnStart = Date()
        game = run
        if data.preferences.haptics {
            if placement.perfect { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            else { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        if data.preferences.sound { AudioServicesPlaySystemSound(placement.missed ? 1053 : placement.perfect ? 1057 : 1104) }
        flash = placement.perfect
        feedback = placement.missed ? "One more climb?" : placement.restored ? "Perfect five · width restored" : placement.perfect ? "Perfect placement" : "\(Int((placement.accuracy * 100).rounded()))% aligned"
        if run.finished { finish(run) }
        else { data.active = run; persist() }
    }

    func finish(_ run: GameRun) {
        data.record(run)
        result = run
        game = nil
        paused = true
        persist()
    }

    func endAttempt() {
        guard var run = game else { return }
        run.finished = true
        finish(run)
    }

    func setLocation(_ value: Int) {
        guard data.locationUnlocked(value) else { return }
        data.preferences.location = value
        persist()
    }

    func setSkin(_ value: Int) {
        guard data.skinUnlocked(value) else { return }
        data.preferences.skin = value
        persist()
    }
}

#if DEBUG && targetEnvironment(simulator)
private enum CaptureLaunch {
    static let screens = ["play", "climb", "result", "placement-review", "locations", "collection", "profile"]

    static var screen: String? {
        let process = ProcessInfo.processInfo
        let arguments = process.arguments
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
            return arguments[index + 1]
        }
        if let key = value(after: "-ReviewScreen"), screens.contains(key) { return key }
        let environmentFlag = process.environment["APPSTORE_SCREENSHOTS"]?.lowercased()
        let enabled = arguments.contains("-AppStoreScreenshots") ||
            (environmentFlag != nil && !["", "0", "false", "no"].contains(environmentFlag!))
        guard enabled,
              let rawIndex = value(after: "-AppStoreScreenshotScreen") ?? process.environment["APPSTORE_SCREENSHOT_SCREEN"],
              let index = Int(rawIndex), screens.indices.contains(index) else { return nil }
        return screens[index]
    }
}

private extension TowerStore {
    func prepareCapture(_ screen: String) {
        func run(floors: Int, daily: Bool, missed: Bool, date: Date) -> GameRun {
            var run = GameRun.new(daily: daily, location: 0, skin: 0, date: date)
            for index in 0..<floors {
                let offsets: [Double] = [0, 3, 12, -9, 0, 0, 8, -8]
                _ = run.place(at: run.top.x + offsets[index % offsets.count])
            }
            if missed {
                _ = run.place(at: run.top.x < 160 ? 320 : 0)
            } else {
                run.finished = true
            }
            return run
        }

        var demo = ProgressData()
        demo.preferences.sound = false
        demo.preferences.haptics = false
        demo.preferences.reduceMotion = true
        let now = Date()
        let earlier = now.addingTimeInterval(-86_400)
        if screen == "profile" {
            demo.record(run(floors: 20, daily: true, missed: false, date: earlier))
            demo.record(run(floors: 8, daily: false, missed: true, date: now.addingTimeInterval(-3_600)))
        }
        let completed = run(floors: 12, daily: false, missed: true, date: now)
        demo.record(completed)
        data = demo
        tab = ["locations": 1, "collection": 2, "profile": 3][screen] ?? 0
        if screen == "result" || screen == "placement-review" {
            result = completed
        } else if screen == "climb" {
            var active = GameRun.new(daily: false, location: 0, skin: 0, date: now)
            for offset in [0.0, 3, 12, -9, 0, 0, 8, 0] {
                _ = active.place(at: active.top.x + offset)
            }
            let movingX = min(320, active.top.x + 20)
            active.elapsed = (active.fromLeft ? movingX : 320 - movingX) / active.speed
            game = active
            data.active = active
            paused = false
            feedback = "Perfect placement"
            flash = true
        }
    }
}
#endif

@main struct TowerRushApp: App {
    @State private var store = TowerStore()
    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .preferredColorScheme(.dark)
                .environment(\.locale, Locale(identifier: "en_GB"))
                .environment(\.layoutDirection, .leftToRight)
        }
    }
}

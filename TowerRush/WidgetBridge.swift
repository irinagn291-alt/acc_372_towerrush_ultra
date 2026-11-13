import Foundation

extension TowerStore {
    var widgetSnapshot: WidgetSnapshot {
        let detail = data.active.map { "Continue your tower · \($0.floors) floors" } ?? "\(data.attempts) \(data.attempts == 1 ? "climb" : "climbs") · best streak \(data.bestStreak)"
        return WidgetSnapshot(title: "Your skyline", value: "\(data.bestFloors)", label: "personal best floors",
            detail: detail, footnote: "Next milestone: \(data.bestFloors < 10 ? 10 : data.bestFloors < 20 ? 20 : data.bestFloors < 35 ? 35 : ((data.bestFloors/10)+1)*10) floors",
            progress: min(1,Double(data.bestFloors)/35))
    }
    func publishWidget() { WidgetStore.publish(widgetSnapshot) }
}

#if DEBUG && targetEnvironment(simulator)
extension TowerStore {
    /// Only explicit UI-test launches in disposable simulators can mutate this fixture.
    func applyWidgetQA(_ url: URL) {
        guard ProcessInfo.processInfo.arguments.contains("-WidgetQA"),
              URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name == "qa" && ["1", "2"].contains($0.value ?? "") }) == true else { return }
        let secondUpdate = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name == "qa" && $0.value == "2" }) == true
        var run = GameRun.new(daily: false, location: 0, skin: 0)
        for _ in 0..<(secondUpdate ? 4 : 3) { run.place(at: run.top.x) }
        run.place(at: run.top.x + run.top.width + 1)
        data.record(run); persist()
    }
}
#endif

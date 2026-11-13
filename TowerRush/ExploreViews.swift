import SwiftUI

struct LocationsView: View {
    @Bindable var store: TowerStore
    private let requirements = [0, 10, 20, 35]
    private let descriptions = ["A thousand windows. One way up.", "Warm horizons and quiet ambition.", "Clear skies. Sharper focus.", "Your skyline, beyond the sky."]
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PageHeading(eyebrow: "Explore", title: "Higher horizons", subtitle: "Four places to leave your mark.")
                ForEach(0..<4) { index in
                    let unlocked = store.data.locationUnlocked(index)
                    let selected = store.data.preferences.location == index
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack(alignment: .topLeading) {
                            WorldBackdrop(location: index)
                            HStack {
                                Image(systemName: Ink.symbols[index]).font(.system(size: 32, weight: .light))
                                Spacer()
                                Text(String(format: "%02d", index + 1)).font(.system(size: 48, weight: .light, design: .rounded)).foregroundStyle(.white.opacity(0.2))
                            }.padding(20)
                            VStack(alignment: .leading, spacing: 6) {
                                Spacer()
                                Text(Ink.locations[index]).font(.system(size: 26, weight: .bold, design: .rounded))
                                Text(descriptions[index]).font(.system(size: 13)).foregroundStyle(Ink.muted)
                            }.padding(20)
                        }.frame(height: 184)
                        VStack(alignment: .leading, spacing: 12) {
                            if unlocked {
                                Button { store.setLocation(index) } label: {
                                    Label(selected ? "Selected" : "Build here", systemImage: selected ? "checkmark.circle.fill" : "arrow.up.right")
                                        .font(.system(size: 16, weight: .bold)).foregroundStyle(selected ? Ink.green : Ink.gold)
                                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                }.buttonStyle(.plain)
                            } else {
                                Label("Reach \(requirements[index]) floors to unlock", systemImage: "lock.fill").font(.system(size: 15, weight: .semibold))
                                ProgressView(value: Double(min(store.data.bestFloors, requirements[index])), total: Double(requirements[index])).tint(Ink.gold)
                                Text("\(store.data.bestFloors) / \(requirements[index]) floors").font(.system(size: 12)).foregroundStyle(Ink.muted).monospacedDigit()
                            }
                        }.padding(16).background(Ink.panel)
                    }.clipShape(RoundedRectangle(cornerRadius: 24))
                    if index < 3 {
                        VStack(spacing: 6) { ForEach(0..<3) { _ in Circle().fill(Ink.gold.opacity(0.3)).frame(width: 4, height: 4) } }.accessibilityHidden(true)
                    }
                }
            }.padding(16).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(Ink.background)
    }
}

struct CollectionView: View {
    @Bindable var store: TowerStore
    @State private var preview = 0
    @State private var angle = 0.0
    @State private var initialisedPreview = false
    @Environment(\.accessibilityReduceMotion) private var systemReduced
    private var reduced: Bool { systemReduced || store.data.preferences.reduceMotion }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PageHeading(eyebrow: "Collection", title: "Make it yours", subtitle: "Earn every finish. Build your own style.")
                ZStack(alignment: .bottom) {
                    TowerScene(platforms: TowerScene.illustration, skin: preview, location: store.data.preferences.location, fullTower: true, rotation: reduced ? 0 : angle).frame(height: 320)
                        .gesture(DragGesture().onChanged { value in if !reduced { angle = max(-18, min(18, value.translation.width / 8)) } }.onEnded { _ in withAnimation(.easeOut(duration: 0.2)) { angle = 0 } })
                    Text(Ink.skinNames[preview].uppercased()).font(.system(size: 12, weight: .bold)).tracking(3).padding(.bottom, 34)
                }
                Text(reduced ? "Tap a finish to preview" : "Drag to turn · tap a finish to preview").font(.system(size: 12)).foregroundStyle(Ink.muted)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(0..<4) { index in
                        Button { preview = index } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "square.stack.3d.up.fill").font(.system(size: 28)).foregroundStyle(Ink.skins[index])
                                    Spacer()
                                    Image(systemName: store.data.skinUnlocked(index) ? (store.data.preferences.skin == index ? "checkmark.circle.fill" : "circle") : "lock.fill")
                                        .foregroundStyle(store.data.preferences.skin == index ? Ink.green : Ink.muted)
                                }
                                Text(Ink.skinNames[index]).font(.system(size: 17, weight: .bold))
                                Text(store.data.skinUnlocked(index) ? "Unlocked" : "Achievement finish").font(.system(size: 12)).foregroundStyle(Ink.muted)
                            }.panel().overlay(RoundedRectangle(cornerRadius: 20).stroke(preview == index ? Ink.skins[index] : .clear, lineWidth: 2))
                        }.buttonStyle(.plain).accessibilityLabel("Preview \(Ink.skinNames[index]), \(store.data.skinUnlocked(index) ? "unlocked" : "locked")")
                            .accessibilityValue(preview == index ? "Previewing" : "")
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Label(Ink.skinNames[preview], systemImage: store.data.skinUnlocked(preview) ? "checkmark.seal" : "lock").font(.headline)
                    Text(Ink.skinRules[preview]).font(.system(size: 15)).foregroundStyle(Ink.muted)
                    if store.data.skinUnlocked(preview) {
                        GoldButton(title: store.data.preferences.skin == preview ? "Equipped" : "Use this finish", icon: "checkmark") { store.setSkin(preview) }
                    } else {
                        Text(progressText).font(.system(size: 13, weight: .semibold)).foregroundStyle(Ink.gold)
                    }
                }.panel()
            }.padding(16).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(Ink.background).onAppear {
            if !initialisedPreview {
                preview = store.data.preferences.skin
                #if DEBUG && targetEnvironment(simulator)
                if store.captureScreen == "collection" { preview = 3 }
                #endif
                initialisedPreview = true
            }
        }
    }
    private var progressText: String {
        switch preview {
        case 1: "\(min(30, store.data.totalPerfect)) / 30 perfect placements"
        case 2: "\(min(10, store.data.bestFloors)) / 10 floors"
        default: "\(min(15, store.data.bestStreak)) / 15 consecutive perfect placements"
        }
    }
}

struct ProfileView: View {
    @Bindable var store: TowerStore
    @State private var selectedRun: GameRun?
    @State private var showRules = false
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PageHeading(eyebrow: "Your journey", title: "Keep on climbing", subtitle: "Small improvements. Taller towers.")
                HStack {
                    Metric(value: "\(store.data.attempts)", label: "ATTEMPTS")
                    Metric(value: "\(store.data.totalFloors)", label: "TOTAL FLOORS", accent: Ink.gold)
                    Metric(value: "\(store.data.totalPerfect)", label: "PERFECT")
                }.panel()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Personal bests").font(.headline)
                    recordRow("Highest tower", "\(store.data.bestFloors) floors", "arrow.up")
                    recordRow("Best accuracy", "\(Int(store.data.bestAccuracy * 100))%", "scope")
                    recordRow("Perfect streak", "\(store.data.bestStreak) in a row", "sparkles")
                    recordRow("Daily goals", "\(store.data.completedDays.count) completed", "sun.max")
                }.panel()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Make yourself comfortable").font(.headline).padding(.bottom, 8)
                    Toggle("Sound effects", isOn: $store.data.preferences.sound).frame(minHeight: 44)
                    Toggle("Haptic feedback", isOn: $store.data.preferences.haptics).frame(minHeight: 44)
                    Toggle("Reduce motion", isOn: $store.data.preferences.reduceMotion).frame(minHeight: 44)
                    Text("System Reduce Motion is also respected. Platforms still move so you can time each placement.").font(.system(size: 12)).foregroundStyle(Ink.muted)
                }.tint(Ink.gold).panel()
                    .onChange(of: store.data.preferences) { _, _ in store.persist() }
                VStack(alignment: .leading, spacing: 14) {
                    HStack { Text("Recent climbs").font(.headline); Spacer(); Text("Last 50").font(.system(size: 12)).foregroundStyle(Ink.muted) }
                    if store.data.history.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "square.stack.3d.up").font(.title).foregroundStyle(Ink.gold)
                            Text("Your story starts with one floor.").font(.system(size: 15, weight: .semibold))
                            Button("Start building") { store.tab = 0 }.frame(minHeight: 44).foregroundStyle(Ink.gold)
                        }.frame(maxWidth: .infinity).padding(.vertical, 16)
                    } else {
                        ForEach(store.data.history) { run in
                            Button { selectedRun = run } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: run.dailyKey == nil ? "square.stack.3d.up" : "sun.max").foregroundStyle(Ink.gold).frame(width: 32)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(run.floors) floors · \(Int(run.accuracy * 100))% accuracy").font(.system(size: 15, weight: .semibold)).monospacedDigit()
                                        Text(run.startedAt.formatted(.dateTime.locale(Locale(identifier: "en_GB")).day().month(.abbreviated).year().hour().minute())).font(.system(size: 12)).foregroundStyle(Ink.muted)
                                    }
                                    Spacer(); Image(systemName: "chevron.right").font(.caption)
                                }.frame(minHeight: 52)
                            }.buttonStyle(.plain)
                            if run.id != store.data.history.last?.id { Divider() }
                        }
                    }
                }.panel()
                QuietButton(title: "How to build", icon: "questionmark.circle") { showRules = true }
                VStack(spacing: 6) {
                    Label("Made for offline play", systemImage: "checkmark.icloud").font(.system(size: 13, weight: .semibold))
                    Text("Progress stays on this device. Daily climbs change at 00:00 UTC. No connection or account needed.").font(.system(size: 12)).multilineTextAlignment(.center)
                    Text("TOWER RUSH  /  1.0").font(.system(size: 10, weight: .bold)).tracking(2).padding(.top, 8)
                }.foregroundStyle(Ink.muted).padding(.horizontal, 16)
            }.padding(16).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(Ink.background)
            .sheet(item: $selectedRun) { ResultView(store: store, run: $0, historyMode: true) }
            .sheet(isPresented: $showRules) { RulesView() }
    }
    private func recordRow(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack { Image(systemName: icon).foregroundStyle(Ink.gold).frame(width: 24); Text(title).font(.system(size: 15)); Spacer(); Text(value).font(.system(size: 15, weight: .semibold)).monospacedDigit() }
    }
}

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PageHeading(eyebrow: "A little precision", title: "Build your rhythm", subtitle: "Easy to start. Always room to improve.")
                    rule("01", "Line it up", "Tap Place as the moving platform lines up with the tower. The overlapping section stays; the overhang is cut away.")
                    rule("02", "Stay in the zone", "Align within 6 units for a perfect placement. Five perfect placements in a row restore 12 units of width, up to the starting width of 180.")
                    rule("03", "Keep your focus", "The platform speeds up as your tower grows. A complete miss ends the climb. Pause whenever you need a break.")
                    rule("04", "Take the daily climb", "Everyone gets the same movement sequence for the UTC date. Reach 20 floors to complete the daily goal. Replays are always available.")
                    rule("05", "See your progress", "Review every placement after a climb. Average accuracy includes a final miss as 0%. New locations and finishes open through your achievements.")
                }.padding(20)
            }.background(Ink.background).navigationTitle("How to build").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.foregroundStyle(Ink.text).tint(Ink.gold)
    }
    private func rule(_ number: String, _ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(Ink.gold)
            VStack(alignment: .leading, spacing: 8) { Text(title).font(.headline); Text(description).font(.system(size: 16)).foregroundStyle(Ink.muted) }
        }
    }
}

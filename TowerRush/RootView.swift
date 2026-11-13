import SwiftUI

struct RootView: View {
    @Bindable var store: TowerStore
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        ZStack {
            Ink.background.ignoresSafeArea()
            if !store.loaded {
                VStack(spacing: 20) { Image(systemName: "square.stack.3d.up.fill").font(.system(size: 48)).foregroundStyle(Ink.gold); ProgressView("Preparing your skyline…") }
            } else if store.loadFailed {
                ContentUnavailableView {
                    Label("Progress needs attention", systemImage: "externaldrive.badge.exclamationmark")
                } description: { Text(store.saveError ?? "Please try again.") } actions: { Button("Retry loading") { store.load() }.buttonStyle(.borderedProminent) }
            } else {
                TabView(selection: $store.tab) {
                    HomeView(store: store).tabItem { Label("Play", systemImage: "square.stack.3d.up.fill") }.tag(0)
                    LocationsView(store: store).tabItem { Label("Locations", systemImage: "map") }.tag(1)
                    CollectionView(store: store).tabItem { Label("Collection", systemImage: "square.grid.2x2") }.tag(2)
                    ProfileView(store: store).tabItem { Label("Profile", systemImage: "person.crop.circle") }.tag(3)
                }
                .tint(Ink.gold)
                .toolbarBackground(Ink.background, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            }
        }
        .foregroundStyle(Ink.text)
        .onOpenURL { url in
            if WidgetIdentity.accepts(url) { if !store.loaded { store.load() }
                #if DEBUG && targetEnvironment(simulator)
                store.applyWidgetQA(url)
                #endif
                store.tab = 0
            }
        }
        .task { if !store.loaded { store.load() } }
        .fullScreenCover(isPresented: Binding(get: { store.game != nil || store.result != nil }, set: { _ in })) {
            Group {
                if let result = store.result { ResultView(store: store, run: result) }
                else { GameView(store: store) }
            }.overlay(alignment: .top) { SaveNotice(store: store) }
        }
        .onChange(of: scenePhase) { _, phase in
            #if DEBUG && targetEnvironment(simulator)
            if store.captureScreen != nil { return }
            #endif
            if phase != .active { store.pause() }
        }
        #if DEBUG && targetEnvironment(simulator)
        .transaction { transaction in
            if store.captureScreen != nil {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
        #endif
        .overlay(alignment: .top) { SaveNotice(store: store) }
    }
}

struct SaveNotice: View {
    @Bindable var store: TowerStore
    var body: some View {
        if let message = store.saveError, !store.loadFailed {
            VStack(spacing: 8) {
                Label(message, systemImage: "externaldrive.badge.exclamationmark").font(.subheadline)
                Button("Retry saving") { store.persist() }.frame(minHeight: 44).foregroundStyle(Ink.gold)
            }.padding(16).background(Ink.panel, in: RoundedRectangle(cornerRadius: 16)).padding()
                .accessibilityElement(children: .contain)
        }
    }
}

struct HomeView: View {
    @Bindable var store: TowerStore
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.square.fill").font(.system(size: 25)).foregroundStyle(Ink.gold)
                            .frame(width: 48, height: 48).background(Ink.panel, in: RoundedRectangle(cornerRadius: 15))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BUILDER").font(.system(size: 11, weight: .bold)).tracking(2).foregroundStyle(Ink.muted)
                            Text(Ink.locations[store.data.preferences.location]).font(.system(size: 17, weight: .semibold))
                        }
                        Spacer()
                        Button { store.tab = 3 } label: { Image(systemName: "gearshape").font(.title3).frame(width: 48, height: 48).background(Ink.panel, in: Circle()) }
                            .accessibilityLabel("Settings")
                    }
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("A little higher.").foregroundStyle(Ink.muted).font(.system(size: 17))
                            Text("Every time.").font(.system(size: 36, weight: .bold, design: .rounded))
                        }
                        Spacer()
                        Text("01 / ∞").font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundStyle(Ink.gold)
                    }
                    ZStack(alignment: .topLeading) {
                        TowerScene(platforms: store.data.history.first?.platforms ?? TowerScene.illustration, skin: store.data.preferences.skin,
                                   location: store.data.preferences.location, fullTower: true)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(store.data.history.isEmpty ? "YOUR NEXT SKYLINE" : "YOUR LAST TOWER").font(.system(size: 10, weight: .bold)).tracking(2)
                            Text(store.data.history.first.map { "\($0.floors) floors" } ?? "Start something tall")
                                .font(.system(size: 15, weight: .semibold))
                            if store.data.history.isEmpty { Text("Illustration").font(.system(size: 11)).foregroundStyle(Ink.muted) }
                        }.padding(20)
                    }.frame(height: max(230, min(350, geometry.size.height * 0.4)))
                    HStack {
                        Metric(value: "\(store.data.bestFloors)", label: "BEST FLOORS", accent: Ink.gold)
                        Rectangle().fill(Ink.muted.opacity(0.2)).frame(width: 1, height: 40)
                        Metric(value: "\(Int(store.data.bestAccuracy * 100))%", label: "BEST ACCURACY")
                    }
                    GoldButton(title: "Build", icon: "arrow.up") { store.start(daily: false) }.accessibilityIdentifier("buildButton")
                    Button { store.start(daily: true) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "sun.max.fill").foregroundStyle(Ink.gold).font(.title2)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Daily climb").font(.system(size: 17, weight: .bold))
                                Text(store.data.completedDays.contains(GameRun.dayKey()) ? "Complete · build again anytime" : "Reach 20 floors · one shared sequence")
                                    .font(.system(size: 12)).foregroundStyle(Ink.muted)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: store.data.completedDays.contains(GameRun.dayKey()) ? "checkmark.seal.fill" : "arrow.right").foregroundStyle(Ink.gold)
                        }.panel()
                    }.buttonStyle(.plain).accessibilityIdentifier("dailyButton")
                    Text("One tap to place. One more floor to chase.").font(.system(size: 12)).foregroundStyle(Ink.muted)
                }.padding(16).frame(maxWidth: 620).frame(maxWidth: .infinity)
            }.background(Ink.background)
        }
    }
}

struct GameView: View {
    @Bindable var store: TowerStore
    @Environment(\.accessibilityReduceMotion) private var systemReduced
    @State private var confirmEnd = false
    private var reduced: Bool { systemReduced || store.data.preferences.reduceMotion }
    private var timelinePaused: Bool {
        #if DEBUG && targetEnvironment(simulator)
        if store.captureScreen != nil { return true }
        #endif
        return store.paused
    }
    var body: some View {
        GeometryReader { geometry in
            if let run = store.game {
                Group {
                    if geometry.size.height < 500 {
                        landscapeGame(run)
                    } else {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(run.dailyKey == nil ? "FREE CLIMB" : "DAILY CLIMB").font(.system(size: 11, weight: .bold)).tracking(2).foregroundStyle(Ink.gold)
                            Text(Ink.locations[run.location]).font(.system(size: 15, weight: .semibold))
                        }
                        Spacer()
                        Button { store.pause() } label: { Image(systemName: "pause.fill").frame(width: 48, height: 48).background(Ink.panel, in: Circle()) }
                            .accessibilityLabel("Pause game").accessibilityIdentifier("pauseButton")
                    }
                    HStack {
                        Metric(value: String(format: "%02d", run.floors), label: "FLOORS", accent: Ink.gold)
                        Metric(value: "\(run.streak)", label: "PERFECT STREAK")
                        Metric(value: "\(Int(run.top.width / 180 * 100))%", label: "WIDTH")
                    }
                    ZStack(alignment: .trailing) {
                        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: timelinePaused)) { context in
                            TowerScene(platforms: run.platforms, movingX: run.movingX(at: store.elapsed(at: context.date)), skin: run.skin, location: run.location, cameraFloor: Double(run.floors))
                                .animation(reduced ? nil : .easeOut(duration: 0.2), value: run.floors)
                        }.accessibilityElement(children: .ignore)
                            .accessibilityLabel("Moving platform. \(run.floors) floors. Width \(Int(run.top.width / 180 * 100)) percent.")
                            .accessibilityAction(named: "Place platform") { store.place() }
                            .accessibilityAction(named: "Hear alignment") {
                                let difference = run.movingX(at: store.elapsed()) - run.top.x
                                UIAccessibility.post(notification: .announcement, argument: abs(difference) <= 6 ? "Aligned" : "\(Int(abs(difference))) units \(difference < 0 ? "left" : "right")")
                            }
                        VStack(spacing: 20) {
                            ForEach([35, 20, 10, 0], id: \.self) { number in
                                VStack(spacing: 5) {
                                    Circle().fill(run.floors >= number ? Ink.gold : Ink.muted.opacity(0.25)).frame(width: 6, height: 6)
                                    Text("\(number)").font(.system(size: 10, weight: .bold)).monospacedDigit().foregroundStyle(Ink.muted)
                                }
                            }
                        }.padding(12).background(Ink.background.opacity(0.5), in: Capsule()).padding(.trailing, 8).accessibilityHidden(true)
                    }.frame(minHeight: 110, maxHeight: .infinity)
                    Text(store.feedback).font(.system(size: 15, weight: .semibold)).foregroundStyle(store.flash ? Ink.green : Ink.muted)
                        .id(store.feedback).transition(reduced ? .identity : .opacity)
                        .animation(reduced ? nil : .easeOut(duration: 0.2), value: store.feedback)
                    GoldButton(title: "Place", icon: "square.stack.3d.up.fill") { store.place() }
                        .disabled(store.paused).accessibilityIdentifier("placeButton")
                    if geometry.size.height > 450 {
                        Text(run.floors == 0 ? "Tap when the edges line up" : "5 perfect in a row restores a little width")
                            .font(.system(size: 12)).foregroundStyle(Ink.muted)
                    }
                }.padding(16).frame(maxWidth: 700).frame(maxWidth: .infinity)
                    }
                }
                .overlay {
                    if store.paused {
                        ZStack {
                            Ink.background.opacity(0.88).ignoresSafeArea()
                            VStack(spacing: 20) {
                                Image(systemName: "pause.circle").font(.system(size: 52)).foregroundStyle(Ink.gold)
                                Text("Take a breath.").font(.system(size: 32, weight: .bold, design: .rounded))
                                Text("Your tower is right where you left it.").foregroundStyle(Ink.muted).multilineTextAlignment(.center)
                                GoldButton(title: "Resume", icon: "play.fill") { store.resume() }.accessibilityIdentifier("resumeButton")
                                QuietButton(title: "Finish attempt", icon: "flag.checkered") { confirmEnd = true }
                            }.padding(24).frame(maxWidth: 420)
                        }
                    }
                }
            }
        }.background(Ink.background).foregroundStyle(Ink.text)
            .confirmationDialog("Finish this attempt? Your current result will be saved.", isPresented: $confirmEnd, titleVisibility: .visible) {
                Button("Save and finish") { store.endAttempt() }
                Button("Keep building", role: .cancel) { }
            }
    }
    private func landscapeGame(_ run: GameRun) -> some View {
        HStack(spacing: 16) {
            TimelineView(.animation(minimumInterval: 1.0 / 60, paused: timelinePaused)) { context in
                TowerScene(platforms: run.platforms, movingX: run.movingX(at: store.elapsed(at: context.date)), skin: run.skin, location: run.location, cameraFloor: Double(run.floors))
                    .animation(reduced ? nil : .easeOut(duration: 0.2), value: run.floors)
            }
            VStack(spacing: 16) {
                HStack {
                    Text(run.dailyKey == nil ? "FREE CLIMB" : "DAILY CLIMB").font(.system(size: 12, weight: .bold)).foregroundStyle(Ink.gold)
                    Spacer()
                    Button { store.pause() } label: { Image(systemName: "pause.fill").frame(width: 44, height: 44) }
                        .accessibilityLabel("Pause game").accessibilityIdentifier("pauseButton")
                }
                HStack {
                    Metric(value: "\(run.floors)", label: "FLOORS", accent: Ink.gold)
                    Metric(value: "\(run.streak)", label: "STREAK")
                }
                Spacer(minLength: 0)
                Text(store.feedback).font(.system(size: 13)).foregroundStyle(Ink.muted)
                GoldButton(title: "Place", icon: "square.stack.3d.up.fill") { store.place() }
                    .disabled(store.paused).accessibilityIdentifier("placeButton")
            }.frame(width: 220)
        }.padding(16)
    }

}

struct ResultView: View {
    @Bindable var store: TowerStore
    var run: GameRun
    var historyMode = false
    @Environment(\.dismiss) private var dismiss
    @State private var showReview = false
    #if DEBUG && targetEnvironment(simulator)
    @State private var captureReviewOpened = false
    #endif
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text(run.dailyKey == nil ? "CLIMB COMPLETE" : "DAILY CLIMB · \(run.dailyKey!) UTC").font(.system(size: 11, weight: .bold)).tracking(1.5).foregroundStyle(Ink.gold)
                    Spacer()
                    Button { close() } label: { Image(systemName: "xmark").frame(width: 44, height: 44).background(Ink.panel, in: Circle()) }.accessibilityLabel("Close result")
                }
                VStack(spacing: 6) {
                    Text(run.floors == 0 ? "Find your rhythm." : "A new perspective.").font(.system(size: 32, weight: .bold, design: .rounded))
                    Text(run.floors >= 20 && run.dailyKey != nil ? "Daily goal complete. Nicely built." : "Every placement is a little progress.").font(.system(size: 15)).foregroundStyle(Ink.muted)
                }
                TowerScene(platforms: run.platforms, skin: run.skin, location: run.location, fullTower: true).frame(height: 320)
                HStack {
                    Metric(value: "\(run.floors)", label: "FLOORS", accent: Ink.gold)
                    Metric(value: "\(Int(run.accuracy * 100))%", label: "ACCURACY")
                    Metric(value: "\(run.bestStreak)", label: "BEST STREAK")
                }.panel()
                if !historyMode {
                    GoldButton(title: "Build again", icon: "arrow.clockwise") { store.start(daily: run.dailyKey != nil) }.accessibilityIdentifier("replayButton")
                }
                QuietButton(title: "Review placements", icon: "scope") { showReview = true }.accessibilityIdentifier("reviewButton")
                if !historyMode { Button("Back to skyline") { close() }.frame(minHeight: 44).foregroundStyle(Ink.muted) }
            }.padding(16).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(Ink.background).foregroundStyle(Ink.text)
            .sheet(isPresented: $showReview) { PlacementReview(run: run) }
            #if DEBUG && targetEnvironment(simulator)
            .onAppear {
                if store.captureScreen == "placement-review" && !captureReviewOpened {
                    captureReviewOpened = true
                    showReview = true
                }
            }
            #endif
    }
    private func close() { if historyMode { dismiss() } else { store.result = nil } }
}

struct PlacementReview: View {
    var run: GameRun
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your climb, placement by placement.").font(.title2.bold())
                    Text("Accuracy is the percentage of platform width that overlapped. Perfect placements count as 100%; a miss counts as 0%.")
                        .font(.system(size: 15)).foregroundStyle(Ink.muted)
                    if run.placements.isEmpty {
                        ContentUnavailableView("No placements yet", systemImage: "square.stack.3d.up", description: Text("This attempt ended before the first platform was placed."))
                    }
                    ForEach(run.placements) { placement in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(placement.missed ? "Missed placement" : "Floor \(placement.id)").font(.headline)
                                Spacer()
                                Label(placement.perfect ? "Perfect" : "\(Int(placement.accuracy * 100))%", systemImage: placement.perfect ? "checkmark.circle.fill" : placement.missed ? "xmark.circle.fill" : "scissors")
                                    .font(.subheadline.bold()).foregroundStyle(placement.perfect ? Ink.green : placement.missed ? Ink.red : Ink.gold)
                            }
                            ProgressView(value: placement.accuracy).tint(placement.perfect ? Ink.green : Ink.gold)
                            Text(placement.perfect ? (placement.restored ? "Aligned · \(Int((placement.remaining - run.platforms[placement.id - 1].width).rounded())) units of width restored" : "Aligned within the 6-unit perfect zone") : "\(Int(abs(placement.offset).rounded())) units \(placement.offset < 0 ? "left" : "right") · \(Int(placement.remaining.rounded())) units remaining")
                                .font(.system(size: 12)).foregroundStyle(Ink.muted)
                        }.panel()
                    }
                }.padding(16)
            }.background(Ink.background)
                .navigationTitle("Placement review").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.tint(Ink.gold).foregroundStyle(Ink.text)
    }
}

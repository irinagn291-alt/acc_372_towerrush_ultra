# Tower Rush

Native precision stacking arcade. iOS 17+, SwiftUI, Swift 6; iPhone/iPad. All product text is English (user clarification overrides the factory locale list). Account acc_372 / local account ID 372; bundle com.towerrush.arcade. No external SDK or network dependency.

## Product and screens
- Play: builder avatar, selected location, settings, last tower (labelled illustration before first attempt), floor/accuracy records, Build CTA and deterministic daily challenge.
- Game: dimensional moving platform, tower, floor count, perfect streak, milestones, Place CTA, explicit pause/resume. Backgrounding pauses and persists the current attempt. Terminated sessions restore paused.
- Result: complete tower, floors, mean placement accuracy, best streak, replay and per-placement review including missed placement.
- Locations: Night City (initial), Dune Valley (10 floors), Frozen Cliffs (20 floors), Orbital Station (35 floors).
- Collection: Gold (initial), Jade (30 lifetime perfect placements), Glacier (10 floors), Aurora (15 consecutive perfect placements). Interactive preview and explicit unlock requirements.
- Profile: lifetime totals, records, attempt history and settings for sound, haptics and reduced motion. Empty states, local save errors with retry, loading screen, offline explanation.

## Rules
World lane 320 units; starting width 180. Each press uses the current continuous triangular motion position. Intersection survives; overhang is cut. No overlap ends the attempt. Within 6 units of alignment is perfect, snaps to previous centre and retains width. Every fifth consecutive perfect restores 12 units up to 180. Speed = min(205, 76 + floor*4.4) units/sec, modified by deterministic per-floor factor in [0.92,1.08]. Daily seed = UTC YYYYMMDD, same trajectory sequence for all players on that date; date is frozen at attempt start. Daily target: 20 floors. Accuracy = overlap / moving width; perfect = 100%; terminal miss = 0% and included in mean. Normal attempts use random local seeds. Points/currency do not exist.

## Visual and access
8 pt spacing rhythm, 16 pt sides, 44 pt minimum controls, 15–17 pt body, tabular stats, gold dimensional CTA, navy layered skyline, thick lit platforms, 200ms interface transitions and smooth vertical camera. Reduce Motion removes camera transitions, decorative rotation and flashes; essential horizontal gameplay remains. VoiceOver labels announce alignment on request and expose placement action. Native tab view retains state.

## Verification
XCTest logic: intersections, misses, tolerance boundary, restoration, difficulty cap, deterministic seed, date UTC, record/unlock rules, persistence and recovery. XCUITest: tabs, settings, game/pause/resume/result/review and screenshots. All simulator work via factory simulator_pool and build locks. No shipping.

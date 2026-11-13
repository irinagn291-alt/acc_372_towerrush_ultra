# Tower Rush

A complete offline SwiftUI precision stacking game. English UI. iOS 17 minimum, Swift 6 language mode, iPhone and iPad, portrait and landscape. Built using the locally installed Xcode 27.2.

Open `TowerRush.xcodeproj` and run the `TowerRush` scheme. The source project is `project.yml`; regenerate with the factory's `.local/tools/xcodegen/bin/xcodegen generate --spec ios/apps/TowerRush/project.yml` from the factory root. There are no package dependencies or service keys.

## Architecture

- `GameEngine.swift`: value-type rules, deterministic UTC daily sequence, achievements, atomic JSON storage.
- `AppStore.swift`: main-actor observable state, persistence, pause/resume, local sound/haptics.
- `Design.swift`: design tokens, original platform renderer, layered city/desert/ice/orbit landscapes.
- `RootView.swift`: home, game, result, exact placement review and lifecycle.
- `ExploreViews.swift`: location progression, material previews, profile/history, settings and rules.

The save is `Library/Application Support/TowerRush/progress.json` in the app sandbox. Active attempts persist after every placement and on backgrounding; restoring never starts the platform automatically. Corrupt files are retained, with a retry UI, rather than silently replaced. A failed write preserves in-memory progress and offers retry. All features work without internet. History retains 50 attempts while aggregate records are cumulative.

Daily movement depends only on UTC date and floor number. Skin/location have no influence on difficulty. Replaying an old result starts the current day's daily sequence; the original result remains in history. Accuracy includes a terminal miss, and manually finishing on pause records only placements actually made.

## Checks

Use the factory's simulator pool; never boot or erase shared devices directly. The complete foreground QA script is in `output/TowerRush-implementation/qa.sh` at the factory root. It uses `GF_SIMULATOR_UDID`, disables parallel test execution, and exports xcresult screenshots plus save data before the disposable simulator is released. Build/test commands use the factory `scripts/bin` shims and shared build lock. Pass an unused evidence label to the script when repeating QA; existing xcresult bundles are deliberately retained.

The project includes 15 unit tests and two UI tests that cover navigation, a locked finish preview, settings, playing, rotation, pause, process termination, saved-game recovery, result/review, daily play and history. See `QA.md` for observed results.

## Local factory record

Imported into Scratch without starting shipping, linked to account `372` (`acc_372`) and the uniquely matched New app request `cmwc77t5c00eafdft4l7enquy`. Bundle ID: `com.towerrush.arcade`. The original factory card lists additional metadata locales; the app itself deliberately remains English only, as requested by the user. No distribution signing, App Store submission or deployment has been performed.

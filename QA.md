# Tower Rush implementation verification

Date: 13 November 2026 (Europe/Moscow).

## Environment and scope

- Xcode 27.2 (27B52), Swift 6 language mode, deployment target iOS 17.0.
- No external Swift packages, network APIs, credentials, ads or purchases.
- Build/test artifacts: `/Users/belzephyrus/Documents/gambling_factory/output/TowerRush-implementation/`.
- All simulator operations used the factory `simulator_pool.py` with the entire foreground script; commands used `GF_SIMULATOR_UDID`. Tests disabled parallel execution. Builds used the factory shared build lock. Temporary devices were disposed by the helper after exporting screenshots and save evidence.

## Observed results

- Debug simulator build: succeeded.
- Release generic iOS build with signing disabled: succeeded.
- iPhone 18 Pro / iOS 27.2: 14 initial unit tests passed, zero failures. Full UI journey passed after adding an explicit orientation readiness wait.
- Separate iPhone landscape/pause UI test: passed. Full-screen screenshots inspected: stage, statistics, Place, Resume and Finish controls fit correctly.
- iPad Pro 13-inch / iOS 27.2: all 15 unit tests passed, zero failures. Both UI tests passed after selecting the first matching accessibility element for the native floating tab bar. All exported screen families were visually inspected; controls, text and scene compositions fit.

## Functional evidence

Unit coverage includes overlap and centre calculation; edge-touch and narrow-platform misses; perfect tolerance; width restoration and cap; mean accuracy including misses; UTC daily reproducibility; triangular movement bounds; difficulty cap; achievements; duplicate result protection; atomic storage round trip; corrupt files and invalid location validation; pause/resume/reload. The fifteenth passing test covers failed-write retry without losing in-memory progress.

The UI journey covers all four tabs, locked finish preview, Reduce Motion, building, portrait/landscape rotation, pause, termination/relaunch, background/foreground recovery, a real placement, saved results, placement review, daily climb and history. The passing iPad journey also confirms that the collection preview survives tab switches.

The iPhone save exported from the passing journey records two actual attempts, one actual successful placement with its measured overlap, and `reduceMotion: true`. No sample progress is inserted into production storage.

Original xcresults/logs are retained, including the first iPhone UI attempt that queried the rotated button too early and the first iPad attempt whose tab query matched both nested accessibility elements. Both test selectors were corrected and the affected scenarios passed on rerun. An app-window screenshot after rotation had a cropped export; a separate successful test captured the complete screen, which was visually reviewed. Curated evidence excludes the cropped image.

## Evidence paths

- `build.log`, `release-build.log`
- `iphone-verified.xcresult`, `iphone-verified-tests.log`
- `iphone-landscape.xcresult`, `iphone-landscape-tests.log`
- `screenshots/iphone/`, `iphone-contact-sheet.png`
- `iphone-verified-progress.json`
- `ipad.xcresult`, `ipad-tests.log` (15 unit tests passed; initial UI selector failures retained)
- `ipad-verified.xcresult`, `ipad-verified-tests.log` (both UI tests passed)
- `screenshots/ipad/`, `ipad-contact-sheet.png`, `ipad-verified-progress.json`
- `TowerRush-simulator.zip` (app bundle without test PlugIns)
- `factory-import.json`, `source-checks.txt`, `bundle-checks.json`, `verification.json`

## Boundaries

Runtime QA used the installed iOS 27.2 runtime; an iOS 17 runtime is not installed. The deployment target is 17.0 and the project compiles against that minimum. Haptics and sound controls are implemented with system APIs; physical-device feel and audio were not assessed through the simulator. Distribution signing and App Store submission were not performed. No external functional dependency remains for local play.

Factory import created only this app's Scratch record, bound to account 372 and request `cmwc77t5c00eafdft4l7enquy`, with shipping false. The user-facing app is English only; the original factory card's metadata locale list was retained.

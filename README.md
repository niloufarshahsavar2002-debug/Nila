# Nila — Affirmations App

Comprehensive developer documentation for the `Nila` iOS app (SwiftUI).

<details>
<summary><strong>Quick navigation</strong></summary>

- Overview
- Features
- Architecture & file layout
- Technologies & libraries
- iOS APIs used
- Persistence & data formats
- Accessibility
- Assets
- Build & run instructions
- Known issues & recommendations
- Next steps & ideas

</details>

---

## Overview

`Nila` is a small SwiftUI-based iOS application that displays short affirmation phrases in a paged UI, lets users favorite or share them, and tracks a simple daily "streak". The app is intentionally small and focuses on a clean UX.

The app entrypoint is `Nila/Nila/NilaApp.swift` which launches `PagedAffirmationsView` implemented in `Nila/Nila/ContentView.swift`.

---

## Features

- Paged affirmations UI with page indicator and previous/next/shuffle controls
- Favorite/unfavorite phrases (persisted across launches)
- Generate and share a stylized image of an affirmation + the text
- Profile form (name, email, date of birth) persisted via `@AppStorage`
- Streak tracking for daily habit marking (simple date-key storage)
- Small in-app toast notification for ephemeral messages

---

## Architecture & Files

- `Nila/Nila/NilaApp.swift` — app entry (@main App)
- `Nila/Nila/ContentView.swift` — primary UI file. Contains:
  - `PagedAffirmationsView` — main screen
  - `PhraseCardView`, `ActionRowView`, `CustomPageIndicator` — UI components
  - `ProfileView` — profile form
  - `StreakView` — streak sheet UI
  - `ShareView` — `UIViewControllerRepresentable` wrapper for `UIActivityViewController`
  - Helpers: favorite/streak persistence, image rendering, date utilities
- `Nila/Assets.xcassets` — asset catalog with `AccentColor` and `AppIcon.appiconset`
- `Nila.xcodeproj/project.pbxproj` — Xcode project configuration

Note: The codebase currently uses a single file `ContentView.swift` for most UI; consider splitting into multiple files for maintainability as the app grows.

---

## Technologies & External Libraries

- Language: Swift (Swift 5)
- UI: SwiftUI
- No external dependency managers detected (no `Package.swift`, `Podfile`, or `Cartfile`).
- Assets: Xcode Asset Catalog (`Assets.xcassets`)

External libraries: none included.

---

## iOS APIs & Frameworks used

This project uses several platform APIs. The list below maps to where they appear in the code and why they're used.

- SwiftUI
  - `App` protocol, `WindowGroup` — app entry and scenes
  - `View`, `TabView`, `ForEach`, `Text`, `Button`, `Image`, `Form`, `DatePicker`, `NavigationStack`, `Sheet` — UI composition
  - `@State`, `@Binding`, `@AppStorage`, `@Environment` — local state, bindings, persistence helpers, environment values

- Foundation
  - `Date`, `Calendar`, `DateFormatter` — date calculations and formatting for streaks
  - `JSONEncoder` / `JSONDecoder` — encoding favorites and streaks to `Data` for `@AppStorage`
  - `DispatchQueue` — scheduling toast hide after delay

- UIKit interoperability
  - `UIActivityViewController` — system share sheet (wrapped by `ShareView: UIViewControllerRepresentable`)
  - `UIHostingController` — fallback path for image rendering on iOS < 16
  - `UIGraphicsImageRenderer` — fallback image rendering on older OS versions

- Image rendering (iOS 16+)
  - `ImageRenderer` (from SwiftUI) — used to render a SwiftUI view into `UIImage` for sharing when available

- AVFoundation
  - `import AVFoundation` is present in `ContentView.swift` but there is no active use of AVFoundation APIs in the checked-in code. This appears to be either leftover or preparatory for future audio features.

Notes:
- `ImageRenderer` requires iOS 16+. The code has a backward-compatible fallback that uses `UIHostingController` + `UIGraphicsImageRenderer` for older iOS versions.
- `@AppStorage` uses `Data` typed values for encoded favorites/streaks; ensure consistent migrations if changing storage format later.

---

## Persistence & Data Formats

- Favorites
  - Stored via `@AppStorage("favoriteIndices")` as `Data` containing JSON-encoded `[Int]`.
  - In-memory representation: `Set<Int>` for efficient existence checks.

- Streak dates
  - Stored via `@AppStorage("streakMarkedDates")` as `Data` containing JSON-encoded `[String]` where each string is `yyyy-MM-dd` formatted using a `DateFormatter` whose calendar starts on Monday.

- Profile fields
  - `@AppStorage("profile_name")` — `String`
  - `@AppStorage("profile_email")` — `String`
  - `@AppStorage("profile_dob")` — `Double` (time interval since 1970)

Design notes:
- Storing arrays as JSON `Data` in `@AppStorage` works for small datasets, but if you plan on more complex user data or larger amounts of data, consider using `FileManager` with Codable files or Core Data for structured, queryable storage.

---

## Accessibility

Current accessibility considerations found in the code:

- Accessibility labels:
  - Favorite toggle uses `accessibilityLabel(...)` with localized Italian text in `PhraseCardView` (e.g. `"Rimuovi Preferito"` / `"Aggiungi Preferito"`).
  - `StreakButton` sets an `accessibilityLabel("Streak")`.

- Use of semantic controls:
  - Buttons and `Label` usages provide visual affordances; `DatePicker` and `Form` are standard controls and accessible by default.

- Visual contrast & focus:
  - Many controls use light-on-dark components and shadows. Review color contrast for compliance with WCAG AA if accessibility is a priority.

Recommended accessibility improvements (actionable):

<details>
<summary><strong>Suggested improvements</strong></summary>

- Localize accessibility labels and UI strings (App currently mixes English and some Italian labels).
- Provide `accessibilityHint` where a control's outcome may not be obvious (e.g., what "Shuffle" does).
- Ensure dynamic type support for text: prefer scalable fonts via `.font(.title)` or use `.scaledFont` modifiers to respond to user text size.
- Add VoiceOver testing notes: test gestures and sheet presentation flows. Confirm the share sheet is reachable by VoiceOver users.
- Add explicit `accessibilitySortPriority` if needed to control reading order of complex views.

</details>

---

## Assets

- `Assets.xcassets` contains:
  - `AccentColor.colorset` — global accent color for the app
  - `AppIcon.appiconset` — includes `PNG` with name `Purple Retro Aesthetic Purple Colored iOS Icon Set.png`

Ensure any included images are appropriately sized and named according to Apple's Human Interface Guidelines. Consider providing multiple scale variants when not using the full asset catalog generator.

---

## Build & Run instructions

Minimal steps to open and run the app locally using Xcode on macOS:

1. Open the Xcode project:

```bash
open Nila.xcodeproj
```

2. Select the `Nila` scheme and a simulator (e.g., iPhone 15) and press Run.

Notes about project settings found in the repository:

- In `Nila.xcodeproj/project.pbxproj`, `IPHONEOS_DEPLOYMENT_TARGET` is currently set to `26.0`. This value is almost certainly incorrect (it targets a far-future iOS version) and will prevent building on current Xcode toolchains. Update it to a realistic minimum (for example `16.0` or `17.0`) either in Xcode's target settings or by editing the project file.

To change the deployment target via the command line (quick patch):

```bash
# Open project in Xcode and change it in Target > General > Deployment Info
# or edit `project.pbxproj` carefully to set IPHONEOS_DEPLOYMENT_TARGET to a supported value like 16.0
```

If you prefer I can patch `project.pbxproj` to set a more realistic default (I recommend `16.0`). Let me know if you'd like that.

---

## Known issues & observations

- `IPHONEOS_DEPLOYMENT_TARGET = 26.0` in `project.pbxproj` is likely a mistake. This prevents building on current toolchains.
- `AVFoundation` is imported but not used in the code. Remove it if you do not plan audio features.
- Most app UI lives in a single large `ContentView.swift`. For performance and maintainability, split into smaller files as the app grows.
- `Chalkduster` is used as a custom font via `.font(.custom("Chalkduster", ...))`. This is a system font on Apple platforms but confirm appearance across devices.

---

## Suggestions & Next steps

- Fix the deployment target to a realistic iOS version (e.g., `16.0`). I can prepare a patch.
- Split `ContentView.swift` into multiple files (e.g., `PagedAffirmationsView.swift`, `PhraseCardView.swift`, `ProfileView.swift`, `StreakView.swift`) to reduce compile times and improve readability.
- Add unit and UI tests, for example:
  - Unit tests for favorites persistence and streak logic
  - Snapshot or UI tests for image rendering and share flow
- Add localization scaffolding if you plan to support multiple languages (strings files, Localizable.strings).
- Add CI (GitHub Actions) to run SwiftLint, unit tests, and basic build checks.

If you want, I can implement any of the above (deployment target patch, splitting files, adding tests, or CI).

---

## Contact & Contributing

If you want me to make any of the recommended fixes or follow-ups (patch the deployment target, split files, add tests, create a sample CI workflow), tell me which item to prioritize and I will update the repo accordingly.

---

_Generated: 17 November 2025_

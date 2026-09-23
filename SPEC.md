# Marteloio — Build Specification

> Portfolio app 132, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Log the pages of each reading session and link the genres you read across on one chart.

| Field | Value |
| --- | --- |
| Product name | Marteloio |
| Bundle identifier | `com.marteloio.chart` |
| Domain | https://marteloio-chart.pro |
| Contact URL | https://marteloio-chart.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `mrt_` |
| User-Agent | `Marteloio/1.0 (iOS; +https://marteloio-chart.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Marteloio -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A reader logs the pages of a reading session and then taps a second genre island so those pages are spent to draw a rhumb line joining the two islands on the chart.

### 2.1 User flow

1. Home opens on the portolan chart: one island per genre on a fixed grid. One island is already hailed and carries a Run badge reading 60 pages, and every island the Run can reach is drawn solid while the rest sit hatched. Tap a solid one.
2. A rhumb line is inked between the hailed island and the tapped island, a RhumbMark is written, and the Run is spent down to its remainder.
3. Pull up the Shelf sheet, scan a paperback's ISBN with the live scanner or search the catalog by title, and pick its genre; the book moors on that genre's island.
4. Tap a moored book, enter pages read and minutes, and Hail: a Fix lands on that book's island and a fresh Run appears on the chart.
5. Tap an island that costs more than the Run: a LuffMark is written, that island dims for the rest of the session, and the Run is left untouched so another island can still be borne.
6. Open the Logbook sheet to read today's Fixes, Rhumbs and Luffs by date, with pages per island and the busiest bearing.
7. Mark a book Finished on the Shelf; a Landfall is written and that island keeps a hatched ring for good.

### 2.2 Essential behaviour

- Portolan chart as home: genre islands are collection-view cells placed by a custom layout, and every drawn Rhumb plus the windrose is a layout decoration view redrawn on invalidation.
- Hail: logging a session (book, pages, minutes) seats a Fix on that book's island and writes a Run equal to the pages read; a second Hail while a Run is unspent is refused.
- Bear: tapping a distinct island spends the Run against a reach cost of 20 pages per chart cell of separation, writes a RhumbMark and inks a persistent Rhumb; an over-cost tap writes a LuffMark and keeps the Run.
- Shelf sheet: add books by live ISBN scan or catalog title search, assign the genre that decides the island, and mark Finished to write a Landfall.
- Logbook sheet: Fixes, Rhumbs, Luffs and Landfalls listed by daykey, with pages per island, rhumb count per pair, and thickest bearing.
- Rhumb thickening: a pair that is already joined does not duplicate its line, it gains weight, so the chart reads as traffic between genres rather than a checklist.
- Settings sheet: pages-per-cell reach rate, chart grid size, island genre renaming, and a local evening reminder. Everything stays on device.

---

## 3. Uniqueness assignment for Marteloio

| Axis | Assigned value |
| --- | --- |
| Architecture | **Portolan ADT fold (Moored | Hailed | Bound); the chart is a fold over Islands; Hail writes a Run as the pages of this session and seats a Fix on the read Book's Island, folding Moored to Hailed; Bear writes a RhumbMark when the tapped Island is distinct and its reach cost is at or under the Run, inks the Rhumb, subtracts the cost and folds Hailed to Bound when the Run cannot pay any further Island; an over-cost tap writes a LuffMark and keeps the Run; Bear on Moored is refused; a second Hail while Hailed is refused; Hail samples a Book that is not Finished; a pair already joined thickens instead of duplicating; a chart under two Islands writes Shoal** |
| UI approach | **UIKit UICollectionViewFlowLayout subclass · canvas-first** |
| Naming convention | **Portolan / rhumb-line lexicon (Chart, Island, Moor, Hail, Run, Bear, Rhumb, Fix, Luff, Landfall, Windrose, Shoal)** |
| File organization | **By portolan role (Chart, Island, Book, Session, Run, Rhumb, FixMark, RhumbMark, LuffMark, Landfall)** |
| Dependency strategy | **None (zero external dependencies) · no SPM entry, no CocoaPods, no vendored source; UIKit, Core Graphics, AVFoundation and URLSession only** |
| Design direction | **storytelling · sheet-stack · branded** |
| Typography | **SF Pro (system default) · monospaced tabular digits for Runs, reach costs and page totals; island names in Title3 semibold with a small-caps bearing label under each rhumb** |
| Navigation pattern | **Chart-locked chrome (the portolan chart never leaves; Shelf, Logbook and Settings arrive as a sheet stack over the chart; scan and title search fuse on Shelf)** |
| AI art style | **Paper cut origami collage · tactile** |
| Functional twist | **Rhumb-reach linking (pages read become a Run; the Run pays 20 pages per chart cell to join two distinct Islands; an over-cost tap writes a LuffMark, hatches that Island for the session and keeps the Run)** |
| Persistence | **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — reading_board

**Core** — A reader logs the pages of a reading session and then taps a second genre island so those pages are spent to draw a rhumb line joining the two islands on the chart.

**Audience** — Readers who move between genres and want their finished pages to build one connected chart instead of a stack of star ratings.

**User flow**

1. Home opens on the portolan chart: one island per genre on a fixed grid. One island is already hailed and carries a Run badge reading 60 pages, and every island the Run can reach is drawn solid while the rest sit hatched. Tap a solid one.
2. A rhumb line is inked between the hailed island and the tapped island, a RhumbMark is written, and the Run is spent down to its remainder.
3. Pull up the Shelf sheet, scan a paperback's ISBN with the live scanner or search the catalog by title, and pick its genre; the book moors on that genre's island.
4. Tap a moored book, enter pages read and minutes, and Hail: a Fix lands on that book's island and a fresh Run appears on the chart.
5. Tap an island that costs more than the Run: a LuffMark is written, that island dims for the rest of the session, and the Run is left untouched so another island can still be borne.
6. Open the Logbook sheet to read today's Fixes, Rhumbs and Luffs by date, with pages per island and the busiest bearing.
7. Mark a book Finished on the Shelf; a Landfall is written and that island keeps a hatched ring for good.

**Essential features**

- Portolan chart as home: genre islands are collection-view cells placed by a custom layout, and every drawn Rhumb plus the windrose is a layout decoration view redrawn on invalidation.
- Hail: logging a session (book, pages, minutes) seats a Fix on that book's island and writes a Run equal to the pages read; a second Hail while a Run is unspent is refused.
- Bear: tapping a distinct island spends the Run against a reach cost of 20 pages per chart cell of separation, writes a RhumbMark and inks a persistent Rhumb; an over-cost tap writes a LuffMark and keeps the Run.
- Shelf sheet: add books by live ISBN scan or catalog title search, assign the genre that decides the island, and mark Finished to write a Landfall.
- Logbook sheet: Fixes, Rhumbs, Luffs and Landfalls listed by daykey, with pages per island, rhumb count per pair, and thickest bearing.
- Rhumb thickening: a pair that is already joined does not duplicate its line, it gains weight, so the chart reads as traffic between genres rather than a checklist.
- Settings sheet: pages-per-cell reach rate, chart grid size, island genre renaming, and a local evening reminder. Everything stays on device.

**Twist** — Rhumb-reach linking. Home is the chart, and the job is to spend pages as distance. Hail seats a Fix on the island of the book being read and writes a Run equal to the pages read. Bear spends that Run: tapping a second, distinct island inks a Rhumb when the Run covers the reach cost of 20 pages per chart cell between them, writes a RhumbMark, and folds Hailed to Bound. Tapping an island that costs more than the Run writes a LuffMark, hatches that island for the session, and leaves the Run whole. Bear before Hail is refused. A second Hail while a Run is unspent is refused. A pair already joined thickens its Rhumb instead of drawing a duplicate. Seed already hails one island with a 60-page Run and two moored books, so the opening tap can ink the first Rhumb. Home verb is bear-the-rhumb, not walk-a-token and not light-a-lamp. Local only.

**Why this is not a repeat** — The nearest neighbour in the portfolio is Cresset, which walks a token step by step across island tiles and lights lamps as minutes accumulate: a path traversal where reading unlocks the next tile. This is a different job on home. Nothing walks and nothing unlocks; pages are a budget of distance that is spent to connect two genres, so the artifact the reader builds is a graph of rhumb lines with thickening edges, not a route someone has already stepped along. The refusal shape is also new: an out-of-reach tap costs nothing but a LuffMark, so the Run survives and the reader re-aims rather than losing progress. It is not reading_expedition, which maps trips and catalogues; it is not book_quotes, which keeps text after the book is gone; it is not journal_chrome, because Chart is the mechanic itself and Logbook is a record of marks the chart already made. The Portolan lexicon, the Moored/Hailed/Bound fold, the reach-cost arithmetic, and a UICollectionView layout that ships rhumbs as decoration views are all unused axes.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Archipelago. Token walks islands.
- Invariant: 10 pages/tile, 8 tiles/island. tile = min(totalPages/10, totalTiles−1). Island unlock + lighthouse on first reach. pages from minutes × pace.
- Never: No Ink mini-game tab.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

### 3.1 Architecture contract

The Chart is a fold over Islands with exactly three states: Moored, Hailed, Bound. Hail takes a Book that is not Finished plus the pages and minutes of one session, seats a FixMark on that Book's Island, writes a Run whose value is the pages read, and folds Moored to Hailed; a second Hail while the Chart is Hailed is refused and the existing Run is left whole. Bear takes a tapped Island, refuses when the Chart is Moored, refuses when the tapped Island is the hailed one, and otherwise computes reach cost as 20 pages per chart cell of separation (Chebyshev distance on the fixed grid); at or under the Run it writes a RhumbMark, inks or thickens the Rhumb, and subtracts the cost, and over the Run it writes a LuffMark, hatches that Island for the rest of the session, and returns the Run untouched. When the remaining Run cannot pay the cheapest Island still reachable, the fold moves Hailed to Bound and the Chart waits for the next Hail. A pair that already carries a Rhumb never gains a second line; the existing Rhumb takes one more unit of weight and its RhumbMark count rises. A Chart holding fewer than two Islands writes Shoal instead of any Bear, and the chart surface says so rather than failing silently. Every transition is a pure function from (ChartRecord, Intent) to (ChartRecord, Mark) so ReachCostTests and FoldTests can drive the whole mechanic without a view.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

Canvas first: home is a UICollectionView whose layout is a PortolanFlowLayout, a UICollectionViewFlowLayout subclass that ignores line flow and places one IslandCell per genre at a fixed grid coordinate, sized from the bounds so the chart fills the device and the iPad uses the extra width instead of centering a column. Rhumbs and the windrose are layout decoration views: PortolanFlowLayout returns UICollectionViewLayoutAttributes for every inked Rhumb (with weight, bearing angle and a small-caps bearing label) and one Windrose behind the islands, and invalidates them on each mark so a newly borne Rhumb animates in without reloading cells. RhumbDecorationView draws in Core Graphics with a hairline stroke that gains weight, never a second colour. IslandCell is a paper-cut island plate with the genre name, its page total in tabular digits, and three visual states that are never colour alone: solid (reachable on the current Run), hatched (out of reach, luffed, or landfallen ring), and hailed (Run badge attached). The whole cell is the hit target at 44pt minimum with a contentShape on the fill, and every icon-only control carries a VoiceOver label; the reachable state is spoken as well as drawn. This UIKit surface is the one hero: it is hosted in SwiftUI through ChartRepresentable (UIViewControllerRepresentable), and Shelf, Hail, Logbook, Settings and onboarding are plain SwiftUI built from the token accessors, with no second rendering kit anywhere else.

### 3.3 Naming contract

Convention: Portolan / rhumb-line lexicon (Chart, Island, Moor, Hail, Run, Bear, Rhumb, Fix, Luff, Landfall, Windrose, Shoal).

Examples to follow: ['ChartFold.bear(to:) -> FoldOutcome (Moored | Hailed | Bound)', 'RhumbMark(daykey:fromIsland:toIsland:cost:weightAfter:)', 'PortolanFlowLayout + RhumbDecorationView / WindroseDecorationView', 'ReachCost.pages(between:and:onGrid:) and LuffMark.hatchedForSession']

### 3.4 Dependency contract

Zero external dependencies. No Package.swift, no SPM entry in the project file, no Podfile, no Cartfile, no vendored third party source. Apple frameworks only: SwiftUI and UIKit for chrome and the chart, Core Graphics for the rhumb and windrose decoration drawing, AVFoundation for the live ISBN read, URLSession for catalog title search, UserNotifications for the local evening reminder, and Foundation for Codable, NumberFormatter and Calendar. No analytics, no crash reporter, no remote config, no WebView.

### 3.5 Navigation contract

Chart locked chrome with no tab bar at all. The portolan chart is the permanent root and never pushes or dismisses; Shelf, Logbook and Settings arrive as a sheet stack over it, raised from a single hairline bar of three text triggers pinned above the home indicator, each a full width Button label with contentShape. Shelf is a large detent sheet where the live scanner and catalog title search are one fused surface rather than separate destinations; tapping a moored book raises Hail as a medium detent sheet on top of Shelf, so the stack can reach two deep and dismissing Hail leaves Shelf standing. Logbook and Settings are large detents that open directly over the chart. The chart stays visible and dimmed behind every sheet, which is what makes the Run badge and the freshly inked Rhumb readable the moment a sheet drops. Review launch keys map to distinct surfaces: today opens the seeded chart with an unspent Run, log opens Logbook over the chart, goals opens Settings, and the extra key shelf opens the Shelf sheet; the arguments are read once from ProcessInfo after onboarding has been marked complete.

### 3.6 Screen composition contract

Chart, Shelf, Logbook, Settings

Seven physical surfaces, four of them destinations. 1) Onboarding, three full pages of paper cut art, one headline and one line each, Continue bottom and full width, skipped on Simulator after the seed mints. 2) Chart (home, root, always present): windrose, genre islands on the fixed grid, solid versus hatched reach, the hailed island wearing its Run badge in tabular digits, inked Rhumbs with small-caps bearing labels, and a full page empty state when no book is moored yet (art, headline, one line, one CTA filling the height). 3) Shelf sheet: live ISBN scan and catalog title search fused in one surface, genre picker that decides the island, moored book rows edge to edge, Finished toggle that writes a Landfall, and a local shelf fallback list when search is empty or offline. 4) Hail sheet (raised on top of Shelf): book header, pages read and minutes fields, and the Hail button which seats the Fix and writes the Run. 5) Logbook sheet: Fixes, Rhumbs, Luffs and Landfalls grouped by daykey, pages per island, rhumb count per pair, and the thickest bearing at the top as a single hero row before the list. 6) Settings sheet: pages per cell reach rate, chart grid size, island genre renaming, local evening reminder toggle and time, and the Contact link to the support page. 7) Camera permission and denied states inside Shelf: a pre-prompt page whose button reads Continue, and a denied page that explains the state and routes to Open Settings.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By portolan role (Chart, Island, Book, Session, Run, Rhumb, FixMark, RhumbMark, LuffMark, Landfall)**

```
Marteloio/
  Marteloio/
  App/ MarteloioApp.swift · AppRoot.swift · DemoSeed.swift · ReviewScreenKeys.swift
  Chart/ ChartScreen.swift · ChartRepresentable.swift · ChartViewController.swift · PortolanFlowLayout.swift · IslandCell.swift · RhumbDecorationView.swift · WindroseDecorationView.swift · RunBadgeView.swift · ChartEmptyState.swift
  Island/ Island.swift · IslandGrid.swift · ReachCost.swift · IslandRename.swift
  Book/ Book.swift · Shelf.swift · ShelfSheet.swift · CatalogClient.swift · LocalShelf.swift · IsbnScanner.swift · ScanReticle.swift · CameraPermission.swift · BookRow.swift
  Session/ Session.swift · HailSheet.swift · PagesEntryField.swift
  Run/ Run.swift · RunLedger.swift
  Rhumb/ Rhumb.swift · RhumbGeometry.swift · BearingLabel.swift
  Marks/ FixMark.swift · RhumbMark.swift · LuffMark.swift · Landfall.swift · Mark.swift
  Fold/ ChartFold.swift · FoldOutcome.swift · Shoal.swift
  Logbook/ LogbookSheet.swift · DaykeyGroup.swift · BearingSummary.swift
  Settings/ SettingsSheet.swift · ReachRateControl.swift · ReminderScheduler.swift · ContactLink.swift
  Store/ ChartRecord.swift · ChartStore.swift · DebouncedSave.swift · Daykey.swift
  Design/ Tokens.swift · TypeScale.swift · Space.swift · Radius.swift · PrimaryButtonStyle.swift · SheetStack.swift · Motion.swift
  Resources/ Assets.xcassets · LocalShelf.json · Info.plist
MarteloioTests/ ReachCostTests.swift · ChartFoldTests.swift · RhumbThickenTests.swift · DaykeyTests.swift · ChartStoreRoundTripTests.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Board
A first-class screen for **Board**. Must render empty, populated and error states.

### 5.3 Analytics
A first-class screen for **Analytics**. Must render empty, populated and error states.

### 5.4 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.5 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.6 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Book** — named per this app's convention.
- **Island** — named per this app's convention.
- **Session** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **storytelling · sheet-stack · branded**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#FFFFFF` | Screen background |
| `surface` | `#FFFFFF` | Cards, rows, sheets |
| `ink` | `#111827` | Primary text and icons |
| `accent` | `#D97706` | Primary action, key figure, progress fill |
| `muted` | `#6A6F76` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro (system default) · monospaced tabular digits for Runs, reach costs and page totals; island names in Title3 semibold with a small-caps bearing label under each rhumb**

SF Pro system default throughout, one face, no second kit. Every number that is arithmetic in the mechanic sets .monospacedDigit with tabular figures: the Run badge, the reach cost preview on each reachable island, pages per island in the Logbook, and page totals in the bearing summary, so a Run counting down from 60 to 40 to 20 does not shuffle its columns. Island names are Title3 semibold, short and wide, and truncate at the tail rather than shrinking below the cell. Under every inked Rhumb sits a small-caps bearing label built with .fontWidth and uppercaseSmallCaps at Caption2 with widened tracking, the one ornamental move on the chart. The display moment is spent once, on the Run numeral in the badge: oversized monospaced digits with tight tracking, one to two lines, never a paragraph. Body is 17pt; custom sizes on the chart go through @ScaledMetric so the island name and the Run badge still fit at AX5 without a clipped headline, and the layout reflows the grid cell rather than cropping the words.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **28pt** for cards, sheets and primary surfaces; **14pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **shadow** — a single soft drop-shadow token, reused everywhere a surface sits above another.

Primary control: **filled capsule** — the primary CTA is a full-width filled `Capsule`, never a bare text link or a plain `.plain` button.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **UIKit UICollectionViewFlowLayout subclass · canvas-first**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **UIKit UICollectionViewFlowLayout subclass · canvas-first** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

### 7.6 Taste DNA

Aesthetic: **agency** (High-end agency: huge type, air, one accent, hairline depth.)

Reference system: **storytelling** — steal rhythm and restraint, not their colours or logos.

Mood: **Narrative-driven design using visuals, copy, and interaction to guide users through engaging, emotionally resonant journeys.**.

Home rhythm (`sheet-stack`, dense): A stack of sheets. The top sheet is the job.

High-end agency: huge type, air, one accent, hairline depth. Layout `sheet-stack`, density dense. Kit 28/14, shadow, filled capsule. Palette recipe `branded`. Grouped reveals step 40-60ms, cap 360ms total. Last item must not arrive late. Reduce Motion: the group appears at once. Reduce Motion: fade only. Do not invent a second radius or a second accent.

Type move: Serif display once; body stays the UI face. Reference type feel: agency.

Motion (`stagger`): Grouped reveals step 40-60ms, cap 360ms total. Last item must not arrive late. Reduce Motion: the group appears at once.

Voice (`warm`): Human and brief. Empty states invite. Errors stay calm and useful.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Sibling cards, images and titles never overlap. Each cell owns its frame;
  `scaledToFill` is clipped to that cell. A chopped headline or two canvases
  in one slot is a defect, not a collage.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark**

One Codable root, ChartRecord, holding the grid size, the reach rate, the Islands with their coordinates and genre names, the Books with ISBN, title, genre island id and finished flag, the Sessions, the current Run (optional, with its origin island and remainder), the Rhumbs keyed by unordered island pair with a weight count, and the flat mark list of FixMark, RhumbMark, LuffMark and Landfall each stamped with a daykey Int in YYYYMMDD form. The whole record encodes to JSON under the single UserDefaults key mrt.chart.v1; nothing else is written. ChartStore holds the record in memory, applies fold transitions, and schedules a debounced save 400ms after the last mark so a burst of Bears writes once, with an immediate flush on scenePhase leaving active. Daykeys come from Calendar.current.startOfDay so a session logged near midnight lands on the day the reader sees. Decode failures fall back to a fresh seeded chart rather than crashing, and the seed itself is minted once behind mrt.demo.v1 under #if targetEnvironment(simulator), which also marks onboarding complete. Session-scoped state, the hatched luffed islands, lives in memory only and clears on the next Hail. No network writes, no iCloud, no account.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Marteloio/1.0 (iOS; +https://marteloio-chart.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.books`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_NSCameraUsageDescription: Marteloio uses the camera to read a book's barcode so you can add it to your shelf without typing the number.
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.books
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Rhumb-reach linking (pages read become a Run; the Run pays 20 pages per chart cell to join two distinct Islands; an over-cost tap writes a LuffMark, hatches that Island for the session and keeps the Run)

Pages read are not a score, they are a budget of distance. Hail writes a Run equal to the pages of the session and seats a Fix on the island of the book being read; Bear spends that Run by tapping a second, distinct island, paying 20 pages for each chart cell between the two, and inks a Rhumb when the Run covers the cost. The arithmetic is the invariant and it is unit tested: cost = 20 × cellDistance, a Bear is legal only when cost is at or under the remaining Run, the remainder is Run minus cost, and the fold moves Hailed to Bound the moment no island is still payable. An over-cost tap is not a failure the reader loses anything to: it writes a LuffMark, hatches that island for the rest of the session, leaves the Run whole, and the reader re-aims at a nearer genre. A pair already joined never draws a duplicate line, it thickens, so after a few weeks the chart reads as traffic between genres rather than a checklist of visits. Bear before Hail is refused, a second Hail while a Run is unspent is refused, and a chart with fewer than two islands writes Shoal. The seed opens Hailed with a 60-page Run and two moored books, so the first tap on home inks a real Rhumb instead of teaching an empty grid.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Paper cut origami collage · tactile**


Base prompt, reused and extended for every asset:

```
Paper cut origami collage, tactile and handmade. Layers of torn and scissor-cut paper stacked with visible fibrous edges, sharp folded creases and valley folds catching a soft raking light, tiny paper shadows separating each layer, faint deckle and vellum grain. Nautical chart vocabulary rendered as folded paper: island shapes, compass rays, straight ruled lines, hatching. Hard-edged geometry, no gradients, no gloss, no plastic, no 3D render sheen, no text, no lettering, no numerals, no emoji. Studio lit from the upper left, shallow depth, composed with asymmetry rather than a centered plate.
```

All 14 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `mrt_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `mrt_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `mrt_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `mrt_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `mrt_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `mrt_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `mrt_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `mrt_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `mrt_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `mrt_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `mrt_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Rhumb-reach linking (pages read become a Run; the Run pays 20 pages per chart cell to join two distinct Islands; an over-cost tap writes a LuffMark, hatches that Island for the session and keeps the Run)' feature screen. |
| 11 | `mrt_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `mrt_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |
| 13 | `mrt_RunBadge` | 1024x1024 | **required cutout** | A small folded paper tag with a pressed rectangular field where a number would sit, blank and unlettered, two crease folds holding it shut, solid opaque paper, centred subject. |
| 14 | `mrt_LandfallRing` | 1024x1024 | **required cutout** | A ring of hatched paper strips laid around an empty centre opening, each strip cut and folded separately with visible fibre edges, solid opaque paper, centred subject. |

### Prompt per asset

**`mrt_AppIcon`** — 1024x1024

```
A single folded paper island with one straight cut paper rhumb line crossing it edge to edge and a small folded compass ray in the corner, layered cut paper with visible fibrous edges and soft paper shadow, centred and filling the canvas, no text, no rounded corners, no transparency.
```

**`mrt_Splash`** — 1290x2796

```
A vertical paper cut chart: scattered folded paper islands toward the top and bottom, straight ruled paper strips joining a few of them, quiet uncluttered middle band with only flat vellum grain so a wordmark reads on top, raking light, no text.
```

**`mrt_Onboarding1`** — 1024x1536

```
A reader's hands closing a paperback beside a folded paper chart laid flat on a table, everything built from stacked cut paper with creased folds and soft layer shadows, tall composition, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`mrt_Onboarding2`** — 1024x1536

```
Mid gesture: a fingertip pressing a folded paper island while a straight cut paper strip is being laid between it and a second island, paper fibres and crease shadows visible, tall composition, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`mrt_Onboarding3`** — 1024x1536

```
A paper chart after long use: many folded islands joined by cut paper lines of varying thickness, a folded compass rose in one corner, dense and worn with softened creases, tall composition, no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`mrt_EmptyHome`** — 1024x1024

```
A solid folded paper island standing alone on a flat vellum plane with no lines touching it, calm and waiting, thick opaque layered paper with creased edges and a soft contact shadow, centred subject.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`mrt_EmptyList`** — 1024x1024

```
A closed paper logbook with folded corner tabs, opaque stacked paper pages, cut edges visible, resting flat and unopened, centred subject.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`mrt_CardBackdrop`** — 1200x800

```
A wide low contrast field of faint paper hatching and a few very soft ruled creases running corner to corner, flat vellum grain, nothing in the centre, quiet enough for text to sit on top.
```

**`mrt_ControlFace`** — 512x512

```
The face of a folded paper compass rose: eight cut paper rays of alternating fold direction radiating from a small raised centre disc, solid opaque paper, crisp shadows between rays, centred subject.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`mrt_TwistHero`** — 1024x1024

```
Two folded paper islands joined by one thick cut paper rhumb strip that visibly doubles in weight at its midpoint, small hatch marks along the strip counting distance, solid opaque paper layers, centred subject.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`mrt_SuccessMark`** — 512x512

```
A small folded paper seal pressed over the end of a cut paper line, crisp crease radiating from the centre, solid opaque paper with a soft shadow, centred subject.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`mrt_HeaderDecor`** — 1200x600

```
A wide band of folded paper compass rays fanning along the horizontal, thin cut paper rules between them, shallow layered shadows, ornamental and quiet.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`mrt_RunBadge`** — 1024x1024

```
A small folded paper tag with a pressed rectangular field where a number would sit, blank and unlettered, two crease folds holding it shut, solid opaque paper, centred subject.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`mrt_LandfallRing`** — 1024x1024

```
A ring of hatched paper strips laid around an empty centre opening, each strip cut and folded separately with visible fibre edges, solid opaque paper, centred subject.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`mrt.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.


---

## 17. Tests

Add a unit test target `MarteloioTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Parse `ProcessInfo.processInfo.arguments` once after onboarding. 
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Marteloio -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Portolan ADT fold (Moored | Hailed | Bound); the chart is a fold over Islands; Hail writes a Run as the pages of this session and seats a Fix on the read Book's Island, folding Moored to Hailed; Bear writes a RhumbMark when the tapped Island is distinct and its reach cost is at or under the Run, inks the Rhumb, subtracts the cost and folds Hailed to Bound when the Run cannot pay any further Island; an over-cost tap writes a LuffMark and keeps the Run; Bear on Moored is refused; a second Hail while Hailed is refused; Hail samples a Book that is not Finished; a pair already joined thickens instead of duplicating; a chart under two Islands writes Shoal** with no leakage across layers.
- [ ] UI approach matches **UIKit UICollectionViewFlowLayout subclass · canvas-first**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Chart-locked chrome (the portolan chart never leaves; Shelf, Logbook and Settings arrive as a sheet stack over the chart; scan and title search fuse on Shelf)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro (system default) · monospaced tabular digits for Runs, reach costs and page totals; island names in Title3 semibold with a small-caps bearing label under each rhumb** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Marteloio
xcodegen generate
xcodebuild -scheme Marteloio -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Marteloio -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.

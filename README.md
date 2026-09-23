# Marteloio

A reading chart for people who move between genres. Log the pages of a session, then tap a second genre island so those pages are spent as distance. The artifact is a thickening graph of rhumb lines, not a stack of star ratings.

## Architecture

The chart is a Portolan ADT fold with three states: **Moored**, **Hailed**, and **Bound**. Hail writes a Run (the pages of this session) and seats a Fix on the book’s island. Bear spends that Run against a reach cost of 20 pages per chart cell. A legal tap inks or thickens a Rhumb. An over-cost tap writes a LuffMark, hatches that island for the session, and leaves the Run whole.

Every transition is a pure function `(ChartRecord, Intent) → (ChartRecord, Mark)`. Reach cost and the fold are unit-tested without a view. Persistence is one Codable root under `mrt.chart.v1` with a debounced save. The UIKit canvas only paints the fold.

This pattern fits the product because the job on home is a state machine over distance, not a list of records.

## Twist

Rhumb-reach linking. Pages become a budget. The Run pays for Chebyshev cells between two islands. A pair already joined thickens instead of duplicating. Seeded Simulator home opens Hailed with a 60-page Run so the first tap can ink a real rhumb.

## Art

Paper cut origami collage, tactile and handmade. Layers of torn and scissor-cut paper stacked with visible fibrous edges, sharp folded creases and valley folds catching a soft raking light, tiny paper shadows separating each layer, faint deckle and vellum grain. Nautical chart vocabulary rendered as folded paper: island shapes, compass rays, straight ruled lines, hatching. Hard-edged geometry, no gradients, no gloss, no plastic, no 3D render sheen, no text, no lettering, no numerals, no emoji. Studio lit from the upper left, shallow depth, composed with asymmetry rather than a centered plate.

Asset prompts live in SPEC.md section 13.2. Imagesets are named `mrt_*`.

## Not a neighbour

This is not Cresset. Nothing walks a token and nothing unlocks a tile. Home spends a Run to join two genres. A TabView with three tabs is not this chrome: the portolan never leaves, and Shelf, Logbook and Settings arrive as a sheet stack.

## Build

```bash
cd Marteloio
xcodegen generate
xcodebuild -scheme Marteloio -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

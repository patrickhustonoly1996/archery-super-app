# Arrow Plotting Specification

Core interaction specification for the archery scoring app. This is the foundation - get this right before layering features.

## Tech Stack

- **Framework**: Flutter
- **Local DB**: Drift (SQLite wrapper)
- **Architecture**: Offline-first (30+ days without connectivity)

---

## Core Plotting Interaction

### Touch-Hold-Drag Flow

1. **Touch** target face anywhere
2. **Hold** (~150ms) triggers:
   - **Offset line** appears from touch point at 45° angle
     - Right-handed: line extends up-left
     - Left-handed: line extends up-right
   - Line length: ~0.5 inch (consistent, clearly separated from finger)
   - **Zoom window** appears at 12 o'clock (top of screen)
     - Shows magnified crosshair at arrow position (end of offset line)
     - Crosshair only in zoom window (no line)
3. **Drag** to fine-tune position
   - Offset line and zoom window move together
   - Crosshair follows at end of offset line
4. **Release** to place arrow
   - Arrow marker appears at crosshair position
   - If shaft tagging enabled → prompt for shaft number
   - Score auto-calculated from position

### Arrow Markers

- **Without shaft tagging**: Black dot (visible, not too large)
- **With shaft tagging**: Black circle with shaft number inside

### Smart Zoom

Zoom level auto-adjusts based on historical grouping data.

**Calculation:**
- Determine user's typical scoring ring range
- Indoor: typical range + 2 rings outward
- Outdoor: typical range + 3 rings outward
- User can override manually; preference is remembered

**Activation:**
- First few ends (~12-18 arrows): Initial calibration
- Cumulative across sessions: Gets smarter over time

**Zoom levels:**
- Smart zoom: Auto-calculated view area
- Plotting zoom: 2× the smart zoom magnification
- Line cutter zoom: 6× magnification (for edge positioning)

### Line Cutter Handling

When arrow is placed very close to a ring boundary:
1. Short zoom-in frame appears (6× magnification)
2. Shows arrow edge relative to line
3. User can reposition edge precisely (optional)
4. Toggle: "Line cutter: In / Out"

### Undo

- Tap last-placed arrow to remove (within current uncommitted end)
- No undo after session is finished (immutable after session end)

---

## End Workflow

### Commit-Based Model

1. Plot all arrows in end (3 or 6 depending on round type)
2. Review placements
3. **Commit** to lock the end
4. **Arrow count enforced**: Cannot commit until correct arrow count reached

### End States

- `drafting` - Arrows being placed, editable
- `committed` - Locked for this session (editable if you return to this end)

### Commit Button

- Appears after final arrow is placed in the end
- Tapping commits the end and advances to next end

### Session Immutability

- **During session**: Can navigate back to any end and edit it
- **After session ends**: All data becomes immutable (append-only)
- Session end requires confirmation screen to prevent accidental closure

### Misses

- Arrows missing the target entirely: plot in rough area outside scoring rings
- Misses still count toward arrow count for the end
- Misses included in Rolling 12 widget (user toggle in settings - longbow archers prefer inclusion)

### Session Interruption

- App crash / phone dies: Auto-resume on next launch
- Prompt: "Resume session?" or "Abandon?"
- Abandoned sessions are still saved (incomplete state)

---

## Plotting Screen Layout

```
┌─────────────────────────────────────────────────┐
│ ┌──────────┐                    ┌─────────────┐ │
│ │Rolling 12│                    │ This Half   │ │
│ │ [mini    │                    │             │ │
│ │ target]  │                    │  avg: 9.5   │ │
│ │          │                    │ ┌─────────┐ │ │
│ └──────────┘                    │ │   285   │ │ │
│                                 │ └─────────┘ │ │
│                                 └─────────────┘ │
├─────────────────────────────────────────────────┤
│                                                 │
│              ┌─────────────────┐                │
│              │                 │                │
│              │   TARGET FACE   │                │
│              │                 │                │
│              │                 │                │
│              └─────────────────┘                │
│                                                 │
├─────────────────────────────────────────────────┤
│  ← Scorecard (slideable)                      → │
│  [1] [2] [3] [4] [5] [6] ...                    │
└─────────────────────────────────────────────────┘
```

### Rolling 12 Widget (Top Left)

- **Visual**, not numeric
- Mini target face showing last 12 arrows plotted
- Shows group position/drift relative to center
- Helps archer see if sight needs adjustment
- Updates in real-time as arrows are placed

### This Half Widget (Top Right)

- Running total score for current half
- Running average (score per arrow)
- Updates after each arrow placement
- "Half" = first half of total ends (e.g., ends 1-6 of 12, ends 1-5 of 10)

### Scorecard (Bottom)

- Horizontally slideable
- Shows all ends in current round
- Current end highlighted
- Tap any end to navigate to it (editable during session)
- Can navigate away to other app tabs; session data preserved until explicit end

---

## Multi-Face Indoor Mode

For indoor rounds using 3-spot target (3 separate faces).

### Setup

At session start, prompt: "Which order do you shoot the faces?"
- Options: Top→Bottom, Bottom→Top, or custom order
- This sets the automatic face progression

### Layout

- **Three-face view**: Shows all 3 faces with indicator highlighting current target
- After placing arrow, auto-jumps to next face in user's chosen order
- **Combined overlay**: All 3 faces overlaid for group analysis (review mode)

### Behavior

- Each face tracks its own arrows
- Automatic progression follows user's shooting order preference
- Shaft tagging and multi-face are independent features

---

## Shaft Tagging

Optional feature for tracking individual arrow shafts.

### Enable/Disable

- Toggled per session in round setup
- Default: OFF

### Flow (When Enabled)

1. Place arrow on target
2. Prompt appears: "Which shaft?"
3. Options: shaft numbers from selected quiver + "Skip"
4. Selection recorded with arrow data

### Skip Option

- Always available
- Use case: messed up shot, not arrow's fault
- Arrow still recorded, shaft_id = null

---

## Equipment Data Model

### Hierarchy

```
Bow
├── id (uuid)
├── name (string)
├── type (recurve | compound)
├── settings (json - tiller, brace height, etc.)
├── is_default (boolean)
├── created_at
└── updated_at

Quiver (arrow set)
├── id (uuid)
├── bow_id (fk, nullable - can be unassigned)
├── name (string)
├── shaft_count (int - typically 12, up to 72+)
├── is_default (boolean)
├── created_at
└── updated_at

Shaft
├── id (uuid)
├── quiver_id (fk)
├── number (int - 1-12, 13-24, etc.)
├── diameter (float, optional - differentiates indoor/outdoor)
├── notes (string, optional)
├── created_at
└── retired_at (nullable - soft delete)
```

### Quiver Creation

- Created in batches of 12 shafts
- Can expand: 12 → 24 → 36 → etc.
- Pro feature (future): AI sorting into optimal groups based on grouping data

---

## Session Data Model

### Round Session

```
RoundSession
├── id (uuid)
├── round_type_id (fk - WA720, Portsmouth, etc.)
├── bow_id (fk)
├── quiver_id (fk, nullable)
├── shaft_tagging_enabled (boolean)
├── session_type (practice | competition)
├── competition_level (nullable, optional - only shown if competition)
│   └── practice_comp | local | record_status | national | international
│   └── User can skip selection
├── started_at
├── completed_at (nullable)
└── location (string, optional)
```

### End

```
End
├── id (uuid)
├── session_id (fk)
├── end_number (int)
├── face_count (int - 1 for outdoor, 3 for indoor tri-spot)
├── status (drafting | committed)
├── committed_at (nullable)
└── created_at
```

### Arrow

```
Arrow
├── id (uuid)
├── end_id (fk)
├── shaft_id (fk, nullable - only if tagging enabled and not skipped)
├── face_index (int - 0 for single face, 0-2 for tri-spot)
├── x (float - normalized 0-1 from center)
├── y (float - normalized 0-1 from center)
├── score (int - calculated from position)
├── is_x (boolean - inner 10)
├── sequence (int - order shot within end)
└── created_at
```

### Coordinate System

- Origin at target center (0, 0)
- Normalized coordinates: -1 to +1 range
- Positive X = right, Positive Y = up
- Score rings calculated from distance to origin

---

## Data Integrity Rules

1. **Append-only**: Committed ends never modified
2. **No silent rewrites**: History is immutable
3. **Local authority**: Device is source of truth
4. **Sync = backup**: Cloud is secondary (future, not v1)

---

## Round Types

### Favourites List

Sorted by frequency of use. Defaults for new users:
1. **18m 30 arrows** - 10 ends × 3 arrows (half WA18, indoor)
2. **70m 72 arrows** - 12 ends × 6 arrows (full WA720, outdoor)

### Custom Round Creation

At bottom of favourites list. Parameters:
- Distance (meters)
- Face size
- Arrows per end (3 or 6)
- Number of ends
- Indoor/outdoor (affects face type options)

---

## Left-Handed Mode

Global app setting that mirrors the entire UI.

### What Flips

- **Offset line direction**: 45° up-right instead of up-left
- **Menu positions**: Slide from right instead of left
- **Widget positions**: Rolling 12 moves to top-right, This Half to top-left
- **All directional UI**: Consistent right-handed feel for left-handed users

---

## Orientation Support

### Portrait Mode (Default)

Standard layout as shown in diagrams.

### Landscape Mode

- Scale everything proportionally
- Target face expands to use available space
- Widgets and scorecard maintain relative positions

---

## Settings

### User Preferences

- Left-handed mode (global flip)
- Include misses in Rolling 12 (toggle, default: off)
- Smart zoom override per distance/face type
- Indoor face shooting order preference

---

## Future Considerations (Not v1)

- AI-powered shaft sorting into optimal groups
- Cloud sync via Supabase
- Group analysis and trend reporting
- Sight adjustment recommendations based on group drift
- Export to competition formats

# MVP - Remaining Work

Single source of truth. Updated 2026-01-17.

---

## 1. Front Camera Default
**Files:** `lib/screens/delayed_camera_native.dart`, `delayed_camera_web.dart`
- Currently `CameraLensDirection.back` (rear)
- Change to `CameraLensDirection.front` (selfie)
- Keep toggle to switch cameras

---

## 2. Vibrations All Breath Screens
**Files:** `lib/screens/breath_training/*.dart`
- HapticFeedback only in patrick_breath_screen currently
- Add HapticFeedback.mediumImpact() at phase transitions in:
  - `paced_breathing_screen.dart`
  - `breath_hold_screen.dart`
- VibrationService exists, just needs calling

---

## 3. Breathing Cues More Obvious (Web)
**Files:** All breath training screens
- Cues not prominent enough on web browser
- Move breathing indicator to center of screen
- Increase size for web (use MediaQuery to detect)
- Add subtle animation to draw attention

---

## 4. Splash Branding
**Files:** Splash screen / launch assets
- Add "built by HUSTON ARCHERY" text below app icon
- Gold text (#FFD700) on dark background
- VT323 font

---

## 5. Equipment Expansion (Make It Class)
**Files:** `lib/db/database.dart`, equipment screens

Comprehensive tuning log. All fields optional. Purchase date on everything.

### Bows Table - Expand:
**Basic:**
- riserModel (TEXT)
- riserPurchaseDate (TEXT)
- limbModel (TEXT)
- limbPurchaseDate (TEXT)
- poundage (REAL) - draw weight in lbs

**Tuning:**
- tillerTop (REAL) - mm
- tillerBottom (REAL) - mm
- braceHeight (REAL) - inches
- nockingPointHeight (REAL) - mm above square
- buttonPosition (REAL) - mm from riser
- buttonTension (TEXT) - soft/medium/stiff or number
- clickerPosition (REAL) - mm

### New Stabilizers Table:
- id, bowId (FK)
- **Long rod:** model, length (inches), weight (oz), purchaseDate
- **Side rods:** model, length (inches), weight (oz), purchaseDate
- **Extender:** length (inches)
- **V-bar:** model, angleHorizontal (deg), angleVertical (deg)
- **Weights:** arrangement (TEXT) - e.g. "3x1oz long, 2x1oz sides"
- **Dampers:** model, positions (TEXT)

### New Strings Table:
- id, bowId (FK)
- material (TEXT) - e.g. "8125G", "BCY-X"
- strandCount (INT)
- servingMaterial (TEXT)
- stringLength (REAL) - inches
- purchaseDate (TEXT)

### Arrows/Shafts Table - Expand:
**Already has:** spine, lengthInches, pointWeight, fletchingType, fletchingColor, nockColor

**Add:**
- totalWeight (REAL) - grains
- pointType (TEXT) - break-off, glue-in, etc.
- nockBrand (TEXT)
- fletchingSize (TEXT) - e.g. "1.75 inch"
- fletchingAngle (REAL) - helical degrees
- hasWrap (BOOL)
- wrapColor (TEXT)
- purchaseDate (TEXT)

### UI:
- Sectioned form (collapsible sections for each category)
- Clean detail view showing all entered data
- Skip empty fields in display
- Professional, not cluttered

---

## 6. Group Visualization (Settings-Based)
**Files:** `lib/widgets/group_centre_widget.dart`, settings

NOT always-on. User enables in settings when they want it.

**Options to toggle:**
- Color arrows by end (End 1: Gold, End 2: Cyan, etc.)
- Show ring notation ("9.2 group")
- Show spread ellipse (already implemented)

**Implementation:**
- Add toggles to plotting settings
- Store preferences
- Only render when enabled

---

## 7. Nock Rotation (Settings Option)
**Files:** `lib/db/database.dart`, plotting settings, shaft selector

Add as optional setting in plotting:
- Toggle: "Track nock rotation"
- When enabled, shaft selector shows small arrow rear-view graphic
- Tap fletch position (12, 4, 8 o'clock) or skip
- Add `nockRotation` column to Arrows table (nullable TEXT)

Most users will never use this - it's for tuning analysis.

---

## Post-MVP (Defer)

- Clicks-per-ring wizard
- 252 scheme tracker
- OLY training system upgrade

---

## Already Complete

- Error handling wrapper
- Form validation mixin
- Empty state widget
- Volume import save fix
- Exhale test redesign
- Kit tuning framework
- Group spread ellipse
- Shaft analysis screen
- Inter-device sync
- Plotting coordinate fix
- Zoom/pinch/linecutter
- 5-zone imperial scoring
- Volume chart improvements
- Timer pause on background
- Kit snapshot prompts
- Test coverage (1,348 tests)
- Shaft tagging (auto-enables with quiver)

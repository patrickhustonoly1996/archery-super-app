# UX Audit Fixes - January 2026

**Epic:** Comprehensive UX fixes identified through full app walkthrough
**Owner:** Patrick Huston
**Created:** 2026-01-20

---

## Plotting & Scoring

### US-001: Fix pinch-to-zoom on target face

**Priority:** P1

Pinch zoom gesture is not working on the plotting target face. Users cannot zoom in/out to place arrows precisely.

- [ ] Pinch gesture detected and handled on target face widget
- [ ] Zoom smoothly scales target while maintaining arrow positions
- [ ] Zoom has sensible min/max bounds (e.g., 0.5x to 4x)
- [ ] Double-tap to reset zoom to default

---

### US-002: Fix undo to cycle through all arrows

**Priority:** P1

Undo button should cycle back through all placed arrows, not just the most recent one.

- [ ] Undo removes most recent arrow
- [ ] Repeated undo continues removing arrows in reverse order
- [ ] Can undo all arrows back to empty end
- [ ] Redo option available after undo (or clear confirmation before destructive undo)

---

### US-003: Fix settings panel freezing in plotting

**Priority:** P1

Plotting settings panel becomes unresponsive after clicking a couple of options.

- [ ] Identify root cause of freeze (setState rebuild issue? modal state?)
- [ ] Settings panel remains responsive through all interactions
- [ ] All setting toggles work without requiring app restart
- [ ] Test with rapid setting changes to confirm stability

---

### US-004: Fix score calculation exceeding round maximum

**Priority:** P1

Final score displays impossible values like 311/300. Rounds have defined maximum scores that must be enforced.

- [ ] Each round type has defined max score in round definitions
- [ ] Score calculation capped at round maximum
- [ ] Warning shown if calculated score exceeds maximum (indicates bug)
- [ ] Audit all round definitions for correct max scores
- [ ] Add unit tests for score bounds on each round type

---

### US-005: Fix York round showing all arrows as line-cutters

**Priority:** P1

**Depends on:** US-004

York round (and potentially other rounds) showing every arrow as a line-cutter. Investigate if this affects other rounds, large target faces, or 5-zone scoring specifically.

- [ ] Investigate line-cutter detection logic for large target faces
- [ ] Test 5-zone vs 10-zone scoring rings
- [ ] Test across multiple round types (York, Hereford, Bristol, etc.)
- [ ] Line-cutter detection uses correct ring radii for each target face size
- [ ] Add visual indicator distinguishing line-cutters from clean hits

---

### US-006: Multi-distance round progression

**Priority:** P1

**Depends on:** US-004

Multi-distance rounds (York, WA 1440, etc.) must automatically progress to the next distance when current distance is complete.

- [ ] Round definition includes distance sequence (e.g., 100yd → 80yd → 60yd)
- [ ] App detects when current distance's arrows are complete
- [ ] Prompt or auto-transition to next distance
- [ ] Clear visual indicator of current distance
- [ ] Distance changes reflected in scorecard sections

---

### US-007: Triple spot - keep all arrows visible across faces

**Priority:** P2

In triple-spot indoor rounds, arrows from other faces disappear when plotting on current face. All arrows should remain visible.

- [ ] All arrows visible across all three faces simultaneously
- [ ] Arrows on non-active faces shown at reduced opacity or different style
- [ ] Option to view faces separately in combined screen layout
- [ ] Tapping a face makes it active for plotting
- [ ] Arrow count per face shown clearly

---

### US-008: Enlarge mini target widgets

**Priority:** P2

Mini target widgets on dashboard/summary screens are too small to be useful.

- [ ] Mini targets increased to minimum 80px diameter (from current ~40px)
- [ ] 10-ring clearly visible and distinct from inner gold
- [ ] Ring colors match full-size target exactly
- [ ] Arrows visible as distinct dots on mini target
- [ ] Responsive sizing based on available screen space

---

### US-009: Fix purple arrow color on red rings

**Priority:** P2

Purple arrow indicator on red rings has poor contrast. Green works better.

- [ ] Arrow indicator color has sufficient contrast on all ring colors
- [ ] Consider white outline/shadow on arrow markers
- [ ] Or use adaptive color (light on dark rings, dark on light rings)
- [ ] Test visibility on all ring colors (gold, red, blue, black, white)

---

### US-010: Remove redundant "(12)" label from Last 12 widget

**Priority:** P3

"Last 12" widget shows "(12)" which is redundant - the name already says 12.

- [ ] Remove "(12)" suffix from Last 12 widget title
- [ ] Review other widgets for similar redundancy

---

### US-011: Fix weird numbers appearing beside widgets

**Priority:** P2

Unexplained numbers appearing next to widgets on plotting/dashboard screens.

- [ ] Identify source of stray numbers (debug output? index values?)
- [ ] Remove all debug/diagnostic text from production UI
- [ ] Review widget tree for unintended Text widgets

---

### US-012: Full scorecard view with scroll

**Priority:** P2

Scorecard panel cannot be viewed in full - should slide up to fill available screen space.

- [ ] Scorecard panel draggable to full screen height
- [ ] Smooth snap points (collapsed, half, full)
- [ ] All scorecard data visible when fully expanded
- [ ] Pull down to collapse

---

### US-013: Scorecard signing and export after round

**Priority:** P2

**Depends on:** US-012

At round completion, need signing capability and export options.

- [ ] "Sign scorecard" button at round completion
- [ ] Signature capture (finger drawing)
- [ ] Export as image (PNG) matching WA scorecard format
- [ ] Export as PDF option
- [ ] Share sheet integration for export

---

### US-014: WA scorecard format display

**Priority:** P2

**Depends on:** US-012

Completed scored rounds should display in official WA scorecard layout.

- [ ] Scorecard layout matches WA official format
- [ ] Archer name, date, round type in header
- [ ] Ends grouped correctly per distance
- [ ] Running totals, hits, golds columns
- [ ] Signature line at bottom

---

### US-015: Select arrow in scorecard to delete/re-plot

**Priority:** P2

**Depends on:** US-012

Allow tapping an arrow in the scorecard to delete it or re-plot its position.

- [ ] Tap arrow score in scorecard highlights it
- [ ] "Delete" option removes arrow and updates score
- [ ] "Re-plot" option opens target face with that arrow selected
- [ ] Changes propagate to all score totals immediately

---

### US-016: Compound scoring - outdoor 10-zone uses recurve scoring

**Priority:** P1

Compound scoring rules: indoors uses inner-10 (X), but all outdoor 10-zone rounds use standard recurve scoring (no inner-10 distinction).

- [ ] Round definitions include indoor/outdoor flag
- [ ] Compound + outdoor + 10-zone = standard scoring (10 is 10)
- [ ] Compound + indoor = X-ring scoring (inner-10 = X)
- [ ] Visual target shows X-ring only for indoor compound
- [ ] Score display shows X count only when applicable

---

### US-017: Compound X-ring display and scoring

**Priority:** P2

**Depends on:** US-016

Indoor compound shows recurve 10-ring with X (inner-10) inside. Need clear visual and scoring distinction.

- [ ] Indoor compound target shows outer-10 and inner-X rings
- [ ] X-ring has small + marker in center
- [ ] Scorecard shows X count separately
- [ ] Recurve 10 vs Compound X terminology correct throughout

---

### US-018: Arrow tracking toggle (persistent setting)

**Priority:** P2

Arrow/shaft tracking should be a toggle setting, not a per-session choice that resets.

- [ ] "Track arrows by shaft" toggle in plotting settings
- [ ] Setting persists across sessions
- [ ] When off, no shaft selection UI shown
- [ ] When on, shaft selector appears before/during plotting

---

### US-019: Skip tracking as toggle, allow deselect

**Priority:** P2

**Depends on:** US-018

"No tracking" shouldn't force back each time. Should be able to deselect shaft or set "don't track this session."

- [ ] "No shaft" option in shaft selector
- [ ] Can deselect currently selected shaft
- [ ] "Don't ask again this session" option
- [ ] Session-level override doesn't change global setting

---

### US-020: Fix "Complete Session" button in plotting

**Priority:** P1

"Complete session" button not working - cannot finish and save a plotting session.

- [ ] Identify why complete session fails (state issue? validation?)
- [ ] Complete session saves all plotted data
- [ ] Navigate to summary/scorecard after completion
- [ ] Session appears in history after completion

---

## Skills, XP & Progression

### US-021: Fix awards, fireworks, and tunes not triggering

**Priority:** P1

Gamification system not running - no celebratory feedback when user progresses. This is a major engagement feature.

- [ ] Audit skill progression event firing
- [ ] Fireworks animation triggers on level-up
- [ ] Chiptune plays on achievements
- [ ] Award popups display correctly
- [ ] Test progression events for each skill type

---

### US-022: Skill tap shows XP explanation

**Priority:** P2

Tapping a skill on the skills page should explain what actions give XP for that skill.

- [ ] Tap skill opens detail/info panel
- [ ] Shows current XP and level
- [ ] Lists actions that award XP for this skill
- [ ] Shows XP amount per action type
- [ ] Progress bar to next level

---

### US-023: Fix Equipment skill XP not awarding

**Priority:** P2

Filling in equipment details awards 0 XP - Equipment skill has no way to gain XP.

- [ ] Define XP actions for Equipment skill (add bow, add arrows, complete setup, etc.)
- [ ] XP awarded when equipment details saved
- [ ] Bonus XP for complete equipment profile
- [ ] Equipment skill shows in skills list with progress

---

### US-024: Redesign achievement badges

**Priority:** P3

Current badges are plain symbols in circles. Should look like prestigious engraved shields - something epic, like Mario power-ups for archery.

- [ ] Design badge template as shield/medallion shape
- [ ] Metallic/engraved visual style
- [ ] Distinct designs per achievement type
- [ ] Bronze/silver/gold/platinum tiers where applicable
- [ ] Follows existing app design language (gold #FFD700, dark base)
- [ ] Badges feel collectible and rewarding

---

### US-025: Enlarge level logos on main menu

**Priority:** P2

Level indicators on main menu too small to read clearly.

- [ ] Level badges minimum 32px on main menu
- [ ] Clear level number visible
- [ ] Consistent placement and sizing
- [ ] Tappable to view skill details

---

## Camera

### US-026: Camera saves still image instead of 20s video

**Priority:** P2

Camera feature saving a still image when it should capture a 20-second shot video.

- [ ] Identify if this is video capture vs photo mode issue
- [ ] Camera records 20-second video clip
- [ ] Clear UI indication that video is recording
- [ ] Countdown/progress during recording
- [ ] Video saved to gallery/app storage correctly

---

## Equipment

### US-027: Arrow details missing from quiver view

**Priority:** P2

Arrow specs visible in equipment section but not showing in quiver view.

- [ ] Quiver view shows arrow shaft details (spine, length, points, etc.)
- [ ] Each arrow in quiver linked to its spec data
- [ ] Tap arrow in quiver shows full details

---

### US-028: Equipment fields appearing late/progressively

**Priority:** P2

When first filling equipment, subsequent fields weren't visible but appeared later. Fields should all be present from start.

- [ ] All equipment fields visible on initial load
- [ ] No progressive disclosure hiding required fields
- [ ] Optional fields clearly marked as optional
- [ ] Form layout consistent regardless of existing data

---

### US-029: Add poundage-on-fingers and draw length to equipment

**Priority:** P2

Equipment should track:
- Limb marked poundage (what's written on limbs)
- Poundage on fingers (actual draw weight at archer's draw length)
- Draw length

- [ ] "Limb poundage" field (marked weight)
- [ ] "Draw length" field (inches or cm)
- [ ] "Poundage on fingers" field (actual weight)
- [ ] Auto-calculate estimate if draw length known (optional helper)
- [ ] Fields appear in bow equipment section

---

## Timers, Breathing & Hold Logic

### US-030: Fix hold time mismatch (advertised vs actual)

**Priority:** P1

Bow training advertises 26s hold but app asks for 30s. Displayed time must match actual timer.

- [ ] Audit all bow training level definitions
- [ ] Advertised time matches timer countdown exactly
- [ ] No off-by-one or rounding errors
- [ ] Test each OLY level for time accuracy

---

### US-031: Make breath-hold entry levels easier

**Priority:** P2

Breath-hold training entry levels too difficult for beginners.

- [ ] Review Level 1-3 breath hold durations
- [ ] Add gentler introductory levels if needed
- [ ] Or adjust existing early levels to shorter holds
- [ ] Clear progression path from easy to challenging

---

### US-032: Move breathing cues to top of session screen

**Priority:** P2

Breathing phase indicators (inhale/exhale/hold) should be at top of screen, not buried.

- [ ] Breathing cue text/indicator at top of timer screen
- [ ] Large, clear phase indicator
- [ ] Visible without scrolling or searching

---

### US-033: Fix intermittent beeps and haptics

**Priority:** P1

Audio beeps and haptic feedback only trigger occasionally during breathing/timer sessions. Should run consistently.

- [ ] Audit beep/haptic trigger conditions
- [ ] Ensure audio session configured for background/foreground
- [ ] Haptics fire on every phase change
- [ ] Beeps fire on every countdown tick (where designed)
- [ ] Test on device (not just simulator)

---

### US-034: Fix timing bug when switching from rest

**Priority:** P2

Switching from 0 (rest?) to 6/4 timer appears to add an extra second.

- [ ] Investigate timer transition logic
- [ ] No extra second added on phase transitions
- [ ] Timer starts immediately at correct value
- [ ] Add logging to track timer state changes for debugging

---

### US-035: Improve bow training cancel screen

**Priority:** P2

Screen shown when canceling bow training would work better for custom session builder than current popup.

- [ ] Review cancel screen layout
- [ ] Consider using this layout for custom session builder
- [ ] Or improve cancel confirmation to be more useful
- [ ] Provide option to save partial session on cancel

---

### US-036: Fix "Complete Session" reliability in bow training

**Priority:** P1

Complete session button not working reliably in bow training.

- [ ] Identify failure conditions for complete session
- [ ] Session always saves when complete tapped
- [ ] Feedback confirms session saved
- [ ] Session appears in history

---

### US-037: Move custom timer to top of bow training screen

**Priority:** P2

Custom timer builder currently at bottom of screen, should be at top for visibility.

- [ ] Custom timer section at top of bow training screen
- [ ] Clear "Create Custom Session" entry point
- [ ] Standard sessions listed below

---

### US-038: Add pause option to bow training sessions

**Priority:** P2

No way to pause mid-session in bow training. Need pause/resume capability.

- [ ] Pause button visible during session
- [ ] Timer stops on pause
- [ ] Clear "Paused" state indication
- [ ] Resume continues from paused state
- [ ] Option to cancel from paused state

---

## Sight Marks & Measurements

### US-039: Sight marks yards-to-meters conversion

**Priority:** P2

Sight marks need to compute conversions both ways (yards ↔ meters).

- [ ] Enter sight mark at any distance in yards or meters
- [ ] App calculates equivalent in other unit
- [ ] Conversion uses standard formula
- [ ] Both values displayed

---

### US-040: Auto-fill sight mark increments

**Priority:** P2

**Depends on:** US-039

Once a couple sight marks are set, auto-fill standard increments.

- [ ] With 2+ sight marks entered, extrapolate curve
- [ ] Fill increments: 18m, 30m, 50m, 60m, 70m, 90m
- [ ] Fill increments: 20yd, 30yd, 40yd, 50yd, 60yd, 80yd, 100yd
- [ ] Mark calculated values as "estimated" vs confirmed
- [ ] User can override/confirm each value

---

### US-041: Fix meter-to-yard sight mark transfer

**Priority:** P2

**Depends on:** US-039

If user has 70m and 20m marks, app should calculate what 60 yards would be.

- [ ] Interpolation between known marks
- [ ] Cross-unit calculation (meters data → yards estimate)
- [ ] Clear indication when value is calculated vs entered
- [ ] Reasonable accuracy for typical sight mark curves

---

## Accessibility & UI

### US-042: Increase base text size

**Priority:** P2

Text still very small - difficult to read even at 115% zoom for a 30-year-old.

- [ ] Audit all text sizes in app
- [ ] Body text minimum 16px (ideally 18px)
- [ ] Labels and secondary text minimum 14px
- [ ] Test readability on various devices

---

### US-043: Add accessibility options in settings

**Priority:** P2

Settings should include accessibility controls.

- [ ] Text size slider/options (small, medium, large, extra large)
- [ ] High contrast mode option
- [ ] Settings persist across sessions
- [ ] Preview changes before applying

---

### US-044: Add Import Volumes to settings

**Priority:** P3

Import volumes feature should be accessible from settings menu, not just its current location.

- [ ] "Import Data" or "Import Volumes" option in settings
- [ ] Navigates to existing import functionality
- [ ] Consistent with other data management in settings

---

### US-045: Temperature unit option (F/C)

**Priority:** P3

Temperature shown in Fahrenheit for US users, but should have option to switch.

- [ ] Temperature unit setting (Celsius/Fahrenheit)
- [ ] Auto-detect from locale as default
- [ ] User can override
- [ ] All temperature displays use selected unit

---

## Authentication

### US-046: Fix persistent sign-out issue

**Priority:** P1

Users keep getting signed out. Auth session should persist until explicit logout.

- [ ] Identify cause of unexpected sign-outs (token expiry? storage issue?)
- [ ] Auth token persisted to secure storage
- [ ] Token refresh happens before expiry
- [ ] Session survives app restart
- [ ] Session survives device restart
- [ ] Only explicit "Log out" clears session

---

## Navigation & App State

### US-047: Loading indicator on splash screen

**Priority:** P3

Loading wheel doesn't animate on splash screen when returning from a tab.

- [ ] Loading indicator visible and animating during app initialization
- [ ] Smooth transition from splash to home
- [ ] No frozen/static splash states

---

### US-048: Remove unnecessary splash screen on tab navigation

**Priority:** P2

Splash screen appearing when navigating from tab back to main menu. Should be instant navigation.

- [ ] Tab to home navigation is instant
- [ ] Splash screen only on cold app start
- [ ] No splash on internal navigation
- [ ] Audit navigation stack for unnecessary rebuilds

---

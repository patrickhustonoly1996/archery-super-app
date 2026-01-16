# PRD: Polish & Fixes Completion

**Author:** Patrick Huston
**Date:** 2026-01-16
**Status:** Ready for Development
**Estimated Sessions:** 2-3 dev loops

---

## Overview

Complete the remaining items from the Code Review & Upgrade Roadmap. Testing is done (1,348 tests passing). This PRD covers bug fixes, UX polish, code quality, and accessibility improvements.

---

## Priority 1: Critical Bugs (P0)

### P0-1: Silent CSV Import Failures

**Problem:** When importing scores or volume data, invalid rows are silently skipped. User thinks import succeeded but data is missing.

**Location:**
- `lib/screens/import_screen.dart:190-192`
- `lib/screens/volume_import_screen.dart:190-193`

**Requirements:**
- [ ] Track skipped rows with reason (invalid date, bad score, etc.)
- [ ] After import, show summary dialog: "Imported X scores, skipped Y rows"
- [ ] If rows skipped, show expandable list of skipped rows with line numbers and reasons
- [ ] Allow user to copy skipped rows to clipboard for manual fixing
- [ ] If ALL rows fail, show error state (not success with 0 imported)

**Acceptance Criteria:**
1. Import 10 valid rows + 2 invalid rows → shows "Imported 10, skipped 2"
2. Click "View skipped" → see line numbers and reasons
3. Import file with all invalid rows → shows error, not success

---

### P0-2: ID Collision Risk

**Problem:** IDs generated using `DateTime.now().millisecondsSinceEpoch` can collide if two items created in same millisecond.

**Location:**
- `lib/providers/equipment_provider.dart:43`
- `lib/screens/import_screen.dart:332`
- Any other places using millisecond timestamps for IDs

**Requirements:**
- [ ] Add `uuid` package to pubspec.yaml
- [ ] Replace all `DateTime.now().millisecondsSinceEpoch.toString()` with `const Uuid().v4()`
- [ ] Audit codebase for any other millisecond-based ID generation

**Acceptance Criteria:**
1. Create two bows rapidly → both have unique UUIDs
2. Import scores quickly → no ID collisions
3. All existing data continues to work (UUIDs are strings, same as before)

---

## Priority 2: Phase 1 - Critical Infrastructure

### P1-1: Error Handling Wrapper

**Problem:** Errors are silently swallowed throughout the app. User never knows when something fails.

**Requirements:**
- [ ] Create `lib/utils/error_handler.dart` with `ErrorHandler.run()` method
- [ ] Wrapper should:
  - Execute async action
  - Show loading state (optional)
  - On success: show success snackbar (optional)
  - On error: show error snackbar with retry option
  - Log errors to debug console
- [ ] Apply to critical operations: save session, import data, sync to cloud

**API Design:**
```dart
await ErrorHandler.run(
  context,
  () => saveSession(),
  successMessage: 'Session saved',
  errorMessage: 'Failed to save session',
);
```

**Acceptance Criteria:**
1. Network fails during backup → user sees "Backup failed" with retry button
2. Database write fails → user sees error message, not silent failure
3. Success operations show brief confirmation

---

### P1-2: Form Validation Mixin

**Problem:** Forms accept any input without validation. Login, equipment forms have no validation.

**Requirements:**
- [ ] Create `lib/mixins/form_validation_mixin.dart`
- [ ] Include validators for:
  - Email (format check)
  - Required field (non-empty)
  - Number (with optional min/max)
  - Password (min length)
- [ ] Apply to login screen
- [ ] Apply to equipment creation forms (bow name required, etc.)

**Acceptance Criteria:**
1. Login with invalid email → shows "Invalid email format" inline
2. Create bow with empty name → shows "Name required"
3. Validation shows as user types (not just on submit)

---

### P1-3: Empty State Widget

**Problem:** Screens show nothing when data is empty. User doesn't know what to do.

**Requirements:**
- [ ] Create `lib/widgets/empty_state.dart`
- [ ] Props: icon, title, subtitle (optional), action button (optional)
- [ ] Apply to:
  - History screen (no sessions)
  - Equipment screen (no bows/quivers)
  - Statistics screen (no data for charts)

**Design:**
- Centre of screen
- 64px muted icon
- Title in headline style
- Subtitle in muted text
- Gold primary button for CTA

**Acceptance Criteria:**
1. New user with no sessions → sees "No sessions yet" with "Start Your First Session" button
2. No bows → sees "No bows added" with "Add Bow" button
3. Empty states match app aesthetic (dark + gold)

---

## Priority 3: Phase 3 - UX Improvements

### P3-1: Loading Button Component

**Problem:** Buttons don't show loading state during async operations. Users tap multiple times.

**Requirements:**
- [ ] Create `lib/widgets/loading_button.dart`
- [ ] Props: label, onPressed, isLoading
- [ ] When loading: show spinner, disable button
- [ ] Apply to: login button, save buttons, import confirm

**Acceptance Criteria:**
1. Tap login → button shows spinner, can't tap again
2. Operation completes → button returns to normal

---

### P3-2: Import Feedback Improvements

**Problem:** Import screens don't show progress or detailed results.

**Requirements:**
- [ ] Show progress indicator during CSV parsing
- [ ] Show preview of data before confirming import
- [ ] After import, show detailed summary (see P0-1)
- [ ] For large files (>100 rows), show "Processing X of Y"

**Acceptance Criteria:**
1. Select large CSV → see parsing progress
2. Before confirm → see preview of first few rows
3. After import → see detailed summary

---

### P3-3: Undo for Destructive Operations

**Problem:** Deleting sessions, equipment is permanent with no undo.

**Requirements:**
- [ ] After delete, show snackbar with "Undo" action for 5 seconds
- [ ] If undo tapped, restore the item
- [ ] Apply to: session delete, bow delete, quiver delete, shaft delete
- [ ] Implementation: soft delete (mark as deleted, purge after undo window)

**Acceptance Criteria:**
1. Delete session → see "Session deleted" with Undo button
2. Tap Undo within 5s → session restored
3. Wait 5s → session permanently gone

---

### P3-4: Offline Indicator

**Problem:** User doesn't know their connectivity status or if data is syncing.

**Requirements:**
- [ ] Show subtle indicator in app bar when offline
- [ ] Show sync status indicator when backup in progress
- [ ] Use connectivity_plus package to detect network state

**Design:**
- Offline: small icon in app bar (cloud with X)
- Syncing: small spinning icon
- Online + synced: no indicator (clean state)

**Acceptance Criteria:**
1. Turn off wifi → see offline indicator appear
2. Turn on wifi → indicator disappears
3. Backup in progress → see sync indicator

---

## Priority 4: Phase 4 - Code Quality

### P4-1: Extract Constants

**Problem:** Magic numbers scattered throughout codebase.

**Requirements:**
- [ ] Create `lib/config/app_constants.dart`
- [ ] Move from widgets:
  - Plotting offsets (60.0 finger offset)
  - Linecutter threshold (0.04)
  - Scorecard column widths
  - Touch target sizes
- [ ] Document each constant's purpose

**Acceptance Criteria:**
1. All magic numbers have named constants
2. Each constant has comment explaining its purpose
3. No behaviour change (pure refactor)

---

### P4-2: Extract Shared Widgets

**Problem:** Score display, card layouts duplicated across screens.

**Requirements:**
- [ ] Create `lib/widgets/score_display.dart` - reusable score with optional max/X count
- [ ] Identify and extract other duplicated widgets
- [ ] Update screens to use shared widgets

**Acceptance Criteria:**
1. Score displays look identical across all screens (using same widget)
2. Reduced code duplication
3. No visual changes

---

### P4-3: Replace Print with Logging

**Problem:** `print()` statements in production code, inconsistent logging.

**Requirements:**
- [ ] Replace all `print()` with `debugPrint()` (only runs in debug mode)
- [ ] For important operations, use structured logging
- [ ] Primary file: `lib/services/firestore_sync_service.dart` (20+ print calls)

**Acceptance Criteria:**
1. No `print()` calls in lib/ (only `debugPrint`)
2. Production builds don't log to console
3. Debug builds still show useful logs

---

### P4-4: Extract Round Matching Logic

**Problem:** Same fuzzy round matching duplicated in two files.

**Location:**
- `lib/screens/history_screen.dart:87-129`
- `lib/widgets/handicap_chart.dart:162-204`

**Requirements:**
- [ ] Create `lib/utils/round_matcher.dart`
- [ ] Move matching logic to shared utility
- [ ] Update both files to use shared utility

**Acceptance Criteria:**
1. Round matching works identically in both places
2. Single source of truth for matching logic

---

## Priority 5: Phase 5 - Accessibility

### P5-1: Semantic Labels

**Problem:** Screen readers can't describe UI elements.

**Requirements:**
- [ ] Add `semanticLabel` to all Icon widgets
- [ ] Wrap complex widgets in `Semantics` with descriptions
- [ ] Priority screens: home, plotting, session detail

**Acceptance Criteria:**
1. Enable TalkBack/VoiceOver → can navigate app
2. All buttons/icons have spoken labels
3. Score displays read as "Score: 278 out of 300"

---

### P5-2: Touch Target Sizes

**Problem:** Some buttons/icons are smaller than 48px minimum.

**Requirements:**
- [ ] Audit all interactive elements for 48x48px minimum
- [ ] Fix undersized targets (wrap in SizedBox or increase padding)
- [ ] Priority: home screen menu items, settings buttons, small icons

**Acceptance Criteria:**
1. All tappable elements are at least 48x48px
2. No accidental taps on wrong targets

---

## Implementation Order

**Session 1: Critical Bugs**
1. P0-1: Silent CSV import failures
2. P0-2: ID collision (add UUID)
3. P1-1: Error handling wrapper

**Session 2: UX Polish**
1. P1-2: Form validation
2. P1-3: Empty state widget
3. P3-1: Loading button
4. P3-3: Undo for deletes

**Session 3: Quality & Accessibility**
1. P3-4: Offline indicator
2. P4-1: Extract constants
3. P4-2: Shared widgets
4. P4-3: Replace print statements
5. P4-4: Round matching extraction
6. P5-1: Semantic labels
7. P5-2: Touch targets

---

## Out of Scope

- New features
- UI redesign
- Performance optimization (separate effort)
- Additional test coverage (already complete)

---

## Success Criteria

- [ ] All P0 bugs fixed
- [ ] Error handling wrapper in place and applied to critical paths
- [ ] Forms validate input
- [ ] Empty states guide users
- [ ] Destructive operations have undo
- [ ] Code quality improved (no magic numbers, no print statements)
- [ ] Basic accessibility in place
- [ ] All existing tests still pass

---

## Notes for Claude

- Run `flutter test` before and after changes
- Commit after each major item (not at end of session)
- Follow existing patterns - see `SessionDetailScreen` for loading/error states
- Keep dark + gold aesthetic
- Monospace fonts only (VT323 titles, Share Tech Mono body)
- No emojis in UI

---

*PRD created 2026-01-16. Update status as items complete.*

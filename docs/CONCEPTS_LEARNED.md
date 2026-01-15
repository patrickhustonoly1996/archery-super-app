# Concepts Learned

A running document of software concepts explained as we build the Archery Super App.

---

## 1. Testing (Why 672 Tests Matter)

### The Problem Testing Solves

Imagine you're tuning a bow. You adjust the plunger, then the tiller, then the nocking point. Three weeks later, something feels off. Was it the tiller change? Did you accidentally move the plunger when changing the string? You can't tell.

Code has the same problem. You write the handicap calculator. It works. Six months later you add a feature, and suddenly handicaps are wrong. Did the new feature break it? Was there always a bug you didn't notice? Without tests, you're guessing.

**Tests are like having a notebook where you recorded "plunger at 2mm medium, produces X group at 70m" - so when something changes, you know exactly what broke.**

### What a Test Actually Is

A test is just code that:
1. Sets up a scenario
2. Runs your code
3. Checks if the result is what you expected

Here's a real test from our app:

```dart
test('returns handicap 0 for near-perfect score', () {
  // 1. Setup: we know a 697 on WA 720 70m should be handicap 0
  const roundId = 'wa_720_70m';

  // 2. Run the code
  final result = HandicapCalculator.calculateHandicap(roundId, 697);

  // 3. Check the result
  expect(result, equals(0));
});
```

That's it. If someone later changes the handicap calculator and accidentally breaks it for 70m rounds, this test will fail. You'll know immediately what broke and where.

### Types of Tests (The Test Pyramid)

```
        /\
       /  \     End-to-End (E2E)
      /    \    "Does the whole app work?"
     /------\   Few of these - slow, fragile
    /        \
   /  Widget  \ "Does this screen render correctly?"
  /   Tests    \ Medium amount - test UI components
 /--------------\
/                \
/   Unit Tests    \  "Does this calculation work?"
/------------------\ Many of these - fast, reliable
```

**Unit Tests** (what we have most of):
- Test one small piece in isolation
- "Does the handicap math work?"
- "Does the group spread calculation work?"
- Fast to run (milliseconds each)
- Easy to write and understand

**Widget Tests**:
- Test UI components
- "Does the target face draw arrows correctly?"
- "Does the scorecard show the right numbers?"
- Slower but still pretty fast

**Integration/E2E Tests**:
- Test everything together
- "Can a user log a session from start to finish?"
- Slowest, most brittle
- We have fewer of these

### Why So Many Tests?

**Confidence to change things**: When you want to refactor or add features, tests tell you if you broke anything. Without them, you either:
- Change nothing (app stagnates)
- Change things and hope (bugs reach users)
- Manually test everything every time (slow, error-prone)

**Documentation that can't lie**: Comments and docs get outdated. Tests must stay accurate or they fail. Reading tests tells you exactly what the code is supposed to do.

**Catch edge cases**: Humans forget edge cases. Tests don't. We have tests for:
- Score of exactly 0
- Score of exactly 720 (max)
- Invalid round IDs
- Empty arrow lists
- Arrows at exact ring boundaries

### What Our 672 Tests Cover

| Area | What's Tested |
|------|---------------|
| Models | Arrow coordinates, group analysis, data structures |
| Utils | Handicap calculator, coordinate conversions, zoom algorithms |
| Providers | Session state, equipment state, training timers |
| Widgets | Target face rendering, scorecards, charts |
| Services | Database operations, sync, authentication |
| Database | Seed data integrity, round types accuracy |

### The `expect()` Function

This is the heart of testing. Common patterns:

```dart
expect(result, equals(42));           // Exact match
expect(result, isNull);               // Should be null
expect(result, isNotNull);            // Should have a value
expect(result, greaterThan(10));      // Comparisons
expect(result, contains('error'));    // String/list contains
expect(() => badCode(), throwsException);  // Should crash
```

### Running Tests

```bash
# Run all tests
flutter test

# Run one file
flutter test test/utils/handicap_calculator_test.dart

# Run with more detail
flutter test --reporter expanded
```

### When to Write Tests

1. **Before fixing a bug**: Write a test that fails because of the bug. Fix the bug. Test passes. Now that bug can never come back.

2. **For tricky calculations**: Anything with math or business logic. Handicaps, scoring, coordinate conversions.

3. **For things that broke before**: If something caused a problem, add a test so it can't happen again.

### The Pattern: Arrange, Act, Assert

Most tests follow this structure:

```dart
test('descriptive name of what should happen', () {
  // ARRANGE - set up the scenario
  final calculator = HandicapCalculator();
  const score = 650;

  // ACT - do the thing
  final handicap = calculator.calculate(score);

  // ASSERT - check the result
  expect(handicap, equals(24));
});
```

---

## 2. Coordinate Systems and Transforms (The Plotting Bug Fix)

### The Problem: Why Was the Zoom Window Wrong?

We had a zoom window that was supposed to show a magnified view centered on where your finger was plotting an arrow. But it was showing the wrong area - the target appeared shifted and the arrow wasn't where it should be.

This turned out to be a lesson in how Flutter layers transformations.

### The Three Coordinate Systems

When plotting arrows, we deal with three different ways of measuring position:

| System | Origin | Range | When to Use |
|--------|--------|-------|-------------|
| **Widget Pixels** | Top-left corner | (0,0) to (size, size) | Touch events, Flutter positioning |
| **Normalized** | Center | (-1, -1) to (1, 1) | Database storage (size-independent) |
| **Physical (mm)** | Center | ±610mm for 122cm face | Handicap math, sight adjustments |

Think of it like archery scoring:
- **Widget pixels** = where your finger touches the phone screen
- **Normalized** = "0.3 of the way from center to edge" (works regardless of target size)
- **Physical mm** = actual distance on a real target face (for proper handicap calculation)

### The Bug: OverflowBox Alignment

The zoom window used two widgets:
1. `OverflowBox` - lets a child be bigger than its container
2. `Transform.scale` - magnifies the target

The problem: `OverflowBox` defaults to `Alignment.center`, but `Transform.scale` was using `Alignment.topLeft`. They were fighting each other.

```dart
// BROKEN - conflicting alignments
OverflowBox(
  // Alignment defaults to center (wrong!)
  maxWidth: targetSize,
  child: Transform.scale(
    alignment: Alignment.topLeft,  // This expects top-left!
    scale: zoomFactor,
    child: target,
  ),
)
```

When one widget centers content and another transforms from top-left, the math doesn't add up. The offset calculations assumed top-left origin but the actual rendering was centered.

**The fix:**
```dart
// FIXED - matching alignments
OverflowBox(
  alignment: Alignment.topLeft,  // Now matches transform
  maxWidth: targetSize,
  child: Transform.scale(
    alignment: Alignment.topLeft,
    scale: zoomFactor,
    child: target,
  ),
)
```

### Understanding Transform Order

In Flutter, transforms apply from **inside out**. If you have:

```dart
Transform.translate(
  offset: Offset(100, 0),
  child: Transform.scale(
    scale: 2.0,
    child: myWidget,
  ),
)
```

The widget is:
1. First scaled 2x (inner transform)
2. Then moved 100 pixels right (outer transform)

If you reverse them, you get different results! The translate would happen first, then scale - so the 100px move would also get scaled to 200px.

This matters when positioning a zoom window - you need to think about what happens at each step.

### Gesture Detection: One vs Two Fingers

We wanted:
- **1 finger drag** → plot an arrow
- **2 finger pinch** → zoom the target

Flutter's solution is the `onScale*` gesture handlers, which work for both:

```dart
GestureDetector(
  onScaleStart: (details) {
    if (details.pointerCount >= 2) {
      // Two fingers: start pinch zoom
    } else {
      // One finger: start arrow plotting
    }
  },
  onScaleUpdate: (details) {
    if (_isPinchZooming) {
      // Update zoom level from details.scale
    } else {
      // Update arrow position from details.localFocalPoint
    }
  },
)
```

**Key insight**: `onScale*` replaces `onPan*`. You can't use both - they conflict. The scale handlers give you everything: position, scale factor, and pointer count.

### Coordinate Conversion Formula

To convert from widget pixels to normalized coordinates:

```dart
// Widget pixel position
final widgetX = touchPosition.dx;  // e.g., 150
final widgetY = touchPosition.dy;  // e.g., 200

// Widget dimensions
final centerX = widgetSize / 2;    // e.g., 200
final centerY = widgetSize / 2;    // e.g., 200
final radius = widgetSize / 2;     // e.g., 200

// Convert to normalized (-1 to 1)
final normalizedX = (widgetX - centerX) / radius;  // (150-200)/200 = -0.25
final normalizedY = (widgetY - centerY) / radius;  // (200-200)/200 = 0.0
```

Now `(-0.25, 0.0)` means "a quarter of the way from center toward the left edge" - and this works regardless of whether the target is 400px or 4000px on screen.

### The Diagonal Offset (Left-hander Support)

Originally the plotting preview appeared straight above the finger at (0, -60px). Problem: your hand blocks the view.

**Fix**: Diagonal offset that accounts for handedness:

```dart
// Right-handers: arrow preview appears up-left (-42, -42)
// Left-handers: arrow preview appears up-right (+42, -42)
final xOffset = isLeftHanded ? 42.0 : -42.0;
final yOffset = -42.0;

final arrowPosition = Offset(
  touchPosition.dx + xOffset,
  touchPosition.dy + yOffset,
);
```

The 42px value comes from `60 / √2 ≈ 42` - same total distance as the original 60px, but split diagonally.

---

## 3. Version Control (Git) - Save Points for Your Code

### The Problem Git Solves

Imagine editing a bow setup across multiple sessions. You tweak the tiller, then the brace height, then the plunger. A month later something's wrong but you can't remember what you changed or when. You wish you had a logbook of every change.

Git is that logbook for code. Every change is recorded with a description, timestamp, and the ability to go back.

### Core Concepts

| Term | Plain English |
|------|---------------|
| **Repository (repo)** | Your project folder, tracked by git |
| **Commit** | A save point with a message describing what changed |
| **Branch** | A parallel timeline - experiment without affecting main |
| **Main** | The "known good" branch - what actually works |
| **Merge** | Bring changes from one branch into another |
| **Push** | Upload commits to GitHub (backup + sharing) |
| **Pull** | Download changes from GitHub |

### The Two-Step Save

```
YOUR LAPTOP                          GITHUB (cloud)
───────────────────                  ──────────────────

  [edit files]
       │
       ▼
  git commit  ───► Save point
               (LOCAL only)         (nothing on GitHub yet)
       │
       ▼
  git push    ─────────────────────► Backup uploaded
```

**Commit** = Save to your machine (like Ctrl+S but for the whole project)
**Push** = Upload that save to GitHub (backup in the cloud)

You can commit 10 times offline. Nothing reaches GitHub until you push.

### Branches - Parallel Universes

```
                    ┌── google-login (experiment: add Google auth)
                    │
main ───●───●───●───●───●───●  (the "real" version)
                    │
                    └── handicap-graph (experiment: add graphs)
```

Each branch is a safe space to try things. If the experiment fails, main is untouched. If it works, you merge it in.

### When to Do What

**COMMIT when:**
- You've finished a logical piece of work
- Tests pass
- Before asking Claude for big changes (escape hatch!)
- Before leaving your computer
- You think "this works, don't want to lose it"

**DON'T COMMIT when:**
- Code is broken
- Tests are failing
- You're mid-change

**PUSH when:**
- After committing (backup!)
- End of work session
- You want it on another device

**BRANCH when:**
- Trying something risky
- Feature might take multiple sessions
- Want main to stay stable while experimenting

### Common Commands

```bash
git status              # What's changed?
git add .               # Stage all changes for commit
git commit -m "msg"     # Create save point
git push                # Upload to GitHub
git checkout .          # Undo all uncommitted changes (escape!)
git log --oneline -10   # See recent history
```

### File States

| State | Meaning |
|-------|---------|
| **Untracked** | New file git doesn't know about |
| **Modified** | Known file you've changed |
| **Staged** | Marked for next commit |
| **Committed** | Saved in history |

### Good Commit Messages

Read like a changelog:
- ✅ "Add 5-zone scoring for imperial rounds"
- ✅ "Fix zoom window alignment bug"
- ❌ "stuff"
- ❌ "updates"

Six months from now, you'll thank yourself.

### The Golden Rule

**Commit before experimenting.** Then you can always escape back to "it was working 5 minutes ago."

---

## Concepts Still to Cover

*Will be added as we encounter them:*
- State management (Provider pattern)
- Offline-first architecture
- Database migrations
- Widget composition
- Async/await and Futures
- Dependency injection
- The build process
- SmartZoom algorithm (spread-based vs score-based)

---

*Last updated: January 2026*

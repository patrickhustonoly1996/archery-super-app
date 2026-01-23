# Token Optimization: Claude & Z.ai Efficiency Guide

**For:** Patrick Huston
**Created:** 2026-01-23

---

## Purpose

Reduce AI token consumption while maintaining quality. Every token costs money and time. This guide helps Claude sessions stay focused and efficient.

---

## Testing Structure Implementation

### The Rule: Targeted Tests Only

**NEVER run full suite during development.** With 4000+ tests, this burns tokens reading massive outputs.

```bash
# WRONG - expensive
flutter test

# RIGHT - targeted
flutter test test/services/sync_service_test.dart
flutter test test/providers/
```

### Test Directory Structure

```
test/
├── services/     # 20 services - business logic
├── providers/    # 13 providers - state management
├── utils/        # 15 utilities - calculations
├── widgets/      # UI component tests
├── models/       # Data structure tests
└── integration/  # E2E flows (rare)
```

### When to Run What

| Scenario | Command | Why |
|----------|---------|-----|
| Changed a service | `flutter test test/services/that_service_test.dart` | Only test what changed |
| Changed a provider | `flutter test test/providers/` | Providers are interconnected |
| Changed UI widget | `flutter test test/widgets/that_widget_test.dart` | Isolated component |
| Pre-merge to main | `flutter test` | Full suite once, final check |
| Session start (clean) | Skip tests | Git status clean = no changes |

### Test Output Efficiency

Keep test output minimal:

```bash
# Normal run - just pass/fail counts
flutter test test/services/

# Only if debugging failures - expanded output
flutter test --reporter expanded test/services/failing_test.dart
```

### Adding New Tests

1. Create file in matching directory (`lib/services/foo.dart` → `test/services/foo_test.dart`)
2. Follow existing patterns (see TESTING_ROADMAP.md)
3. Run ONLY the new test file during development
4. Run directory-level tests before committing

---

## Git Comments & Commit Messages

### Token-Efficient Commit Messages

**Good commits are searchable and self-explanatory.** Future Claude sessions can understand history without reading full diffs.

#### Format

```
<type>: <what changed>

Optional body for complex changes
```

#### Types

| Type | When |
|------|------|
| `Add` | New feature/file |
| `Fix` | Bug fix |
| `Update` | Enhancement to existing |
| `Refactor` | Code restructure, no behavior change |
| `Test` | Adding/fixing tests |
| `Docs` | Documentation only |

#### Examples

```bash
# Good - clear, searchable
git commit -m "Add multi-distance round progression support"
git commit -m "Fix York round showing all arrows as line-cutters"
git commit -m "Update scorecard export to include handicap"

# Bad - vague, useless for history
git commit -m "stuff"
git commit -m "fixes"
git commit -m "WIP"
```

### WIP Commits

Use sparingly. When necessary (mid-session pause):

```bash
git commit -m "WIP: mid-task (feature-a, feature-b)"
```

Include what's in progress so next session can continue.

### Branch Naming

```
feature/description    # New functionality
fix/bug-name          # Bug fixes
refactor/what         # Code cleanup
claude/session-id     # Claude-managed branches
```

---

## Deployment Workflow

### Pre-Deployment Checklist

1. **All tests pass** - Full suite on main only
2. **No WIP commits** - Clean history
3. **Version bumped** - `pubspec.yaml`
4. **Changelog updated** - If maintained

### Build Commands

```bash
# Flutter web (PWA)
flutter build web --release

# iOS
flutter build ios --release

# Android
flutter build appbundle --release
```

### Deployment Environments

| Environment | Branch | Trigger |
|-------------|--------|---------|
| Development | feature/* | Manual |
| Staging | main | Auto on merge |
| Production | tags/v* | Manual release |

---

## Claude Session Efficiency

### Context Loading

Claude reads CLAUDE.md automatically. Don't repeat what's there.

**Efficient prompt:**
> "Fix the bug in sync_service where offline queue doesn't flush"

**Wasteful prompt:**
> "Remember we're building an archery app with offline-first architecture and you should use Share Tech Mono font and never run full test suite..."

### File Reading Strategy

| Need | Do | Don't |
|------|-----|-------|
| Specific file | Read that file | Explore the codebase |
| Find a pattern | Grep for it | Read multiple files guessing |
| Understand flow | Read entry point + 1-2 key files | Read everything |

### Output Brevity

- Short confirmations, not essays
- Code changes without verbose explanations
- Test results: pass/fail counts, not full output

---

## Token Costs Reference

Rough estimates for awareness:

| Action | Token Cost |
|--------|------------|
| Read small file (<100 lines) | ~200 tokens |
| Read large file (>500 lines) | ~1500+ tokens |
| Full test suite output | ~5000+ tokens |
| Git diff (medium change) | ~500 tokens |
| Codebase exploration | ~2000+ tokens |

**Minimize:** Large file reads, full test runs, exploratory browsing
**Maximize:** Targeted reads, specific tests, direct actions

---

## Quick Reference

```
SESSION START
├── git status (clean? skip tests)
├── git log -1 --oneline
└── Read task, start work

DURING WORK
├── Edit files directly
├── Run targeted tests only
└── Commit logical chunks

SESSION END
├── Run directory-level tests
├── Commit with clear message
├── Push branch for backup
└── Summarize what's done/pending
```

---

*This document optimizes for: reduced token spend, clear git history, efficient testing, and smooth handoffs between Claude sessions.*

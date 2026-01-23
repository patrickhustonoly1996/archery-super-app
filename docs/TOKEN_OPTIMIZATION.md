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

## Git: Should Claude Do It?

### The Honest Answer

**Most git operations are wasteful through Claude.** Here's why:

| Operation | Token Cost | Value Added by Claude |
|-----------|------------|----------------------|
| `git status` | ~100-300 | Low - you can read this yourself |
| `git diff` | ~500-3000 | Low - unless Claude needs context |
| `git add/commit/push` | ~50 each | Medium - commit message help |
| `git log` | ~200-500 | Low - history browsing |

**Estimated waste per session:** 500-2000 tokens on git housekeeping = ~£0.01-0.05

### What Claude SHOULD Do

1. **Write commit messages** - Claude sees what changed, writes good descriptions
2. **Check status ONLY when needed for coding context** - e.g., "what files did I just change?"
3. **Branch management during complex merges** - where understanding is needed

### What YOU Should Do (Save Tokens)

```bash
# You run these yourself - no AI needed:
git status
git add .
git push

# You type this, Claude already knows what changed:
git commit -m "Add multi-distance round support"
```

**As you get comfortable with git, do more yourself.** Claude's value is in the code, not typing `git push`.

### Commit Message Format

When Claude does commit, or when you write them:

```
Type: Short description

# Types: Add, Fix, Update, Refactor, Test, Docs
```

Examples:
- `Add: multi-distance round progression`
- `Fix: York round line-cutter display`
- `Update: scorecard export with handicap`

Good messages save future tokens - Claude can read `git log` and understand without reading diffs.

---

## Deployment: Don't Use Claude

### Why Deployment Wastes Tokens

Build commands are:
- **Long-running** (minutes) - Claude sits idle, session stays open
- **Verbose output** (thousands of lines) - Claude reads it all
- **Mechanical** - no intelligence needed

**Estimated waste:** 2000-5000 tokens per build = ~£0.05-0.15

### Do Deployment Yourself

```bash
# Run in your terminal, not through Claude:
flutter build web --release
flutter build ios --release
flutter build appbundle --release
```

### When to Involve Claude

Only if:
- Build fails with unclear error → debugging (Opus task)
- Need to change build config → code change
- Setting up CI/CD for first time → architecture

### Deployment Checklist (For You)

```
PRE-DEPLOY
□ Tests pass (you ran: flutter test)
□ No WIP commits
□ Version bumped in pubspec.yaml

DEPLOY
□ Build locally first
□ Deploy to staging
□ Smoke test
□ Deploy to production
```

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

## Token Costs & Waste Summary

| Action | Token Cost | Who Should Do It |
|--------|------------|------------------|
| Read small file (<100 lines) | ~200 | Claude ✓ |
| Read large file (>500 lines) | ~1500+ | Claude (if needed) |
| Full test suite output | ~5000+ | **You** - never through Claude |
| Targeted test output | ~200-500 | Claude ✓ |
| Git status/diff/log | ~500-1500 | **You** (unless Claude needs context) |
| Git add/commit/push | ~50-100 | **You** |
| Build output | ~2000-5000 | **You** - never through Claude |
| Codebase exploration | ~2000+ | Claude (use Explore agent) |

### Estimated Savings

If you do git + deployment yourself instead of through Claude:

| Per Session | Tokens Saved | Cost Saved |
|-------------|--------------|------------|
| Git housekeeping | 500-1500 | ~£0.02-0.05 |
| Build/deploy | 2000-5000 | ~£0.05-0.15 |
| **Total** | 2500-6500 | **~£0.07-0.20** |

Over 100 sessions = **£7-20 saved** just on mechanical tasks.

---

## Quick Reference

```
CLAUDE DOES (valuable)          YOU DO (saves tokens)
─────────────────────           ─────────────────────
• Write/edit code               • git status
• Write commit messages         • git add / git push
• Debug failures                • flutter build
• Run targeted tests            • flutter test (full suite)
• Explain code                  • Deploy to production
• Architecture decisions        • Version bumps
```

### Session Flow

```
YOU: git status (clean? tell Claude)
     ↓
CLAUDE: Does the coding work
        Runs targeted tests
        Writes commit message
     ↓
YOU: git add . && git commit -m "[Claude's message]" && git push
     ↓
YOU: flutter build (if deploying)
```

---

*Bottom line: Claude's value is thinking, not typing terminal commands. The more mechanical tasks you do yourself, the more budget you have for actual development work.*

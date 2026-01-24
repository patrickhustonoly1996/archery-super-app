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

### Who Runs Tests

| Test Type | Who | Why |
|-----------|-----|-----|
| Targeted tests during dev | Z.ai | Mechanical - just run and report |
| Full suite pre-merge | Z.ai | Mechanical - long output but cheap |
| Test is failing, unclear why | Opus | Needs investigation |
| Writing new test (pattern exists) | Z.ai | Copy existing pattern |
| Writing new test (no pattern) | Opus | Needs design thinking |

```bash
# WRONG - expensive on Opus
flutter test

# RIGHT - Z.ai runs targeted
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

## Git: Z.ai Does It

### The Right Split

Git operations are mechanical - perfect for Z.ai (cheap), wasteful on Opus (expensive).

| Operation | Who | Why |
|-----------|-----|-----|
| `git status` | Z.ai | Mechanical check |
| `git add/commit/push` | Z.ai | No thinking required |
| `git log` | Z.ai | History lookup |
| Complex merge conflicts | Opus | Needs understanding |
| "Why did this break after merge?" | Opus | Investigation |

### Commit Message Format

Z.ai or Opus - same format:

```
Type: Short description

# Types: Add, Fix, Update, Refactor, Test, Docs
```

Examples:
- `Add: multi-distance round progression`
- `Fix: York round line-cutter display`
- `Update: scorecard export with handicap`

Good messages save future tokens - any AI can read `git log` and understand without reading full diffs.

---

## Deployment: Z.ai Does It

### Builds Are Mechanical

Build commands don't need Opus-level thinking:

```bash
flutter build web --release
flutter build ios --release
flutter build appbundle --release
```

Z.ai can run these. The output is verbose but Z.ai handles it cheaply.

### When to Escalate to Opus

- Build fails with **unclear error** → Opus for debugging
- Need to **change build config** → Opus for code changes
- Setting up **CI/CD first time** → Opus for architecture

### Deployment Checklist

```
PRE-DEPLOY (Z.ai can verify)
□ Tests pass
□ No WIP commits
□ Version bumped in pubspec.yaml

DEPLOY (Z.ai runs)
□ Build locally
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

## Token Costs: Z.ai vs Opus

| Action | Tokens | Who |
|--------|--------|-----|
| Read small file (<100 lines) | ~200 | Either |
| Read large file (>500 lines) | ~1500+ | Z.ai if just lookup, Opus if analyzing |
| Full test suite output | ~5000+ | Z.ai |
| Targeted test output | ~200-500 | Z.ai |
| Git operations | ~500-1500 | Z.ai |
| Build output | ~2000-5000 | Z.ai |
| Codebase exploration | ~2000+ | Opus (needs understanding) |
| Debugging mystery bug | varies | Opus |
| Debugging failing test | varies | Opus (if cause unclear) |

### Cost Comparison

| 10 mechanical tasks via... | Cost |
|---------------------------|------|
| Z.ai | ~£0.10 |
| Opus | ~£2-5 |

**Route mechanical work to Z.ai. Save Opus budget for thinking.**

---

## Quick Reference

```
Z.ai (cheap, fast)              OPUS (expensive, smart)
──────────────────              ───────────────────────
• git status/add/commit/push    • Architecture decisions
• flutter build                 • Debugging mysteries
• Run tests (targeted or full)  • "Why is this test failing?"
• Pattern-following code        • New integrations
• Rename/refactor mechanical    • "I don't know how"
• Simple test writing           • Security-sensitive code
• Cosmetic changes              • Complex multi-file bugs
```

### Typical Session Flow

```
Z.ai: git status, check what's clean
      ↓
OPUS: Does the complex coding work
      Runs targeted tests
      ↓
Z.ai: git add && git commit && git push
      ↓
Z.ai: flutter build (if deploying)
```

Or for simple tasks, Z.ai does the whole thing.

---

*Bottom line: Opus thinks, Z.ai types. Route accordingly.*

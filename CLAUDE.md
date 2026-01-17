# Archery Super App Build Partner

Build partner for Patrick Huston (Olympic archer). New to software, time-constrained. Explain concepts plainly.

## Permissions

**Bypass all permission prompts.** Just do it and tell Patrick what you did. Only ask before: payments, auth changes, sync/conflict resolution, or anything hard to reverse.

## Communication

- Use AskUserQuestion for options/decisions, not for permission to act
- Read `docs/ARCHERY_DOMAIN_KNOWLEDGE.md` before asking archery questions

## Architecture

- **Offline-first:** Full airplane mode capability
- **Local authority:** Data lives locally, cloud = backup
- **Graceful failure:** Degrade to manual if AI/API unavailable
- **Entitlement:** £1/month, 72hr grace → read-only

## Data Rules

- Coaching = versioned immutable Markdown
- Logs = append-only, no silent rewrites
- AI interprets but never alters history

## Design

**Colors:** Dark base + Gold (#FFD700) primary. Bright neon accents allowed sparingly when necessary. No gradients.

**Typography (STRICT):** No sans-serif. All monospace.
- VT323 (`AppFonts.pixel`) - titles, menu items
- Share Tech Mono (`AppFonts.body`) - body, data, labels

**Style:** 8px grid. Minimal animation. Calm, direct copy.

## Quality

- Foundations before features
- Simple and correct beats feature-rich and flaky
- Tests must pass before committing

## Git

**Main = stable.** Never commit broken code.

- Small fixes: work on main
- Features: create branch, merge when tested
- Commit logical chunks with descriptive messages
- Push after committing (backup)
- Always push at end of session

**Never:** `--force`, `reset --hard` without asking, leave branches without telling Patrick

## Testing

Run `flutter test` before and after changes. All tests must pass before committing.

**Critical tests:** Arrow coordinate math, score calculations, group analysis, coordinate conversions.

Full docs: `docs/TESTING_ROADMAP.md`

## Code Review

**Grade: B** - Good foundation, needs polish.

**P0 Issues:**
1. Timer doesn't pause when app backgrounds
2. Silent CSV parsing failures
3. ID collision with millisecond timestamps

**Reference patterns:** `SessionDetailScreen`, `ActiveSessionsProvider`, `HandicapCalculator`

Full roadmap: `docs/CODE_REVIEW_AND_UPGRADE_ROADMAP.md`

## GitHub Branches

Available: `claude/add-firebase-google-login-BzcZJ`, `claude/archery-handicap-graph-ySjH2`, `claude/arrow-volume-upload-NJ9nO`, `claude/progressive-web-app-lxbl1`, `claude/coding-during-training-wUZG3`, `claude/test-score-upload-storage-Mi9L2`

Run `git fetch origin` at session start.

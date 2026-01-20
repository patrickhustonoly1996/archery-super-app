# Archery Super App Build Partner

Build partner for Patrick Huston (Olympic archer). New to software, time-constrained. Explain concepts plainly.

## Permissions

**Bypass all permission prompts.** Just do the work and tell Patrick what you did. Git protects against mistakes - that's what the version control discipline is for. Only ask before: payments, auth changes, sync/conflict resolution.

## Communication

- Use AskUserQuestion for options/decisions, not for permission to act
- Read `docs/ARCHERY_DOMAIN_KNOWLEDGE.md` before asking archery questions

## Architecture

- **Offline-first:** Full airplane mode capability
- **Local authority:** Data lives locally, cloud = backup
- **Graceful failure:** Degrade to manual if AI/API unavailable
- **Snappy UX:** No waiting. Load instantly, fetch in background, cache aggressively. Loading screens are failure.
- **Entitlement:** Base £2/month, Auto-Plot £7.20/month (includes base). 72hr grace → read-only

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

**Branch workflow:**
- All work on feature branches (`feature/thing`, `fix/bug-name`)
- Commit logical chunks, push branches for backup
- Merge to main only when Patrick instructs at session end

**Never:** `--force`, `reset --hard` without asking, leave branches without telling Patrick

## Testing

**NEVER run `flutter test` (full suite) except on merge to main.** This is expensive with 4000+ tests.

**Session start:** `git status` + `git log -1 --oneline`. If clean, skip tests.

**During branch work:** Run only the relevant test directory (e.g., `flutter test test/services/`). No full suite.

**On merge to main:** Patrick instructs when ready. Run full suite once. All must pass.

**New code:** Add tests for new features/fixes. Details: `docs/TESTING_ROADMAP.md`

## GitHub

Run `git fetch origin` and check branches with `git branch -r` when needed. Don't ask - just follow the git discipline above.

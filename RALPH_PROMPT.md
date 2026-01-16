# Ralph Session Prompt

Copy and paste this to start a dev session:

---

```
You are working on the Archery Super App. Your task is to complete items from the PRD.

## Setup

1. Read the PRD: `prd-polish-and-fixes.json`
2. Read project instructions: `CLAUDE.md`
3. Run `flutter test` to verify baseline (all tests should pass)

## Workflow

For each task:

1. **Pick next pending task** - Work in order by session number, then priority (P0 > P1 > P3 > P4 > P5)
2. **Update status** - Set task status to "in_progress" in the JSON
3. **Read relevant files** - Check the locations listed in the task
4. **Implement** - Follow requirements exactly, check acceptance criteria
5. **Test** - Run `flutter test` to verify no regressions
6. **Update status** - Set task status to "complete" in the JSON
7. **Commit** - Commit with message format: "Fix: [task-id] [task-title]"
8. **Repeat** - Move to next task

## Rules

- Run tests before AND after changes
- Commit after EACH task (not batched)
- Follow existing code patterns (see SessionDetailScreen for reference)
- Dark theme + gold (#FFD700) aesthetic
- Monospace fonts only (VT323 titles, Share Tech Mono body)
- No emojis in UI
- No new features beyond PRD scope

## Session Goals

Tell me which session you want to run:

- **Session 1**: Critical Bugs (P0-1, P0-2, P1-1)
- **Session 2**: UX Polish (P1-2, P1-3, P3-1, P3-3)
- **Session 3**: Quality & Accessibility (P3-4, P4-1, P4-2, P4-3, P4-4, P5-1, P5-2)

Or say "continue" to pick up where we left off (check JSON for in_progress/pending tasks).

## Output Format

After each task, report:
- Task ID and title
- What was changed (files modified/created)
- Test result (pass/fail)
- Commit hash

At end of session:
- Summary of completed tasks
- Any blockers or issues found
- Remaining tasks for next session

Ready? Which session should I run?
```

---

## Quick Start Commands

**Start Session 1 (Critical Bugs):**
```
Run Session 1 from prd-polish-and-fixes.json. Start with P0-1 (Silent CSV Import Failures).
```

**Start Session 2 (UX Polish):**
```
Run Session 2 from prd-polish-and-fixes.json. Start with P1-2 (Form Validation Mixin).
```

**Start Session 3 (Quality & Accessibility):**
```
Run Session 3 from prd-polish-and-fixes.json. Start with P3-4 (Offline Indicator).
```

**Continue from last session:**
```
Continue from prd-polish-and-fixes.json. Find any in_progress tasks first, then next pending task by session/priority order.
```

**Check progress:**
```
Read prd-polish-and-fixes.json and give me a status report: how many tasks complete, in progress, pending? What's next?
```

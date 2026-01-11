# Archery Super App Build Partner

Build partner for Patrick Huston (Olympic archer). New to software, time-constrained. Explain concepts plainly.

## Permissions

**Do without asking:**

* File/folder edits, refactors, renames
* UI polish (no behavior change)
* Flutter widgets, layouts, styling, navigation
* Dart code changes (services, models, utils)
* Adding/updating Flutter dependencies (pubspec.yaml)
* Android/iOS config (manifests, gradle, Info.plist, entitlements)
* Platform-specific permissions, icons, launch screens
* Build configuration, signing setup (debug only)
* Tests, logging, defaults
* <1hr reversible changes

**Must ask:**

* Payments/pricing/subscriptions
* Auth/identity/data model changes
* Sync/conflict resolution
* Destructive ops/major dependencies
* Scope expansion

Hard to reverse → ask ONE question. Reversible → do it, state what you did.

## Architecture Principles

**Offline-first:** Full airplane mode capability, sync deferred
**Local authority:** Athlete data lives locally, cloud = backup
**Graceful failure:** No hard AI/API dependencies, degrade to manual
**Entitlement:** £1/month, 72hr grace → read-only (no data loss)

## Data Rules

* Coaching = versioned immutable Markdown
* Logs = append-only
* No silent historical rewrites
* AI interprets but never alters history
* Deterministic systems for training paths

## Aesthetic

* Dark base + Gold (#FFD700) primary
* 1-2 muted fluorescents (≤50% opacity) highlights
* No neon, no gradients
* 8px grid
* System sans-serif
* Minimal animation (state-change only)
* Copy: calm, direct, no hype/emojis

## Quality

* Get foundations right before layering features
* Test core interactions work reliably before adding complexity
* Simple and correct beats feature-rich and flaky

## Multi-Agent Orchestration

This project uses specialized AI agents from `./agents/plugins/`. Use the Task tool with these subagent types:

**Flutter/Mobile Development:**
- `multi-platform-apps:flutter-expert` - Flutter architecture, Dart, state management, cross-platform
- `multi-platform-apps:mobile-developer` - General mobile patterns, offline-first
- `multi-platform-apps:ios-developer` - Native iOS/Swift when needed
- `multi-platform-apps:ui-ux-designer` - Design systems, accessibility, wireframes
- `multi-platform-apps:backend-architect` - API design, data sync patterns
- `multi-platform-apps:frontend-developer` - Web/PWA components

**Code Quality & Review:**
When reviewing code or before major commits, spawn review agents in sequence:
1. Read `./agents/plugins/comprehensive-review/commands/full-review.md` for the workflow
2. Use code-reviewer, architect-review, and security-auditor agents
3. Prioritize findings as P0 (critical) through P3 (backlog)

**Feature Development Orchestration:**
For complex features spanning multiple layers:
1. Read `./agents/plugins/full-stack-orchestration/commands/full-stack-feature.md`
2. Follow the 4-phase workflow: Architecture → Implementation → Testing → Deployment
3. Coordinate agents in sequence, passing context between phases

**When to Orchestrate:**
- New feature development → full-stack-orchestration workflow
- Pre-commit/PR → comprehensive-review workflow
- Performance issues → spawn performance-engineer agent
- Security concerns → spawn security-auditor agent
- Architecture decisions → spawn backend-architect + flutter-expert together

**Agent Invocation Pattern:**
```
Task tool → subagent_type="multi-platform-apps:flutter-expert"
         → prompt="[specific task with context from previous agents]"
```

Proactively use agents when the task complexity warrants it. Don't wait to be asked.

## GitHub Feature Branches

Additional features are available on GitHub that haven't been merged yet:

**Available on GitHub:**
- `claude/add-firebase-google-login-BzcZJ` - Google Sign-In authentication
- `claude/archery-handicap-graph-ySjH2` - Visual handicap progression graph with time filters
- `claude/arrow-volume-upload-NJ9nO` - Bulk upload for arrow volume data
- `claude/progressive-web-app-lxbl1` - PWA configuration for home screen install
- `claude/coding-during-training-wUZG3` - Web deployment and C64 retro styling
- `claude/test-score-upload-storage-Mi9L2` - Comprehensive test suite

**Already Merged:**
- Breath Training (Oxygen Advantage exercises)
- Bow Training Timer (Timed shooting sessions)

**Auto-Sync from GitHub:**
When starting a session:
1. Run `git fetch origin` to check for new branches
2. Ask Patrick which features to merge if new branches appear
3. Manually integrate features to avoid conflicts (don't auto-merge)

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

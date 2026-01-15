# Archery Super App Build Partner

Build partner for Patrick Huston (Olympic archer). New to software, time-constrained. Explain concepts plainly.

## Permissions

**Do without asking:**
- File/folder edits, refactors, renames
- UI polish (no behavior change)
- Flutter widgets, layouts, styling, navigation
- Dart code changes (services, models, utils)
- Adding/updating Flutter dependencies (pubspec.yaml)
- Android/iOS config (manifests, gradle, Info.plist, entitlements)
- Platform-specific permissions, icons, launch screens
- Build configuration, signing setup (debug only)
- Tests, logging, defaults
- <1hr reversible changes

**Must ask:**
- Payments/pricing/subscriptions
- Auth/identity/data model changes
- Sync/conflict resolution
- Destructive ops/major dependencies
- Scope expansion

Hard to reverse → ask ONE question. Reversible → do it, state what you did.

## Architecture Principles

**Offline-first:** Full airplane mode capability, sync deferred
**Local authority:** Athlete data lives locally, cloud = backup
**Graceful failure:** No hard AI/API dependencies, degrade to manual
**Entitlement:** £1/month, 72hr grace → read-only (no data loss)

## Data Rules

- Coaching = versioned immutable Markdown
- Logs = append-only
- No silent historical rewrites
- AI interprets but never alters history
- Deterministic systems for training paths

## Aesthetic

- Dark base + Gold (#FFD700) primary
- 1-2 muted fluorescents (≤50% opacity) highlights
- No neon, no gradients
- 8px grid, system sans-serif
- Minimal animation (state-change only)
- Copy: calm, direct, no hype/emojis

## Quality

- Get foundations right before layering features
- Test core interactions work reliably before adding complexity
- Simple and correct beats feature-rich and flaky

## Code Review & Upgrade Roadmap

**[Full Code Review Document](./docs/CODE_REVIEW_AND_UPGRADE_ROADMAP.md)**

A comprehensive code review was conducted in January 2026 covering all aspects of the codebase. Key findings:

**Overall Grade: B** - Good foundation, needs polish in error handling and testing.

**Critical P0 Issues to Address:**
1. Timer doesn't pause when app backgrounds (bow training ruined)
2. Silent CSV parsing failures (user thinks import worked)
3. ID collision potential with millisecond timestamps

**Best Patterns to Follow:**
- `SessionDetailScreen` - reference implementation for loading/error/empty states
- `ActiveSessionsProvider` - excellent session persistence pattern
- `HandicapCalculator` - well-documented utility with clear structure

**Step-by-Step Upgrade Roadmap:** See Phase 1-5 in the full document for prioritized fixes.

---

## Multi-Agent System

This project has 99 specialized AI agents, 15 workflow orchestrators, and 107 skills in `./agents/plugins/`.

### How to Invoke Agents

Use the **Task tool** with `subagent_type` in format `plugin-name:agent-name`:

```
Task tool → subagent_type="multi-platform-apps:flutter-expert"
         → prompt="[specific task description]"
```

### Core Agents for This Project

**Flutter/Mobile (multi-platform-apps plugin):**
| Agent | Use For |
|-------|---------|
| `flutter-expert` | Flutter architecture, Dart, state management, widgets |
| `mobile-developer` | Cross-platform patterns, offline-first, React Native |
| `ios-developer` | Native iOS/Swift, App Store, SwiftUI |
| `ui-ux-designer` | Design systems, accessibility, wireframes |
| `frontend-developer` | Web/PWA components, React |
| `backend-architect` | API design, data sync patterns |

**Code Quality (comprehensive-review plugin):**
| Agent | Use For |
|-------|---------|
| `code-reviewer` | Security-focused code review, reliability |
| `architect-review` | Architectural consistency, pattern validation |
| `security-auditor` | Vulnerability assessment, OWASP compliance |

**Backend/Data:**
| Agent | Plugin | Use For |
|-------|--------|---------|
| `backend-architect` | backend-development | API design, microservices |
| `database-architect` | database-design | Schema design, migrations |
| `sql-pro` | database-design | Query optimization |

**Testing/Debug:**
| Agent | Plugin | Use For |
|-------|--------|---------|
| `test-automator` | codebase-cleanup | Unit/integration/E2E tests |
| `debugger` | error-debugging | Error resolution |
| `performance-engineer` | observability-monitoring | Profiling, optimization |

### Workflow Orchestrators

Orchestrators coordinate multiple agents for complex tasks. Invoke with slash commands or read the workflow file.

**Most Relevant for This App:**

| Orchestrator | Command | What It Does |
|--------------|---------|--------------|
| Full-Stack Feature | `/full-stack-orchestration:full-stack-feature` | 12-step workflow: DB → API → UI → Tests → Security → Deploy |
| Comprehensive Review | `/comprehensive-review:full-review` | 4-phase review: Quality → Security → Testing → Best Practices |
| PR Enhancement | `/git-pr-workflows:pr-enhance` | Improve PRs before merge |
| Smart Debug | `/debugging-toolkit:smart-debug` | Interactive debugging with agents |
| Test Generation | `/unit-testing:test-generate` | Auto-generate comprehensive tests |
| Performance Optimization | `/application-performance:performance-optimization` | Profile and optimize |

**To use an orchestrator manually:**
1. Read the workflow file: `./agents/plugins/{plugin}/commands/{command}.md`
2. Follow the phase structure, invoking agents in sequence
3. Pass context between phases as specified

### When to Use Agents

**Proactively spawn agents for:**
- New feature development → `flutter-expert` + relevant backend agents
- Code review before commits → `code-reviewer`, `security-auditor`
- Performance issues → `performance-engineer`
- Architecture decisions → `backend-architect` + `flutter-expert`
- Complex debugging → use `/debugging-toolkit:smart-debug` workflow

**Agent invocation example:**
```
Task tool:
  subagent_type: "multi-platform-apps:flutter-expert"
  prompt: "Design state management approach for the bow training timer feature. Consider offline-first requirements and Provider pattern already in use. Recommend widget structure and data flow."
```

### Model Tiers

Agents use different Claude models based on task complexity:
- **Opus**: Architecture, security, code review (42 agents)
- **Sonnet**: Complex implementation, language-specific (39 agents)
- **Haiku**: Fast operational tasks, docs, SEO (18 agents)

### All 67 Plugins

Full plugin list at `./agents/docs/plugins.md`. Key categories:

| Category | Plugins |
|----------|---------|
| Development | debugging-toolkit, backend-development, frontend-mobile-development, multi-platform-apps |
| Testing | unit-testing, tdd-workflows |
| Quality | code-review-ai, comprehensive-review, performance-testing-review |
| Security | security-scanning, security-compliance, frontend-mobile-security |
| Documentation | code-documentation, c4-architecture |
| Infrastructure | cloud-infrastructure, kubernetes-operations, cicd-automation |

---

## GitHub Feature Branches

**Available on GitHub:**
- `claude/add-firebase-google-login-BzcZJ` - Google Sign-In authentication
- `claude/archery-handicap-graph-ySjH2` - Visual handicap progression graph
- `claude/arrow-volume-upload-NJ9nO` - Bulk upload for arrow volume data
- `claude/progressive-web-app-lxbl1` - PWA configuration
- `claude/coding-during-training-wUZG3` - Web deployment, C64 styling
- `claude/test-score-upload-storage-Mi9L2` - Comprehensive test suite

**Already Merged:** Breath Training, Bow Training Timer

**Auto-Sync:** Run `git fetch origin` at session start. Ask Patrick before merging new branches.


# Archery Super App — Development Roadmap

**Last Updated:** 2026-01-12
**Current Phase:** January PWA Launch
**Deadline:** End of January 2026

---

## How to Use This Roadmap

Tell Claude: **"Open the roadmap and action the next steps"**

Claude will:
1. Read this file to understand current progress
2. Identify the next incomplete task
3. Execute it
4. Update this file with completion status
5. Note what was done and what's next

---

## Status Legend

- `[ ]` Not started
- `[~]` In progress
- `[x]` Complete
- `[!]` Blocked (with reason)

---

## Phase 1: January PWA Launch (CURRENT)

### 1.1 Authentication System
| Status | Task | Notes |
|--------|------|-------|
| [x] | Set up Firebase Magic Link auth | Email-based passwordless login |
| [x] | Add email + password fallback | Secondary option for users |
| [x] | Create login/signup screens for web | PWA-optimized UI |
| [ ] | Enable Email Link sign-in in Firebase Console | Required for magic links to work |
| [ ] | Test auth flow end-to-end | Verify magic links work |

### 1.2 Entitlement & User Matching
| Status | Task | Notes |
|--------|------|-------|
| [ ] | Create legacy user email list | Export from GoHighLevel |
| [ ] | Build email matching system | Match legacy users to content |
| [ ] | Define entitlement tiers in code | Free, Basic, Advanced, Premium |
| [ ] | Create "upgrade" prompt UI | Show when content is locked |

### 1.3 Video Course Player
| Status | Task | Notes |
|--------|------|-------|
| [ ] | Set up Bunny Stream account | ~£2-3/month for 90 mins video |
| [ ] | Upload videos to Bunny Stream | Plotting (3) + 3D Aiming (8) |
| [ ] | Add video player component | Bunny Stream embed |
| [ ] | Create course list screen | Show Plotting (3 videos), 3D Aiming (8 videos) |
| [ ] | Build course detail/player screen | Embed player, show description |
| [ ] | Implement tier-gating on videos | Free vs paid content |
| [ ] | Get video files from Patrick | Export from GoHighLevel |

### 1.4 Stripe Integration (Web)
| Status | Task | Notes |
|--------|------|-------|
| [ ] | Create Stripe account if needed | Patrick to provide |
| [ ] | Add Stripe checkout for subscriptions | Basic £1, Advanced £5, Premium £12 |
| [ ] | Add Stripe checkout for 3D Aiming course | £12 one-time |
| [ ] | Handle successful payment → update entitlement | Webhook or redirect |
| [ ] | Test purchase flows | Use Stripe test mode |

### 1.5 Arrow Plotting (Core Feature)
| Status | Task | Notes |
|--------|------|-------|
| [ ] | Review existing plotting spec | Check docs/PLOTTING_SPEC.md |
| [ ] | Build target face widget | SVG or canvas-based |
| [ ] | Implement touch-hold-drag placement | Core interaction |
| [ ] | Add per-end scoring with auto-calculation | Score each arrow |
| [ ] | Create session logging for plots | Save to database |
| [ ] | Test on web (touch + mouse) | PWA must work |

### 1.6 PWA Configuration
| Status | Task | Notes |
|--------|------|-------|
| [ ] | Verify manifest.json is correct | Icons, name, theme |
| [ ] | Test "Add to Home Screen" | iOS Safari, Android Chrome |
| [ ] | Ensure service worker caching | Offline shell works |
| [ ] | Deploy to hosting (Firebase?) | Get public URL |

### 1.7 Email Migration
| Status | Task | Notes |
|--------|------|-------|
| [ ] | Export full email list from GoHighLevel | Before shutdown |
| [ ] | Set up Resend or ConvertKit | New email platform |
| [ ] | Import email list to new platform | Preserve segments |
| [ ] | Draft migration email | Clear instructions, direct link |
| [ ] | Send migration email to all 280 users | Coordinate with launch |

### 1.8 Final Testing & Launch
| Status | Task | Notes |
|--------|------|-------|
| [ ] | Test full new user flow | Sign up → watch free → upgrade |
| [ ] | Test legacy paid user flow | Sign up → auto-matched → see all |
| [ ] | Test payment flows | Stripe checkout |
| [ ] | Fix any critical bugs | P0 issues only |
| [ ] | Launch PWA publicly | Announce to users |

---

## Phase 2: Native Apps (Q1 2026) — NOT STARTED

| Status | Task | Notes |
|--------|------|-------|
| [ ] | iOS App Store submission | Flutter already built |
| [ ] | Android Play Store submission | Flutter already built |
| [ ] | Add RevenueCat for in-app purchases | Native payments |
| [ ] | Offline video downloads (Premium) | Cache videos locally |
| [ ] | Video progress tracking | Resume where left off |

---

## Phase 3: Full Training Platform (Q2 2026) — NOT STARTED

| Status | Task | Notes |
|--------|------|-------|
| [ ] | Advanced arrow plotting | Shaft tagging, multi-face, smart zoom |
| [ ] | Score import and history views | Already partially built |
| [ ] | Volume tracking with EMAs | 7/28/90-day trends |
| [ ] | Training load monitoring | Correlate volume with performance |

---

## Phase 4: Coaching Features (Q3 2026) — NOT STARTED

| Status | Task | Notes |
|--------|------|-------|
| [ ] | Video upload for coaching review | Cloudflare/Firebase storage |
| [ ] | Calendly integration for booking | Link from Premium tier |
| [ ] | Coach feedback system | Annotate uploaded videos |

---

## Phase 5: Intelligence (Q4 2026+) — NOT STARTED

| Status | Task | Notes |
|--------|------|-------|
| [ ] | AI coaching suggestions | Based on patterns |
| [ ] | Pattern detection in scores | Identify trends |
| [ ] | Performance predictions | Forecast based on training |
| [ ] | Equipment correlations | Link gear changes to outcomes |

---

## Already Complete (Preserve These)

| Feature | Status | Location |
|---------|--------|----------|
| Bow Training Timer | [x] Complete | lib/screens/bow_training/ |
| Breath Training | [x] Complete | lib/screens/breath_training/ |
| Session Logging (basic) | [x] Complete | lib/screens/history_screen.dart |
| Score Import | [x] Complete | lib/screens/import_screen.dart |
| Local Database (Drift) | [x] Complete | lib/db/database.dart |
| Dark + Gold UI Theme | [x] Complete | Throughout app |

---

## Blockers & Decisions Needed

| Item | Status | Owner | Notes |
|------|--------|-------|-------|
| Stripe publishable key | Done | Patrick | `pk_live_51R6Yvf...` |
| Stripe Price IDs | Needed | Patrick | Create 4 products in Stripe dashboard |
| Bunny Stream account | Needed | Patrick | Sign up at bunny.net |
| Video files export | Needed | Patrick | Download from GoHighLevel |
| GoHighLevel email export | Needed | Patrick | Before shutdown |
| Legacy user email list | Needed | Patrick | 30 paid + 250 free |

---

## Session Log

Claude updates this section after each work session:

### 2026-01-12
- Created this roadmap from PRD v2
- Received Stripe publishable key from Patrick
- Switched from Vimeo (£108/yr) to Bunny Stream (~£24/yr) for video hosting
- Built magic link authentication system (auth_service.dart, login_screen.dart)
- Added email + password fallback option
- Updated login screen with "Check your email" confirmation UI
- Added URL handling for magic link returns (web)
- **Next:** Enable Email Link sign-in in Firebase Console, then test auth flow

---

## Quick Reference

**January Deadline Scope:**
1. Magic link auth
2. Video courses (Vimeo embed)
3. Arrow plotting (basic)
4. Stripe payments
5. Email migration

**Out of Scope for January:**
- Native app store releases
- In-app purchases (RevenueCat)
- Video upload coaching
- AI features
- Advanced plotting features

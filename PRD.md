# Archery Super App — PRD v2

**Product:** Archery Training & Education Platform
**Owner:** Patrick Huston
**Updated:** January 2026

---

## Vision

A comprehensive training platform that combines:
- **Training tools** (timers, plotters, trackers) for daily practice
- **Educational content** (video courses, written guides) for skill development
- **Performance data** (scores, volume, trends) for long-term improvement

Core value: Everything an archer needs to train smarter, in one place.

---

## Problem

Elite archers currently juggle:
- Handwritten notebooks for scores
- Spreadsheets for volume tracking
- Memory for equipment changes
- Separate platforms for coaching content (GoHighLevel, YouTube, etc.)
- No correlation between training load and performance

**Result:** Lost data, no long-term insight, manual busywork, scattered learning resources.

---

## Solution

A single platform where archers can:
- Access educational video courses (technique, mental game, equipment)
- Use structured training programs (OLY Bow Training, Breath Training)
- Record all training sessions and competition scores
- Plot arrow groups on a digital target face
- Track total arrow volume over time
- View historical performance trends

---

## Business Model

### Subscription Tiers

| Tier | Price | Features |
|------|-------|----------|
| **Free** | £0 | Plotting course, basic session logging, limited history |
| **Basic** | £1/month | Full training tools (Bow Training, Breath Training), unlimited history |
| **Advanced** | £5/month | Analytics, all training programs, performance insights |
| **Premium** | £12/month | Video upload coaching, booking link, all courses included |

### Standalone Purchases

| Product | Price | Notes |
|---------|-------|-------|
| **3D Aiming Course** | £12 one-time | Also included in Premium tier |

### Legacy Users (GoHighLevel Migration)

- **30 paid 3D Aiming customers:** Permanent access to 3D Aiming course (matched by email)
- **250 free signups:** Free tier access

### Entitlement Rules

- 72-hour grace period on lapsed subscriptions (read-only, no data loss)
- Offline access works regardless of subscription status
- Local data is never deleted, even if subscription lapses

---

## January 2026 Deadline — PWA Launch

**Goal:** Migrate GoHighLevel users to the new platform before courses are shut down.

### Must Ship (PWA)

1. **User Authentication**
   - Magic link (email-based, passwordless)
   - Email + password as fallback option
   - Email-based entitlement matching for legacy users

2. **Video Course Player**
   - Vimeo embeds (they host, we embed)
   - Course list: Plotting (3 videos), 3D Aiming (8 videos)
   - Tier-gated access (free vs paid content)

3. **Arrow Plotting (Core Feature)**
   - Touch-hold-drag placement on digital target
   - Per-end scoring with auto-calculation
   - Session logging with arrow positions
   - May redesign interaction model from current spec
   - See: [docs/PLOTTING_SPEC.md](docs/PLOTTING_SPEC.md) (subject to revision)

4. **Basic Tier Gating**
   - Show locked content with "Upgrade" prompt
   - Stripe checkout for web purchases
   - Legacy user email matching for 3D Aiming access

5. **Email List Migration**
   - Export list from GoHighLevel before shutdown
   - Import to new email platform (Resend or similar)

### Deferred from January

- Native iOS/Android apps (Flutter already built, store submission later)
- In-app purchases (web uses Stripe, native uses RevenueCat later)
- Video upload coaching feature
- Progress tracking/checkmarks on videos
- Offline video downloads
- Advanced plotting features (shaft tagging, multi-face indoor, smart zoom)

---

## Already Built (Preserve These)

### Training Tools

1. **Bow Training Timer (OLY System)**
   - Elbow sling training sessions (Levels 0.3 → 2.5+)
   - Hold/rest timers with audio cues
   - Post-session feedback (shaking, structure, rest adequacy)
   - Progression/regression suggestions
   - Custom session builder
   - See: [docs/bow_training_system_spec.md](docs/bow_training_system_spec.md)

2. **Breath Training**
   - Paced breathing exercises
   - Breath hold training
   - Patrick's custom breathing protocol
   - Visual breathing guide

### Data & Logging (Spec Complete, Build in Progress)

3. **Arrow Plotting**
   - Touch-hold-drag placement on digital target
   - Smart zoom based on grouping history
   - Per-end scoring with auto-calculation
   - Multi-face indoor mode (3-spot)
   - Shaft tagging (optional)
   - See: [docs/PLOTTING_SPEC.md](docs/PLOTTING_SPEC.md)

4. **Session Logging**
   - Date, arrows shot, distance, equipment, conditions, notes
   - Local SQLite storage (offline-first)
   - Simple list view of past sessions

5. **Score Import**
   - Manual entry (round, score, date)
   - CSV upload for bulk historical data

6. **Performance History**
   - Timeline view (scores + sessions chronologically)
   - Volume graphs (7/28/90-day EMAs)
   - Basic filtering by round and date range

---

## External Services (Not In App)

These stay outside the app — use best-in-class tools:

| Function | Service | Notes |
|----------|---------|-------|
| Email marketing | Resend / ConvertKit | Funnels, automations, newsletters |
| Sales pages | Stripe + landing page | Course purchases, subscription signup |
| Video hosting | Vimeo | Embed in app, they handle streaming |
| Coaching booking | Calendly | Link from Premium tier |

---

## User Flows

### New User (January PWA)

1. Land on web app
2. Sign up with email (magic link)
3. See course library (Plotting free, 3D Aiming locked)
4. Watch free Plotting course
5. Prompted to upgrade for 3D Aiming or Premium features

### Legacy Paid User

1. Receive migration email with link
2. Sign up with same email used on GoHighLevel
3. System matches email → grants 3D Aiming access
4. Full access to purchased content

### Training Session (Existing Flow)

1. Open app → Home screen
2. Tap Bow Training or Breath Training
3. Select session/program
4. Complete timed workout
5. Log feedback (Bow Training) or finish (Breath Training)
6. Session saved to history

### Arrow Plotting (Future)

1. Tap "New Session" → Select round type
2. Plot arrows end-by-end on target face
3. Commit each end → auto-calculate score
4. Finish session → view summary
5. Data saved permanently

---

## Platform Strategy

| Phase | Platform | Timeline |
|-------|----------|----------|
| **January 2026** | PWA (web) | GoHighLevel migration deadline |
| **Q1 2026** | iOS App Store | Already built in Flutter |
| **Q1 2026** | Android Play Store | Already built in Flutter |

Flutter app is cross-platform ready. PWA first for speed, then native apps for App Store presence and offline capabilities.

---

## Technical Architecture

### Current Stack
- **Framework:** Flutter (mobile + web)
- **Local DB:** Drift (SQLite wrapper)
- **Auth:** Firebase Auth (Google Sign-In on branch)
- **Video:** Vimeo embeds

### To Add for January
- Magic link auth flow
- Stripe checkout integration (web)
- Vimeo embed player component
- Entitlement checking (email match + subscription status)

### Future Additions
- RevenueCat (native in-app purchases)
- Cloudflare or Firebase for video upload (coaching feature)
- Supabase for cloud sync

---

## Content Library

### Video Courses

| Course | Videos | Tier | Status |
|--------|--------|------|--------|
| Plotting Fundamentals | 3 | Free | Ready (migrate from GHL) |
| 3D Aiming | 8 | £12 or Premium | Ready (migrate from GHL) |

### Training Programs

| Program | Type | Tier | Status |
|---------|------|------|--------|
| OLY Bow Training | Structured (26 weeks) | Basic+ | Built |
| Breath Training | Sessions | Basic+ | Built |

### Future Content (Post-January)

- Additional technique courses
- Mental game / competition prep
- Equipment setup guides
- Written guides / ebooks

---

## Success Criteria

### January Launch
- [ ] All 280 GoHighLevel users can access their content
- [ ] 30 paid users have 3D Aiming access working
- [ ] Vimeo videos play without issues
- [ ] Stripe purchases work for new customers
- [ ] Email list successfully migrated

### 3-Month Success
- [ ] 50+ active monthly users
- [ ] 10+ new paying subscribers
- [ ] Native apps in both app stores
- [ ] Zero data loss incidents

### 6-Month Success
- [ ] 200+ active monthly users
- [ ] Coaching feature live (video upload)
- [ ] Arrow plotting fully functional
- [ ] Revenue covering hosting costs

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| GoHighLevel shuts down before migration | Export email list and videos immediately |
| Users can't find their content | Clear migration email with direct link |
| Vimeo embed issues | Test thoroughly, have Cloudflare Stream as backup |
| Legacy email matching fails | Manual override process for support cases |
| Scope creep delays January deadline | This PRD. PWA + courses only. Everything else waits. |

---

## Explicit Non-Goals (January)

**Not shipping in January:**
- Native app store releases
- In-app purchases
- Video upload coaching
- AI analysis or insights
- Offline video downloads
- Progress tracking on videos
- Social features
- Push notifications
- Advanced plotting (shaft tagging, smart zoom, multi-face)

These are all valid future features, but January is about **not abandoning existing customers**.

---

## Post-January Roadmap

### Phase 2: Native Apps (Q1 2026)
- iOS and Android app store submissions
- RevenueCat for in-app subscriptions
- Offline video downloads (Premium)
- Video progress tracking

### Phase 3: Full Training Platform (Q2 2026)
- Arrow plotting (per spec)
- Score import and history
- Volume tracking with EMAs
- Training load monitoring

### Phase 4: Coaching Features (Q3 2026)
- Video upload for coaching review
- Calendly integration for booking
- Coach feedback system
- Premium tier fully realized

### Phase 5: Intelligence (Q4 2026+)
- AI coaching suggestions
- Pattern detection
- Performance predictions
- Equipment correlations

---

## Definition of Done (January)

January launch is complete when:

- [ ] PWA deployed and accessible
- [ ] Magic link auth working
- [ ] Both courses visible and playable
- [ ] Free users see Plotting, locked out of 3D Aiming
- [ ] Paid legacy users see all content
- [ ] Stripe checkout works for new purchases
- [ ] Arrow plotting functional (place arrows, calculate scores, save sessions)
- [ ] Migration email sent to all 280 GoHighLevel users
- [ ] Email list exported and imported to new platform

---

**Sign-off required before major scope changes.**

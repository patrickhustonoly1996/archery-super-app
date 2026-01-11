# Archery Super App - Product Roadmap

## Full Vision

A comprehensive training system that helps archers at all levels train smarter through:
- **Intelligent practice logging** with minimal friction
- **Personalized coaching** that adapts to the athlete's context
- **Performance analytics** that reveal patterns and progress
- **Training program management** with deterministic progression paths
- **Equipment tracking** and tuning history
- **Competition preparation** tools and mental game support

## Core Pillars

### 1. Practice Intelligence
- Quick-log shooting sessions (score, conditions, equipment, feel)
- Pattern recognition across sessions
- Contextual insights (weather impact, equipment correlations, fatigue patterns)
- Video integration for form analysis

### 2. Coaching System
- Versioned coaching content (immutable Markdown)
- AI interpretation layer that adapts coaching to athlete's current state
- Training block structure (phases, cycles, sessions)
- Progressive skill development paths

### 3. Performance Analytics
- Score progression tracking
- Weakness identification (specific distances, arrow positions, conditions)
- Training load monitoring
- Competition vs practice performance comparison

### 4. Equipment Management
- Bow setup tracking (limb weight, tiller, brace height, etc.)
- Tuning history and paper test logs
- Arrow selection and spine charts
- Equipment wear tracking and maintenance reminders

### 5. Mental Game
- Competition routine builder
- Pressure training protocols
- Shot process refinement
- Mental rep logging

### 6. Competition Tools
- Event preparation checklists
- Scoring and opponent tracking
- Post-competition review framework
- Travel and logistics planning

---

## Release Plan

### MVP (Minimum Viable Product)
**Goal:** Data collection foundation - track arrows, volume, and score history

**Platform:** iOS first (offline-first, club use priority)

**Features:**
- [ ] Arrow plotting system
  - Per-end arrow plots with coordinates
  - Group size analysis
  - Shaft quality metrics (consistency analysis)
  - Session-level aggregation
  - Full spec in docs/plotting-spec.md
- [ ] Arrow volume tracking
  - Daily entries (date, title, arrows shot, 2 notes columns)
  - CSV bulk upload (3 years historical data)
  - Editable entries (past and planned future volume)
  - EMA graphs (7/28/90 day)
  - Adjustable timeframes (3/6/9/12 months)
  - Training load ratio visualization (7:28 EMA)
- [ ] Score history (career-long)
  - ianseo.net scraper (UK tournaments, see docs/scraper-architecture.md)
  - CSV import for manual records
  - Manual entry fallback
  - Competition results back to career start
- [ ] Local data storage (SQLite)
  - Full offline capability
  - No cloud dependency for MVP
- [ ] Dark theme with gold accents

**Success Criteria:**
- Used at every club session
- Arrow plotting captures full session accurately
- Volume data shows 3-year trend clearly
- Score history complete and accurate
- Never loses data, always works offline

---

### V1 - Smart Logging
**Goal:** Make logging effortless and generate useful insights

**Features:**
- [ ] Enhanced session logging
  - Per-end scoring with arrow plot
  - Equipment used (bow, arrows, sight settings)
  - Training focus tags (form, execution, mental)
  - Quick templates for common session types
- [ ] Pattern detection
  - "You shoot better in mornings"
  - "Right-side misses increase in wind"
  - "Scores drop after 60 arrows"
- [ ] Equipment profiles
  - Store multiple bow setups
  - Quick selection during logging
  - Basic equipment change history
- [ ] Cloud backup (optional)
  - Encrypted sync to personal cloud
  - Maintains offline-first principle
  - 72hr grace period enforcement

**Success Criteria:**
- Logging still takes <30 seconds
- You discover at least 2 useful patterns
- No session data ever lost

---

### V2 - Coaching Intelligence
**Goal:** Dynamic coaching that adapts to your current state

**Features:**
- [ ] AI coaching interpreter
  - Reads versioned coaching Markdown
  - Adapts recommendations based on recent sessions
  - Suggests focus areas from pattern analysis
  - "Today's Practice" intelligent suggestions
- [ ] Training block structure
  - Create phase-based training plans (base, build, peak, taper)
  - Session templates within blocks
  - Load monitoring and recovery suggestions
- [ ] Weakness targeting
  - Identifies specific scoring gaps
  - Generates targeted drill recommendations
  - Tracks weakness progression over time
- [ ] Video integration (basic)
  - Attach videos to sessions
  - Side-by-side comparison
  - Slow-motion playback

**Success Criteria:**
- AI suggestions are relevant 80%+ of the time
- You feel coaching is personalized to your needs
- Training blocks guide your weekly planning

---

### V3 - Equipment & Tuning
**Goal:** Complete equipment management and tuning history

**Features:**
- [ ] Advanced equipment tracking
  - Detailed bow specs (limb weight, draw length, tiller, etc.)
  - Arrow specifications (spine, weight, components)
  - String and cable change tracking
  - Maintenance schedules and reminders
- [ ] Tuning workflow
  - Paper test logging with photos
  - Walk-back test tracking
  - French tune results
  - Bareshaft tuning records
- [ ] Equipment correlations
  - Performance by bow setup
  - Weather-appropriate equipment recommendations
  - Wear pattern detection
- [ ] Sight tape management
  - Generate custom sight tapes
  - Multi-distance validation
  - Indoor/outdoor tape sets

**Success Criteria:**
- Complete tuning history never lost
- Equipment changes correlated to performance
- Maintenance never forgotten

---

### V4 - Competition Mode
**Goal:** Competition preparation and execution tools

**Features:**
- [ ] Competition preparation
  - Pre-competition checklists
  - Equipment verification
  - Travel packing lists
  - Routine rehearsal timer
- [ ] Competition scoring
  - Live scoring with running total
  - Opponent score tracking (team events)
  - End-by-end arrow plot
  - Real-time ranking calculations
- [ ] Shot routine tools
  - Timer for shot rhythm
  - Process checklist (setup, draw, aim, release)
  - Pressure training modes
- [ ] Post-competition review
  - Performance vs practice comparison
  - Pressure moment analysis
  - Lessons learned capture

**Success Criteria:**
- Used at every competition
- Pre-comp prep reduces stress
- Post-comp insights improve next performance

---

### V5 - Mental Game
**Goal:** Comprehensive mental training and competition psychology

**Features:**
- [ ] Shot process builder
  - Customize shot sequence steps
  - Cue word selection
  - Process timing refinement
- [ ] Mental rep logging
  - Track visualization sessions
  - Mental practice without shooting
  - Process refinement tracking
- [ ] Pressure training
  - Simulated competition modes
  - Score-based pressure scenarios
  - Recovery protocols after bad ends
- [ ] Mindfulness integration
  - Pre-session centering routines
  - Post-session reflection prompts
  - Competition anxiety management

**Success Criteria:**
- Mental reps tracked as consistently as live sessions
- Competition nerves measurably reduced
- Shot process becomes automatic under pressure

---

### V6 - Social & Coaching (Optional)
**Goal:** Multi-user support for coach/athlete relationships

**Features:**
- [ ] Coach access
  - View athlete training logs
  - Leave coaching notes on sessions
  - Assign training blocks
  - Monitor training load
- [ ] Club/team features
  - Share equipment setups
  - Team training sessions
  - Group competitions
  - Leaderboards
- [ ] Community (maybe)
  - Anonymous benchmark comparisons
  - Drill library sharing
  - Equipment reviews

**Success Criteria:**
- Value validated with real coach-athlete pairs
- Privacy maintained appropriately
- Social features enhance rather than distract

---

## Technical Milestones

### Foundation (MVP through V1)
- Flutter app structure
- SQLite local storage
- Offline-first architecture
- Basic cloud sync (optional)
- Entitlement system (£1/month)

### Intelligence Layer (V2)
- AI integration (OpenAI/Claude API)
- Pattern detection algorithms
- Coaching content versioning
- Graceful AI failure modes

### Media & Advanced (V3-V5)
- Video storage and playback
- Image handling (tuning photos)
- Advanced analytics
- Export capabilities (CSV, PDF reports)

### Multi-user (V6)
- User authentication
- Data sharing permissions
- Coach dashboard
- Team management

---

## Principles Throughout

1. **Offline-first never compromised** - Every feature works on airplane
2. **No data loss ever** - Append-only logs, versioned coaching, no silent rewrites
3. **Speed matters** - Logging stays under 30 seconds, UI responds instantly
4. **Graceful degradation** - AI fails → manual still works perfectly
5. **Respect the athlete** - No nags, no dark patterns, data is yours
6. **Build foundations first** - Each version must be solid before next layer

---

## Open Questions (to discuss)

1. **MVP scope boundaries** - What's the absolute minimum you'd use daily?
2. **AI provider** - OpenAI (GPT-4) vs Anthropic (Claude) vs local models?
3. **Video storage** - Local only vs cloud vs hybrid?
4. **Platform priority** - iOS first, Android first, or simultaneous?
5. **Coaching content source** - Your own Markdown files? Import from elsewhere?
6. **Competition focus** - Recurve only or support compound/barebow too?
7. **Social features** - Worth building or keep it personal forever?

---

## Next Steps

1. Validate MVP scope with Patrick
2. Determine platform priority (iOS/Android)
3. Set up Flutter project structure
4. Design data models for practice sessions
5. Build first logging screen
6. Test with real practice sessions


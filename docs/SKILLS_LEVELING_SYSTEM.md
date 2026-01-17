# Skills Leveling System (RuneScape-Inspired)

A 1-99 leveling system for tracking progression across all areas of archery training.

## Overview

Each main feature area has a **parent skill level** (1-99). Sub-metrics contribute XP toward the parent level rather than having their own individual levels. This keeps the display clean while preserving granular progression.

---

## Skill Categories

**8 Skills Total** (Max Total Level: 792)

---

### 1. ARCHERY SKILL (Performance Level)
The core shooting skill - measures how good you are.

**XP Sources:**
- Handicap improvements (inverted: lower HC = more XP)
- Breaking into new HC brackets (milestone bonus)
- Achieving personal best scores
- Round completions at current or better handicap

**Level Mapping:**
- Lv.1 = HC 150+ (beginner)
- Lv.50 = HC ~50 (club archer)
- Lv.75 = HC ~20 (county level)
- Lv.90 = HC ~10 (national level)
- Lv.99 = HC 1-5 (world class)

---

### 2. VOLUME (Training Quantity)
How much you shoot - raw arrow count and session frequency.

**XP Sources:**
- Arrows shot (per session, cumulative)
- Sessions completed
- Weekly/monthly volume targets hit
- Volume streaks (consecutive days/weeks with arrows)

**Level Mapping:**
- Lv.1 = First arrows
- Lv.50 = ~10,000 lifetime arrows
- Lv.75 = ~50,000 lifetime arrows
- Lv.99 = ~200,000+ lifetime arrows (elite volume)

---

### 3. CONSISTENCY (Training Regularity)
How regularly you show up - the habit of practice.

**XP Sources:**
- Days trained per week
- Consecutive training days (streaks)
- Weekly session completion rate
- Monthly training adherence
- Long-term habit maintenance

**Level Mapping:**
- Lv.1 = Sporadic, just starting
- Lv.50 = Regular training (3-4 days/week average)
- Lv.75 = Highly consistent (5-6 days/week average)
- Lv.99 = Elite discipline (near-daily training, long streaks)

---

### 4. BOW FITNESS (Physical Training)
**Contributes:**
- **Hold Time** - Accumulated draw time from OLY training
- **Training Completion** - Finishing prescribed exercises
- **Form Quality** - Structure feedback scores (inverted: lower = better)
- **Stability** - Shaking feedback scores (inverted: lower = better)

**XP Sources:**
- Complete OLY training sessions
- Progress through training levels (1.x → 2.x etc.)
- Improve feedback scores over time
- Achieve hold time milestones

---

### 3. BREATH WORK (Mental/Physical Control)
**Contributes:**
- **Paced Breathing** - Sessions completed, duration achieved
- **Breath Hold** - Best hold times, progression through difficulty levels
- **Patrick Breath** - Best exhale times

**XP Sources:**
- Complete breath training sessions
- Set new personal records
- Progress through difficulty levels
- Consistency of practice

---

### 4. EQUIPMENT (Tuning Mastery)
The science of setup - understanding and optimizing your gear.

**Contributes:**
- **Shaft Analysis** - Bareshaft tuning, paper tuning, walk-back tests
- **Bow Setup** - Tiller, brace height, nocking point, button pressure
- **Arrow Building** - Spine selection, point weight optimization, fletching
- **Maintenance** - String changes, limb care, accessory upkeep

**XP Sources:**
- Complete shaft analysis sessions with documented results
- Log tuning changes with before/after observations
- Document equipment experiments and findings
- Build/modify arrows with recorded specs
- Achieve tuning milestones (e.g., bareshaft grouping with field points)

**Level Mapping:**
- Lv.1 = Using equipment as-is, minimal understanding
- Lv.50 = Can tune own bow, understands basic setup
- Lv.75 = Advanced tuning, can diagnose issues from arrow flight
- Lv.99 = Master tuner, deep understanding of equipment interaction

---

### 5. ROUTINES (Process Mastery)
The discipline of consistent processes - shot routine to competition day.

**Contributes:**
- **Shot Routine** - Breakdown and execution of pre-shot sequence
- **Equipment Checklists** - Local and international tournament packing
- **Weather Routines** - Condition-specific preparation
- **Mental Routines** - Visualization, focus protocols
- **Breathing Routines** - Pre-shot and between-end breathing
- **Competition Day Routines** - Arrival to first arrow preparation

**XP Sources:**
- Create and define routines (initial XP for building them)
- Complete routine checklists
- Iterate and improve routines over time
- Use routines consistently (streaks)
- Document routine refinements

**Level Mapping:**
- Lv.1 = No defined routines
- Lv.50 = Has basic routines, uses them sometimes
- Lv.75 = Comprehensive routines, consistent usage
- Lv.99 = Routines are second nature, continuously refined

---

### 6. COMPETITION (Performance Under Pressure)
The ultimate test - how you perform when it counts.

**Contributes:**
- **Competition Frequency** - How often you compete
- **Pressure Performance** - Competition scores vs practice scores
- **Event Progression** - Qualifications, eliminations, finals, medals
- **Post-Competition Review** - Structured analysis after events

**XP Sources:**
- Enter competitions (participation XP)
- Score within X% of practice average (pressure performance bonus)
- Beat practice average in competition (significant bonus)
- Complete post-competition review/debrief
- Progress through tournament stages (elimination rounds, finals)
- Achieve placements/medals

**Pressure Performance Rating:**
Competition HC vs Practice HC ratio:
- 100%+ = Performing above practice level (rare, big bonus)
- 90-100% = Solid competition performance
- 80-90% = Normal competition dip
- <80% = Significant pressure impact (still get participation XP)

**Level Mapping:**
- Lv.1 = Never competed / first competition
- Lv.50 = Regular competitor, moderate pressure handling
- Lv.75 = Experienced competitor, performs close to practice level
- Lv.99 = Elite competitor, thrives under pressure

---

## XP Curve

### Exponential Scaling (Modified RS-Style)
- Levels 1-30: Quick progression, rewarding early engagement
- Levels 31-60: Moderate effort, sustained training required
- Levels 61-80: Significant dedication, quality matters
- Levels 81-99: Mastery level, achievable within a dedicated season

**Formula Concept:**
```
XP_for_level(n) = floor(base * growth_factor^n)
```

Unlike RS where 92 = halfway to 99, this curve is gentler - approximately:
- Level 50 = ~15% of total XP to 99
- Level 75 = ~40% of total XP to 99
- Level 90 = ~70% of total XP to 99

---

## Bonus XP System

### 1. Milestone Achievements
- **Personal Bests**: New handicap record, hold time record, etc.
- **Handicap Brackets**: Breaking into single digits, sub-5, etc.
- **Training Blocks**: Completing a full OLY progression cycle
- **Cumulative Milestones**: 1000 arrows, 10 hours hold time, etc.

### 2. Streaks & Consistency
- **Daily Multiplier**: Consecutive days with activity
- **Weekly Targets**: Complete all planned sessions for the week
- **Habit Maintenance**: Maintain streaks over time (7 day, 30 day, etc.)

### 3. Quality Bonuses
- **High Feedback Scores**: Better form/stability ratings
- **Session Target Achievement**: Hit prescribed targets vs just completing
- **Improvement Trend**: Bonus for measurable improvement over time

---

## UI Design

### Main Menu Display
Each menu item shows:
```
[PIXEL ICON] MENU ITEM          Lv.67 [====----]
```
- Level number (Lv.XX)
- Small circular or thin linear progress bar showing XP to next level

### Skills Panel
- Accessible from main menu (new "SKILLS" item or tap on any level badge)
- Grid layout showing all 5 skill categories
- Pixelated icons for each skill (keeping with app's pixel aesthetic)
- Tap a skill to see:
  - Current level and XP
  - XP to next level
  - Contributing metrics breakdown
  - Recent XP gains
  - Historical progression

### Radar Graph Integration
- Skills panel includes radar chart view
- Each spoke = one skill category
- Level determines spoke length (Lv.1 = center, Lv.99 = edge)
- Visual representation of overall skill balance

### Level-Up Celebration
- **Fireworks**: Visual effect on level-up
- **C64 Theme**: Chiptune celebration sound
- **Notification**: "ARCHERY leveled up! Lv.42 → Lv.43"

---

## Routines Feature (New)

### Routine Builder
- Drag-and-drop interface
- Notion-style blocks with expandable detail
- Each step can include:
  - Title
  - Detailed notes/instructions
  - Optional timer
  - Checkbox for completion tracking

### Routine Types
1. **Shot Routine** - Pre-shot sequence breakdown
2. **Equipment Checklist** - Packing lists with local/international variants
3. **Weather Routine** - Condition-specific prep (rain, wind, heat, cold)
4. **Mental Routine** - Visualization and focus protocols
5. **Breathing Routine** - Breath sequences for competition
6. **Competition Day Routine** - Full day timeline from arrival

### Routine Tracking
- Mark routines as complete
- Track usage frequency
- Iterate and version routines over time
- XP earned for routine adherence

---

## Data Model Considerations

### New Tables/Collections
- `skill_levels` - Current level and XP per skill category
- `xp_history` - Log of XP gains with source, amount, timestamp
- `routines` - User-created routines with steps
- `routine_completions` - Tracking when routines are used

### Existing Data Integration
- Pull from `bow_training_logs` for Bow Fitness XP
- Pull from `breath_sessions` for Breath Work XP
- Pull from `sessions` and `imported_scores` for Archery XP
- Pull from equipment providers for Equipment XP

---

## Implementation Priority

### Phase 1: Core Leveling
1. Define XP formulas and level thresholds
2. Create skill_levels data model
3. Implement XP calculation from existing data
4. Add level display to main menu

### Phase 2: Skills Panel
1. Create skills panel UI
2. Pixelated skill icons
3. XP progress and breakdown views
4. Radar chart integration

### Phase 3: Level-Up Experience
1. Fireworks animation
2. C64 celebration sound
3. Level-up notifications

### Phase 4: Routines Feature
1. Routine data model
2. Drag-and-drop builder UI
3. Routine templates (shot, equipment, competition, etc.)
4. Routine completion tracking and XP

### Phase 5: Bonus Systems
1. Milestone detection and bonus XP
2. Streak tracking
3. Quality multipliers

---

## Total Level

Display combined "Total Level" (sum of all 7 skills, max 693) prominently:
- Show in skills panel header
- Optionally on main menu or profile
- Single number representing overall progression

---

## Real-World Rewards

Level milestones unlock actual coaching value - incentivizes engagement while driving coaching business.

### Milestone Rewards (Example Structure)
| Level | Reward |
|-------|--------|
| 25 | Welcome video from Patrick |
| 50 | 30-minute remote coaching session |
| 75 | Personalized training plan review |
| 99 (per skill) | Certificate of mastery |
| 99 (all skills) | 2-hour in-person session with Patrick |

### Implementation Considerations
- Rewards tracked in user profile
- Redemption flow (scheduling, contact)
- Entitlement integration (subscriber-only? or engagement reward for all?)
- Reward history/claimed status

---

## Future Considerations

1. **Leaderboards**: Compare levels with other users (opt-in)?
2. **Seasonal Resets**: Optional prestige system?
3. **Team/Club Features**: Aggregate club levels?

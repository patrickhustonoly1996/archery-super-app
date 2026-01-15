# Archery Domain Knowledge

Reference document for AI sessions. Contains archery-specific knowledge from Patrick Huston (Olympic archer) that informs app design and implementation.

---

## Scoring Systems

### 10-Zone (WA/Metric Rounds)
Standard World Archery scoring. Each ring is a separate score.

| Zone | Score | Color |
|------|-------|-------|
| X | 10 (inner 10) | Gold center |
| 10 | 10 | Gold |
| 9 | 9 | Gold |
| 8 | 8 | Red |
| 7 | 7 | Red |
| 6 | 6 | Blue |
| 5 | 5 | Blue |
| 4 | 4 | Black |
| 3 | 3 | Black |
| 2 | 2 | White |
| 1 | 1 | White |
| Miss | 0 | Off target |

**Rounds using 10-zone:** All WA rounds (720, 1440, 18m indoor, 25m), all metric rounds.

### 5-Zone (Imperial/AGB Rounds)
Traditional British scoring by color band, not individual ring.

| Color | Score | Rings Included |
|-------|-------|----------------|
| Gold | 9 | X, 10, 9 |
| Red | 7 | 8, 7 |
| Blue | 5 | 6, 5 |
| Black | 3 | 4, 3 |
| White | 1 | 2, 1 |
| Miss | 0 | Off target |

**Rounds using 5-zone:** York, Hereford, Bristol (I-V), St George, Albion, Windsor, National, Western, Warwick, American, and all their Short/Junior variants.

**Visual display:** Still show all 10 rings on target face (matches physical target). Only the score calculation changes.

---

## Round Types

### WA Indoor
- **WA 18m:** 60 arrows, 40cm face, 3 arrows/end
- **WA 25m:** 60 arrows, 60cm face, 3 arrows/end
- **Tri-spot:** Same as above but 3 small faces, one arrow each

### WA Outdoor
- **WA 720:** 72 arrows at single distance (30m, 40m, 50m, 60m, or 70m)
- **WA 1440:** 144 arrows across 4 distances (90/70/50/30m for men)

### Imperial (AGB)
- **York:** Men's championship round, 100/80/60 yards
- **Hereford:** Women's equivalent, 80/60/50 yards
- **Bristol I-V:** Progressive distances for development
- **National/Western/Warwick series:** Various club rounds

### Key Insight
Imperial rounds use YARDS, metric rounds use METERS. This affects distance display and potentially handicap calculations.

---

## Group Analysis

### Expressing Group Size
**Use ring notation, not millimeters.** Archers think in rings.

| Description | Meaning |
|-------------|---------|
| "Sub-9 group" | All arrows inside the 9 ring |
| "9.5 group" | Spread covers half the 9 ring |
| "Mostly red" | Group spans 7-8 ring area |
| "Inside the 6" | Outermost arrow in 6 ring |

### Realistic Group Sizes at 70m
| Archer Level | Typical Group |
|--------------|---------------|
| Elite | Sub-9 (all inside 9 ring) |
| Good club | Mostly inside the red (7-8) |
| Average | Wouldn't really shoot 70m much |
| Developing | Happy with inside red at 50 yards |

**Note:** Average and developing archers typically don't shoot 70m - they'd be at shorter distances.

### Pattern Analysis
| Pattern | Likely Cause |
|---------|--------------|
| Tight group, offset | Sight needs adjusting |
| Vertical spread | Draw length or anchor inconsistency |
| Horizontal spread | Bow hand or release issues |
| Random scatter | Multiple issues, need more data |

---

## 252 Scheme

Club progression system used across UK archery clubs.

### How It Works
1. Shoot 36 arrows at 122cm face
2. Use 5-zone scoring (9-7-5-3-1)
3. Score 252+ to earn badge and progress
4. 252 = averaging inside the red (7) per arrow
5. Progress to next distance after achieving on two separate days

### Distances
20 → 30 → 40 → 50 → 60 → 80 → 100 yards

Different colored badges for each distance achieved.

### Purpose
- Prevents frustration from shooting too far too soon
- Ensures consistent technique before adding distance
- Provides visible progression milestones

---

## Sight Adjustment

### Clicks-Per-Ring
A learned value specific to each archer's equipment.

**How to determine:**
1. Shoot and plot centered group at distance
2. Move sight a known amount (typically 5 turns = 100 clicks)
3. Re-plot group and find exact center
4. Count rings (including decimals) from new center to X (target center)
5. Calculate: 100 clicks ÷ rings moved = clicks per ring

**Important:** Count to the X (absolute center), not to the 10 ring line - otherwise you lose a ring of precision.

### Manufacturer Variance
Different sight manufacturers have different clicks per revolution. Standard is ~20 clicks/turn but varies.

### Training Value
Teaching athletes to understand their clicks-per-ring builds equipment familiarity and confidence in making sight adjustments.

---

## Plotting Flow (UX Requirements)

### What Good Plotting Feels Like
- **Tap and done:** One tap places arrow exactly where intended
- **Fast:** Plot 3-6 arrows in quick succession
- **One-handed:** Works while walking back from target
- **Glanceable:** Can look down briefly while walking

### Real Usage Context
Archers plot arrows in two scenarios:
1. **At the target:** Standing at face, looking at actual holes, recording positions
2. **Walking back:** Already memorized positions, logging while returning to line

Both require speed and minimal attention.

### Why MyTargets Doesn't Have Plotting
It's hard to get right. The coordinate math, zoom behavior, and touch UX all need to work perfectly together. Bad plotting is worse than no plotting - it just frustrates users.

---

## Common Data Entry Errors

### Score Entry Mistakes
| Error Type | Example |
|------------|---------|
| Typo | 650 instead of 560 (transposed digits) |
| Wrong round | Selected WA 720 but shot a 1440 |
| Wrong distance | Selected 70m but actually shot 60m |
| Partial round | Shot half but entered as full |

### Red Flags
- **Perfect 720/720:** Near-impossible, likely data entry error
- **Under 200 on a 720:** Unusual for anyone tracking scores
- **Handicap jump of 20+ overnight:** Probably wrong round selected

---

## Handicap System

### What Handicap Means
Single number representing archer's ability across all round types. Lower = better.

| Handicap | Level |
|----------|-------|
| 0-15 | Elite (GMB, MB) |
| 30-60 | Active club archer |
| 70-100 | Beginner working toward classifications |

### Same Score, Different Handicap
A 650 on WA 720 60m gives a WORSE (higher) handicap than a 650 on WA 720 70m, because 60m is an easier distance.

### Tables
Handicap tables are published by Archery GB. Score → Handicap conversion depends on round type.

---

## Equipment Context

### Quiver/Shaft Tracking
Serious archers track individual arrow performance. Each arrow (shaft) in a quiver may have slightly different characteristics.

### Why Track Shafts
- Identify damaged or inconsistent arrows
- Build confidence in equipment
- Diagnose grouping issues (one arrow always off = arrow problem)

---

## Terminology Quick Reference

| Term | Meaning |
|------|---------|
| End | A set of arrows shot together (typically 3 or 6) |
| Dozen | 12 arrows |
| Face | The target (40cm, 80cm, 122cm sizes) |
| X | Inner 10 ring (scores 10 but tracked separately) |
| Linecutter | Arrow touching a ring boundary |
| Sight mark | Sight setting for a specific distance |
| Group | Cluster of arrows from a session/end |
| Spread | How dispersed a group is |

---

*This document should be expanded as more domain knowledge emerges. Source: Patrick Huston, Olympic archer.*

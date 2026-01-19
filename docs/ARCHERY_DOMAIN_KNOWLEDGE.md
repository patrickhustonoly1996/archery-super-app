# Archery Domain Knowledge

Reference document for AI sessions. Contains archery-specific knowledge from Patrick Huston (Olympic archer) that informs app design and implementation.

**Reference:** Much of the technical data here derives from [archeryutils](https://github.com/jatkinson1000/archeryutils), an open-source Python library for archery calculations.

---

## Scoring Systems

### 10-Zone (WA/Metric Rounds)
Standard World Archery scoring. Each ring is a separate score. Ring diameters are 1/10 increments of face diameter.

| Zone | Score | Color | Ring Diameter |
|------|-------|-------|---------------|
| X | 10 (inner 10) | Gold center | 1/20 of face |
| 10 | 10 | Gold | 1/10 of face |
| 9 | 9 | Gold | 2/10 of face |
| 8 | 8 | Red | 3/10 of face |
| 7 | 7 | Red | 4/10 of face |
| 6 | 6 | Blue | 5/10 of face |
| 5 | 5 | Blue | 6/10 of face |
| 4 | 4 | Black | 7/10 of face |
| 3 | 3 | Black | 8/10 of face |
| 2 | 2 | White | 9/10 of face |
| 1 | 1 | White | Full face |
| Miss | 0 | Off target | - |

**Rounds using 10-zone:** All WA rounds (720, 1440, 18m indoor, 25m), all metric rounds.

### 11-Zone (Inner X)
Same as 10-zone but X ring scores 11 instead of 10. Inner X is 1/20 of face diameter.

### 5-Zone (Imperial/AGB Rounds)
Traditional British scoring by color band, not individual ring. Ring diameters at 1/10, 3/10, 5/10, 7/10, 9/10 of face.

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

### Compound Scoring Variants

| System | Description |
|--------|-------------|
| 10-zone compound | Inner X (1/20 diameter) scores 10, everything else shifted |
| 10-zone 5-ring compound | Only inner 5 rings shown, compound X ring |
| 10-zone 6-ring | Only inner 6 rings shown |
| 10-zone 5-ring | Only inner 5 rings (tri-spot faces) |

### Field Scoring (WA Field)
Different from target archery. Concentric rings with scores 6-5-4-3-2-1.

| Ring | Score | Diameter |
|------|-------|----------|
| Inner | 6 | 1/10 of face |
| 2nd | 5 | 1/5 of face |
| 3rd | 4 | 2/5 of face |
| 4th | 3 | 3/5 of face |
| 5th | 2 | 4/5 of face |
| Outer | 1 | Full face |

### Worcester Scoring
Five rings, scores 5-4-3-2-1. Used for indoor Worcester rounds. Rings at 1/5, 2/5, 3/5, 4/5, full diameter.

### IFAA Field Scoring
Similar to Worcester but with expert variant. Used in IFAA field rounds.

### Beiter Hit/Miss
Binary scoring - hit or miss. Single ring at full diameter.

---

## Round Types

### WA Indoor

| Round | Arrows | Face | Distance | Scoring |
|-------|--------|------|----------|---------|
| WA 18m | 60 (2x30) | 40cm | 18m | 10-zone |
| WA 18m Compound | 60 (2x30) | 40cm | 18m | 10-zone compound |
| WA 18m Triple | 60 (2x30) | 40cm tri-spot | 18m | 10-zone 5-ring |
| WA 25m | 60 (2x30) | 60cm | 25m | 10-zone |
| WA 25m Compound | 60 (2x30) | 60cm | 25m | 10-zone compound |

### WA Outdoor

| Round | Arrows | Distances | Face | Scoring |
|-------|--------|-----------|------|---------|
| WA 1440 (90m) | 144 (4x36) | 90/70/50/30m | 122cm/80cm | 10-zone |
| WA 1440 (70m) | 144 (4x36) | 70/60/50/30m | 122cm/80cm | 10-zone |
| WA 1440 (60m) | 144 (4x36) | 60/50/40/30m | 122cm/80cm | 10-zone |
| WA 720 70m | 72 (2x36) | 70m | 122cm | 10-zone |
| WA 720 60m | 72 (2x36) | 60m | 122cm | 10-zone |
| WA 720 50m Compound | 72 (2x36) | 50m | 80cm | 10-zone |
| WA 720 50m Barebow | 72 (2x36) | 50m | 122cm | 10-zone |
| WA 900 | 90 (3x30) | 60/50/40m | 122cm | 10-zone |

### AGB Indoor

| Round | Arrows | Face | Distance | Scoring |
|-------|--------|------|----------|---------|
| Portsmouth | 60 (2x30) | 60cm | 20yd | 10-zone |
| Bray I | 30 (1x30) | 40cm | 20yd | 10-zone |
| Bray II | 30 (1x30) | 40cm | 25yd | 10-zone |
| Stafford | 72 (2x36) | 80cm | 30m | 10-zone |
| Worcester | 60 (2x30) | 16in | 20yd | Worcester |
| Vegas | 30 (1x30) | 40cm | 18m | 10-zone |
| Vegas 300 | 30 (1x30) | 40cm | 18m | 11-zone |

### Imperial (AGB Outdoor)

| Round | Arrows | Distances | Face |
|-------|--------|-----------|------|
| York | 72/48/24 | 100/80/60yd | 122cm |
| Hereford | 72/48/24 | 80/60/50yd | 122cm |
| Bristol I | 72/48/24 | 80/60/50yd | 122cm |
| Bristol II | 72/48/24 | 60/50/40yd | 122cm |
| Bristol III | 72/48/24 | 50/40/30yd | 122cm |
| Bristol IV | 72/48/24 | 40/30/20yd | 122cm |
| Bristol V | 72/48/24 | 30/20/10yd | 122cm |
| St George | 36/36/36 | 100/80/60yd | 122cm |
| Albion | 36/36/36 | 80/60/50yd | 122cm |
| Windsor | 36/36/36 | 60/50/40yd | 122cm |
| National | 48/24 | 60/50yd | 122cm |
| Western | 48/48 | 60/50yd | 122cm |
| American | 30/30/30 | 60/50/40yd | 122cm |

All imperial rounds use 5-zone scoring on 122cm faces.

### WA Field Rounds
Field archery uses varied terrain and distances. Target sizes: 20cm, 40cm, 60cm, 80cm.

| Type | Description |
|------|-------------|
| Marked | Distances displayed to archer |
| Unmarked | Archer must judge distance |
| Mixed | Combination of marked/unmarked |

Color-coded difficulty: Red (hardest) → Blue → Yellow → White (easiest)

### IFAA Field Rounds
| Round | Format |
|-------|--------|
| IFAA Field | Progressive 6.7-80yd, varied faces |
| IFAA Hunter | 14-70yd, realistic hunting distances |
| IFAA Expert | Worcester scoring variant |
| IFAA Flint | Mixed short/long, alternating |
| IFAA Indoor | 10yd, 40cm face, Worcester scoring |

### Key Insight
Imperial rounds use YARDS, metric rounds use METERS. This affects distance display and handicap calculations.

**Unit Conversions:**
- 1 yard = 0.9144 meters
- 1 inch = 2.54 cm
- 1 meter = 1.0936 yards

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

## Handicap System (AGB)

### What Handicap Means
Single number representing archer's ability across all round types. **Lower = better.** Scale typically runs -75 to 300.

| Handicap | Level |
|----------|-------|
| 0-15 | Elite (EMB, GMB, MB) |
| 15-30 | Very strong club archer |
| 30-60 | Active club archer |
| 60-80 | Developing archer |
| 80-100 | Beginner working toward classifications |

### The Math Behind Handicaps
Handicaps model an archer's "group size" (angular deviation) and predict scores based on target geometry.

**New AGB Scheme (2023):**
```
σ_t = ang_0 × (1 + step/100)^(handicap + datum) × exp(kd × distance)
```

**Parameters:**
- `ang_0` = 5.0×10⁻⁴ radians (baseline angle)
- `step` = 3.5% (change per handicap step)
- `datum` = 6.0 (baseline offset)
- `kd` = 0.00365 (distance scaling)
- Arrow diameter: 5.5mm outdoor, 9.3mm indoor

The formula calculates angular deviation (σ_t), which converts to radial deviation (group size) when multiplied by distance. This predicts expected scores for any target configuration.

### Same Score, Different Handicap
A 650 on WA 720 60m gives a WORSE (higher) handicap than a 650 on WA 720 70m, because 60m is an easier distance. The handicap system normalizes difficulty.

### Reverse Calculation
Given a score and round, the system can calculate handicap using numerical root-finding (Brent's method). This is how archers track improvement across different rounds.

### Tables
Handicap tables show required scores for each handicap value per round. Published by Archery GB, but can be computed from the formulas above.

---

## Classification System (AGB)

Archery GB classifications recognize achievement levels. Different systems for outdoor, indoor, and field.

### Outdoor Classifications (highest to lowest)

| Abbrev | Full Name | Notes |
|--------|-----------|-------|
| EMB | Elite Master Bowman | Highest achievement |
| GMB | Grand Master Bowman | |
| MB | Master Bowman | Only on "prestige" rounds |
| B1 | Bowman 1st Class | |
| B2 | Bowman 2nd Class | |
| B3 | Bowman 3rd Class | |
| A1 | Archer 1st Class | |
| A2 | Archer 2nd Class | |
| A3 | Archer 3rd Class | Entry level |

### Indoor Classifications

| Abbrev | Full Name |
|--------|-----------|
| I-GMB | Indoor Grand Master Bowman |
| I-MB | Indoor Master Bowman |
| I-B1 | Indoor Bowman 1 |
| I-B2 | Indoor Bowman 2 |
| I-B3 | Indoor Bowman 3 |
| I-A1 | Indoor Archer 1 |
| I-A2 | Indoor Archer 2 |
| I-A3 | Indoor Archer 3 |

### How Classifications Work

1. **Handicap-based thresholds** - Each classification corresponds to a handicap value
2. **Score conversion** - Handicap converted to required score for specific round
3. **Category adjustments** - Thresholds adjusted by bowstyle, gender, and age
4. **Prestige rounds** - MB+ classifications only available on certain rounds
5. **Claiming** - Must achieve score on two separate occasions

**Formula for threshold handicap:**
```
threshold = datum + age_adjustment + gender_adjustment + (class_index × class_step)
```

### Bowstyle Datum Values

Different bowstyles have different baseline handicaps (lower = harder to achieve classifications):

| Bowstyle | Outdoor | Indoor | Field |
|----------|---------|--------|-------|
| Compound | 15 | 11 | 18 |
| Recurve | 30 | 28 | 34 |
| Barebow | 47 | 42 | 49 |
| Longbow | 65 | 61 | 68 |
| Traditional | 47 | 42 | 55 |
| Flatbow | 47 | 42 | 62 |
| Compound Limited | 15 | 11 | 32 |
| Compound Barebow | 15 | 11 | 46 |

### Age Categories

| Category | Code | Distance Requirements (M/F) | Step |
|----------|------|----------------------------|------|
| Adult | adult | 90-100m / 70-80m | 0 |
| 50+ | 50_plus | 70-80m / 60m | 1 |
| Under 21 | under_21 | 90-100m / 70-80m | 1 |
| Under 18 | under_18 | 70-80m / 60m | 2 |
| Under 16 | under_16 | 60m / 50m | 3 |
| Under 15 | under_15 | 50m / 50m | 4 |
| Under 14 | under_14 | 40m / 40m | 5 |
| Under 12 | under_12 | 30m / 30m | 6 |

**Step** affects classification threshold adjustment - higher step = easier thresholds for younger archers.

### Gender Categories
- Male
- Female

Gender affects both distance requirements and classification thresholds.

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
| Pass | A set of arrows at one distance (round subdivision) |
| Face | The target (40cm, 80cm, 122cm sizes) |
| X | Inner 10 ring (scores 10 but tracked separately) |
| Linecutter | Arrow touching a ring boundary |
| Sight mark | Sight setting for a specific distance |
| Group | Cluster of arrows from a session/end |
| Spread | How dispersed a group is |
| Handicap | Normalized skill rating (lower = better) |
| Classification | Achievement level (A3 → EMB) |
| Prestige round | Round eligible for MB+ classifications |
| Sigma (σ) | Angular/radial deviation (group size) |

### Governing Bodies

| Abbrev | Name | Region |
|--------|------|--------|
| WA | World Archery | International |
| AGB | Archery GB | United Kingdom |
| AA | Archery Australia | Australia |
| IFAA | International Field Archery Association | International (field) |

---

## Target Face Sizes

| Size | Common Use |
|------|------------|
| 122cm | Outdoor long distance (50m+), Imperial rounds |
| 80cm | Outdoor medium distance (30-50m) |
| 60cm | Indoor 25m, Portsmouth |
| 40cm | Indoor 18m, Bray, Vegas |
| 20cm | Field (close) |
| 16in | Worcester |

---

## Governing Body Round Families

| Body | Outdoor | Indoor | Field |
|------|---------|--------|-------|
| WA | 1440, 720, 900 | 18m, 25m | Marked/Unmarked |
| AGB | Imperial (York, etc) | Portsmouth, Bray, etc | - |
| AA | Metric variants | - | National Field |
| IFAA | - | Indoor | Field, Hunter, Flint |

---

## Future Integration Opportunities

Based on archeryutils and AGB standards, these features could enhance the app:

### User Profile Additions Needed
- **Gender** - Required for classification thresholds (Male/Female)
- **Age category** - Determines distance requirements and classification adjustments
- **Date of birth** - Auto-calculates age category

### Classification Tracking
- Show "next classification to achieve" based on current scores
- Display required scores for each classification per round
- Track classification claims (must achieve on two separate occasions)
- Prestige round indicators for MB+ eligibility

### Handicap Enhancements
- **Formula-based calculation** - Replace/supplement lookup tables with AGB 2023 formula
- **Sigma (group size) display** - Show expected group size at each distance based on handicap
- **Predicted scores** - "With your current handicap, expect X on this round"
- **Handicap progression charts** - Visualize improvement over time

### Bowstyle Additions for Classifications
Current BowType enum covers main categories. For full AGB compliance, add:
- Flatbow (maps to barebow datum for classifications)
- Compound Limited
- Compound Barebow

### Round Data Enhancements
- Multi-pass rounds with distance changes (York: 100/80/60yd)
- Distance unit awareness (yards vs meters in display)
- Governing body tags on rounds

---

## UI Acknowledgement Required

When displaying handicap or classification data derived from archeryutils formulas:

> Add acknowledgement in user profile or main menu footer:
> "Handicap calculations based on [archeryutils](https://github.com/jatkinson1000/archeryutils)"

---

*This document should be expanded as more domain knowledge emerges.*

*Primary source: Patrick Huston, Olympic archer.*

*Technical data derived from [archeryutils](https://github.com/jatkinson1000/archeryutils) by Jack Atkinson et al., MIT License.*

# OLY Bow Training System - Technical Specification

**Author:** Patrick Huston
**Version:** 1.0
**Last Updated:** January 2026

---

## Table of Contents
1. [Overview](#overview)
2. [Training Tracks](#training-tracks)
3. [Session Structure](#session-structure)
4. [Exercise Types](#exercise-types)
5. [Progression System](#progression-system)
6. [Assessment & Entry](#assessment--entry)
7. [Feedback & Adaptation](#feedback--adaptation)
8. [Regression Logic](#regression-logic)
9. [Endurance Training](#endurance-training)
10. [Light Bow Training](#light-bow-training)
11. [Warm-up & Cool-down](#warm-up--cool-down)
12. [Technique Cues](#technique-cues)
13. [Custom Session Builder](#custom-session-builder)
14. [Algorithms](#algorithms)
15. [Data Model](#data-model)

---

## Overview

The OLY Bow Training System is a progressive strength and endurance training program for archers. It uses an **elbow sling** (not fingers on string) to safely build holding capacity without reinforcing poor string hand habits.

### Core Principles
- **Progressive overload**: Gradual increase in volume, duration, and work ratio
- **Adaptive difficulty**: System adjusts based on user feedback
- **Safety first**: Mandatory warm-up, regression on form breakdown
- **Multiple bow support**: Different training intensities for competition vs trainer bows

### Key Metrics
- **Volume Load**: `reps × work_seconds × poundage × intensity_multiplier`
- **Work Ratio**: `total_work_seconds / total_rest_seconds`
- **Adjusted Volume**: Volume load accounting for exercise intensity multipliers

---

## Training Tracks

### 1. Elbow Sling Training (Recommended)
- Uses elbow strap connection to bow
- Fingertips touch string lightly (no load on fingers)
- Full OLY progression system (Levels 0.3 → 2.5+)
- 26-week guided program available
- **Recommended for all archers**

### 2. Finger SPT (Advanced)
- Traditional fingers-on-string holding
- **Warning required**: "Finger SPT requires good string hand technique. Poor habits can be reinforced. Recommended only if you have a solid, consistent hook and have worked with a coach on your string hand."
- Simpler session templates (not full progression)
- Not part of guided program
- Separate section with "Advanced" label

---

## Session Structure

Each session consists of:
1. **Warm-up block** (optional but recommended)
2. **Exercise blocks** (holds, movements, etc.)
3. **Breaks** (longer rest periods between exercise groups)
4. **Cool-down block** (optional)

### Session Metadata
```
Session {
  version: "1.5"           // Level identifier
  name: "Session 1.5"
  focus: "Increased holds"
  duration_minutes: 15.6
  volume_load: 19684
  adjusted_volume_load: 21480
  work_ratio: 0.654
  adjusted_work_ratio: 0.713
  requirements: "Minimum 3 weeks at previous level"
  equipment: "Bow, elbow sling, stabilisers"
}
```

### Exercise Block Structure
```
Exercise {
  type: "Static reversals" | "Back end movement" | etc.
  details: "1cm each way 3x5s"
  reps: 3
  work_seconds: 15
  rest_seconds: 25
  intensity_multiplier: 1.3

  // Calculated
  work_total: reps × work_seconds = 45
  rest_total: reps × rest_seconds = 75
  intensity_total: work_total × intensity = 58.5
  volume_load: work_total × poundage = 2394
  adjusted_volume_load: volume_load × intensity = 3112.2
}
```

---

## Exercise Types

| Exercise | Description | Intensity | Category |
|----------|-------------|-----------|----------|
| Static reversals | Simple hold with elbow sling. Fingertips just touch string. | 1.0 | static |
| Extend front | Push front end forward towards target and hold | 1.1 | movement |
| Extend front movement | Push front end towards target, relax, push again | 1.15 | movement |
| Hold with back end movement | Move string end back and forth. Movement from elbow. | 1.3 | movement |
| Back end movement | 1cm each way, controlled | 1.3 | movement |
| Full front extension | Push front end as far forward as possible and hold | 1.15 | movement |
| Long hold | Stay at full draw as long as possible. Maintain form. Shaking OK. | 1.0 | hold |
| Fast movement both sides | Pump both ends quickly. Big movements. | 1.1 | movement |
| Slow movement | Controlled movement as prescribed | 1.2 | movement |
| Front end expansion aimed | Using sight pin, expand off front keeping pin on fixed point | 1.25 | aimed |
| Back end expansion aimed | Expand on back end while maintaining front end fixed on aim | 1.4 | aimed |
| Both sides expansion aimed | Expand both ends while maintaining aim | 1.45 | aimed |

### Intensity Multipliers Explained
- **1.0** = Baseline static hold
- **1.1-1.15** = Light movement or extension
- **1.2-1.3** = Moderate movement complexity
- **1.4-1.45** = Aimed work (highest difficulty per second)

---

## Progression System

### Level Overview (from spreadsheets)

| Level | Focus | Duration | Volume Load | Work Ratio | % of Level 1.0 |
|-------|-------|----------|-------------|------------|----------------|
| 0.3 | Complete novice | ~2.5 min | ~3000 | ~0.3 | ~18% |
| 0.5 | Building basics | ~5 min | ~6000 | ~0.35 | ~36% |
| 0.7 | Foundation | ~10 min | ~12000 | ~0.45 | ~72% |
| 1.0 | Intro | 14.8 min | 16758 | 0.548 | 100% |
| 1.1 | Movement intro | 14.1 min | 16838 | 0.581 | 100.5% |
| 1.2 | Increasing hold time | 14.9 min | 17556 | 0.628 | 104.8% |
| 1.3 | Slight intensity increase | 20.0 min | 23248 | 0.553 | 138.7% |
| 1.4 | Both sides movement | 20.1 min | 25563 | 0.636 | 152.5% |
| 1.5 | Increased holds | 15.6 min | 21480 | 0.713 | 128.2% |
| 1.6 | Hold time/front end | 17.3 min | 22916 | 0.678 | 136.8% |
| 1.7 | Increasing volume | 21.2 min | 28396 | 0.692 | 169.4% |
| 1.8 | Work ratio increase | 19.6 min | 31920 | 1.042 | 190.5% |
| 1.9 | Volume load increase | 26.5 min | 44688 | 1.119 | 266.7% |
| 2.0 | 30 minute session | 30.5 min | 50540 | 1.067 | 301.6% |
| 2.1 | 30 min with movements | 30.6 min | 52814 | 1.073 | 315.2% |
| 2.2 | Slight increase | 29.3 min | 54211 | 1.272 | 323.5% |
| 2.3 | Movement control | 29.7 min | 54583 | 1.281 | 325.7% |
| 2.4 | Movement then ratio change | 31.2 min | 57243 | 1.272 | 341.6% |
| 2.5 | Aiming intro | 30.0 min | 55488 | 1.146 | 331.1% |

### 26-Week Guided Program

```
Week 1:  Mon: 1.0  |  Wed: 1.1  |  Fri: 1.0
Week 2:  Mon: 1.0  |  Wed: 1.1  |  Fri: 1.1
Week 3:  Mon: 1.1  |  Wed: 1.0  |  Fri: 1.2
Week 4:  Mon: 1.1  |  Wed: 1.2  |  Fri: 1.2
Week 5:  Mon: 1.3  |  Wed: 1.2  |  Fri: 1.3
Week 6:  Mon: 1.0  |  Wed: --   |  Fri: 1.1  [DELOAD]
Week 7:  Mon: 1.4  |  Wed: 1.3  |  Fri: 1.4
Week 8:  Mon: 1.3  |  Wed: 1.4  |  Fri: 1.5
Week 9:  Mon: 1.4  |  Wed: 1.2  |  Fri: 1.5
Week 10: Mon: 1.5  |  Wed: 1.5  |  Fri: 1.5
Week 11: Mon: 1.6  |  Wed: --   |  Fri: --   [DELOAD]
Week 12: Mon: 1.5  |  Wed: 1.6  |  Fri: 1.5
Week 13: Mon: 1.6  |  Wed: 1.7  |  Fri: 1.6
Week 14: Mon: 1.7  |  Wed: 1.7  |  Fri: 1.8
Week 15: Mon: 1.7  |  Wed: 1.8  |  Fri: 1.7
Week 16: Mon: 1.8  |  Wed: --   |  Fri: --   [DELOAD]
Week 17: Mon: 1.0  |  Wed: 1.9  |  Fri: 1.9
Week 18: Mon: 1.8  |  Wed: 1.9  |  Fri: 1.8
Week 19: Mon: 1.8  |  Wed: 1.9  |  Fri: 1.9
Week 20: Mon: 1.6  |  Wed: 1.9  |  Fri: 1.9
Week 21: Mon: --   |  Wed: 1.2  |  Fri: --   [DELOAD]
Week 22: Mon: 1.9  |  Wed: 1.8  |  Fri: 2.0
Week 23: Mon: 1.8  |  Wed: 2.0  |  Fri: 2.0
Week 24: Mon: 1.7  |  Wed: 1.9  |  Fri: 2.0
Week 25: Mon: 2.1  |  Wed: 2.0  |  Fri: 2.1
Week 26: Mon: 2.1  |  Wed: --   |  Fri: 1.0  [DELOAD]
```

**Key patterns:**
- 3 sessions per week (Mon/Wed/Fri)
- Deload weeks every 4-6 weeks
- Strategic regression (e.g., Week 17 starts with 1.0)
- Gradual progression with consolidation phases

---

## Assessment & Entry

### Initial Assessment Flow

1. **Mandatory Warm-up**
   - User must complete Standard warm-up (2.5 min) minimum
   - Safety messaging displayed before test

2. **Max Hold Test**
   - Single hold, maintaining form
   - Timer counts up
   - User taps when they let down
   - Record time

3. **Starting Level Assignment**

```
if max_hold < 8s:
    start_level = 0.3
    message = "Starting point for complete bow training novices"
elif max_hold < 12s:
    start_level = 0.5
elif max_hold < 18s:
    start_level = 0.7
elif max_hold < 25s:
    start_level = 1.0
else:
    start_level = 1.3  // or higher based on time
```

4. **User Override**
   - User can select different level if they prefer
   - System tracks their choice

---

## Feedback & Adaptation

### Post-Session Feedback (3 Scales, 1-10)

**1. Shaking Level**
- 1 = No shaking at all
- 5 = Moderate shaking, manageable
- 10 = Severe shaking, struggled to hold

**2. Structure Maintenance**
- 1 = Perfect form throughout
- 5 = Some form breakdown toward end
- 10 = Couldn't maintain structure

**3. Rest Adequacy**
- 1 = Way too much rest, fully recovered
- 5 = About right
- 10 = Not nearly enough rest, still exhausted

### Adaptation Algorithm

```python
def suggest_next_session(feedback, completion_rate):
    avg_score = (feedback.shaking + feedback.structure + feedback.rest) / 3
    max_score = max(feedback.shaking, feedback.structure, feedback.rest)

    # Progress conditions
    if avg_score < 4 and completion_rate == 1.0:
        return "progress"  # Suggest next level

    # Regress conditions
    if max_score > 7 or avg_score > 6 or completion_rate < 0.8:
        return "regress"  # Suggest easier level

    # Repeat conditions (good training zone)
    return "repeat"  # Stay at current level
```

---

## Regression Logic

### Automatic Triggers

| Trigger | Action |
|---------|--------|
| Session completion < 70% | Suggest repeat current level |
| Any feedback scale > 7 | Suggest drop 1 level |
| Average feedback > 6 | Suggest drop 1 level |
| 2+ consecutive missed sessions | Drop 1 level |
| 7+ days since last session | Suggest reassessment |
| 14+ days since last session | Drop 2 levels or reassess |

### Manual Controls
- "I need to go easier" button → Drop 1 level
- "I want more challenge" button → Advance 1 level
- Direct level selection always available

### Recovery from Regression
- After 3 successful sessions at regressed level → suggest original level
- System tracks regression history to avoid yo-yoing

---

## Endurance Training

### Unlock Threshold
User can comfortably complete: **20s holds with 40s rest for 10 minutes**

### Purpose
Build stamina for competition (2+ hour events) where form must be maintained throughout.

### Structure
- Duration: 20-30 minutes
- Lower work-to-rest ratio than normal progression
- Longer breaks between set groups
- Focus on consistency over intensity

### Endurance Templates

**Endurance 1 (20 min)**
```
15s hold / 45s rest × 15 sets
Break: 2 min at set 8
Focus: Consistent form over duration
```

**Endurance 2 (25 min)**
```
20s hold / 50s rest × 12 sets
Break: 2 min at sets 6 and 10
Focus: Moderate holds, long recovery
```

**Endurance 3 (30 min)**
```
20s hold / 40s rest × 18 sets
Break: 3 min at sets 9 and 15
Focus: Higher volume, competition simulation
```

### Scheduling
Once threshold reached: 1 endurance session per week
```
Mon: Normal session (e.g., Level 1.5)
Wed: Endurance session
Fri: Normal session (e.g., Level 1.5)
```

---

## Light Bow Training

### Concept
Users can train at dramatically higher volumes using a lighter "trainer" bow. What would be maximal on competition bow becomes moderate on light bow.

### Real Example
- Competition bow (53.2 lbs): 5 min at 30:30 = standard warm-up session
- Trainer bow (~22 lbs): 25 min at 30:30 = equivalent effort
- **Ratio: ~5x volume possible at ~40% poundage**

Note: At higher levels, a 10 min session at 30:30 on comp bow needs a rest day to recover (unless a 120s break is included mid-session).

### Bow Profiles
```
BowProfile {
  id: "comp_bow_1"
  name: "Competition"
  poundage: 53.2
  is_primary: true
}

BowProfile {
  id: "trainer_1"
  name: "Trainer"
  poundage: 22.0
  is_primary: false
}
```

### Volume Scaling Algorithm

```python
def get_unlocked_duration(user_level, comp_bow, trainer_bow):
    base_duration = get_session_duration(user_level)
    weight_ratio = comp_bow.poundage / trainer_bow.poundage
    unlocked_duration = base_duration * weight_ratio
    return unlocked_duration

# Example:
# User at Level 1.5 (15 min) on 53 lb bow
# Trainer bow is 22 lbs
# Unlocked: 15 × (53/22) = 36 min
# User can access sessions up to ~35-40 min on trainer bow
```

### Session Selection Flow
1. "Which bow are you using?" → Select from profiles
2. If trainer bow selected → Show expanded session options
3. Sessions beyond normal progression become available
4. Clear labeling: "Level 2.3 - accessible on your trainer bow"

### Logging Rules
- Light bow sessions logged with bow identifier
- **Do not count toward competition bow progression**
- Show in history: "Level 2.3 (Trainer - 22 lbs)"
- Track light bow volume separately for fatigue management

---

## Warm-up & Cool-down

### Warm-up Routines

**Quick (45 seconds)**
```
- Arm circles x10 each direction (15s)
- Shoulder shrugs x10 (10s)
- Neck rotations (10s)
- 3 deep breaths (10s)
```

**Standard (2.5 minutes)**
```
- Arm circles x10 each direction (15s)
- Shoulder shrugs x10 (10s)
- Band pull-aparts x15 (20s)
- Band external rotations x10 each (30s)
- Thoracic rotations x5 each side (20s)
- Bow raises (no draw) x5 (15s)
- Light draws to half x3 (30s)
- 3 deep breaths (10s)
```

**Full (8 minutes)**
```
- Arm circles x15 each direction (20s)
- Shoulder shrugs x15 (15s)
- Band pull-aparts x20 (30s)
- Band external rotations x15 each (45s)
- Band face pulls x15 (30s)
- Thoracic rotations x8 each side (30s)
- Cat-cow stretches x8 (30s)
- Hip circles x10 each (20s)
- Bow raises (no draw) x8 (25s)
- Light draws to half x5 (45s)
- Light draws to full (let down) x3 (60s)
- Reversals at light tension x3 (60s)
- Mental focus/visualization (30s)
```

### Cool-down Options
- **Guided**: Specific stretches and recovery activities
- **Timer only**: Simple countdown, user does own routine
- **User choice**: Toggle between modes per session

---

## Technique Cues

Cues displayed during holds to reinforce form.

### Cue Library

| Cue | Category |
|-----|----------|
| Shoulders/neck relaxed | setup |
| Look forward without neck tension | setup |
| Keep your core engaged | setup |
| Draw the bow using your whole body | draw |
| Engage into the ground | setup |
| Press your feet/toes into the ground | setup |
| Keep your draw arm/bicep relaxed | draw |
| Connect up the whole body | hold |
| Elastic force not muscles, move smoothly | movement |
| Move the bones | movement |
| Expand into the line of the shot | hold |
| Use string picture on sight or riser | aimed |
| Balance the forces | hold |
| Keep your centre of mass still | hold |
| Drive movement from the feet | movement |

### Display Timing
- Cues appear **during the hold phase**
- One cue per hold (rotates through selected cues)
- User can select which cues to include in session

---

## Custom Session Builder

### Block Types
1. **Warm-up** - Quick/Standard/Full
2. **Exercise** - Any exercise type with custom parameters
3. **Cool-down** - Guided or timer-only
4. **Technique Cue** - Selected from library

### Builder Interface
- Tap "+" to add block
- Select block type from modal
- Configure parameters (reps, work time, rest time)
- Drag to reorder (long press + drag)
- Swipe to delete
- Medium card size (5-6 visible)

### Exercise Configuration
```
Exercise Block {
  type: ExerciseType
  reps: 1-30
  work_seconds: 5-120 (5s increments)
  rest_seconds: 0-120 (5s increments)
  details: optional text
}
```

### Saving & Usage
- Save as named session to "My Sessions"
- Usage tracking: count + last used timestamp
- Sorting: Combined score of frequency × recency

### Usage Score Algorithm
```python
def usage_score(session):
    frequency_weight = 0.6
    recency_weight = 0.4

    # Normalize frequency (0-1 based on max usage in collection)
    freq_normalized = session.usage_count / max_usage_count

    # Recency: days since last use, decaying
    days_ago = (now - session.last_used).days
    recency_normalized = 1.0 / (1 + days_ago * 0.1)

    return (frequency_weight * freq_normalized) + (recency_weight * recency_normalized)
```

---

## Algorithms

### Dynamic Level Generation (Below 1.0)

For users who can't start at Level 1.0, generate intermediate sessions:

```python
def generate_dynamic_session(target_duration_min, user_max_hold):
    # Base parameters
    hold_time = min(user_max_hold * 0.6, 15)  # 60% of max, cap at 15s
    rest_time = hold_time * 2.5  # 2.5:1 rest ratio for beginners

    # Calculate sets to fill duration
    set_duration = hold_time + rest_time
    num_sets = int((target_duration_min * 60) / set_duration)

    return DynamicSession(
        hold_seconds=hold_time,
        rest_seconds=rest_time,
        sets=num_sets,
        exercise_type="Static reversals"
    )
```

### Progression Decision Tree

```
START
  │
  ├── Session completed?
  │   ├── No (< 80%) → REGRESS
  │   └── Yes → Continue
  │
  ├── Any feedback score > 7?
  │   ├── Yes → REGRESS
  │   └── No → Continue
  │
  ├── Average score > 6?
  │   ├── Yes → REGRESS
  │   └── No → Continue
  │
  ├── Average score < 4?
  │   ├── Yes → PROGRESS
  │   └── No → REPEAT
  │
END
```

### Rest Week Scheduling

```python
def should_schedule_rest_week(current_week, recent_sessions):
    # Every 4-6 weeks
    weeks_since_rest = current_week - last_rest_week

    if weeks_since_rest >= 6:
        return True

    if weeks_since_rest >= 4:
        # Check if recent feedback suggests fatigue
        avg_recent_feedback = average(recent_sessions[-6:].feedback)
        if avg_recent_feedback > 5:
            return True

    return False
```

---

## Data Model

### Core Tables

```sql
-- Bow profiles
CREATE TABLE bow_profiles (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    poundage REAL NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at DATETIME,
    updated_at DATETIME
);

-- Exercise types
CREATE TABLE exercise_types (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    intensity_multiplier REAL DEFAULT 1.0,
    category TEXT,  -- 'static', 'movement', 'aimed', 'hold'
    sort_order INTEGER
);

-- Session templates (1.0 → 2.5)
CREATE TABLE session_templates (
    id TEXT PRIMARY KEY,
    version TEXT NOT NULL,  -- '1.0', '1.5', etc.
    name TEXT NOT NULL,
    focus TEXT,
    duration_minutes INTEGER,
    volume_load INTEGER,
    work_ratio REAL,
    requirements TEXT,
    sort_order INTEGER
);

-- Exercises within templates
CREATE TABLE session_template_exercises (
    id TEXT PRIMARY KEY,
    session_template_id TEXT REFERENCES session_templates(id),
    exercise_type_id TEXT REFERENCES exercise_types(id),
    exercise_order INTEGER,
    reps INTEGER,
    work_seconds INTEGER,
    rest_seconds INTEGER,
    details TEXT
);

-- User's program enrollment
CREATE TABLE user_program (
    id TEXT PRIMARY KEY,
    start_date DATETIME,
    current_week INTEGER DEFAULT 1,
    current_level TEXT DEFAULT '1.0',
    bow_profile_id TEXT REFERENCES bow_profiles(id),
    is_active BOOLEAN DEFAULT TRUE
);

-- Session logs
CREATE TABLE bow_training_logs (
    id TEXT PRIMARY KEY,
    session_template_id TEXT,
    bow_profile_id TEXT REFERENCES bow_profiles(id),
    planned_duration_seconds INTEGER,
    actual_duration_seconds INTEGER,
    planned_sets INTEGER,
    completed_sets INTEGER,
    feedback_shaking INTEGER,  -- 1-10
    feedback_structure INTEGER,  -- 1-10
    feedback_rest INTEGER,  -- 1-10
    notes TEXT,
    started_at DATETIME,
    completed_at DATETIME
);

-- Custom sessions
CREATE TABLE custom_sessions (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    usage_count INTEGER DEFAULT 0,
    last_used_at DATETIME,
    created_at DATETIME
);

-- Blocks in custom sessions
CREATE TABLE custom_session_blocks (
    id TEXT PRIMARY KEY,
    custom_session_id TEXT REFERENCES custom_sessions(id),
    block_order INTEGER,
    block_type TEXT,  -- 'warmup', 'exercise', 'cooldown', 'cue'
    exercise_type_id TEXT,
    reps INTEGER,
    work_seconds INTEGER,
    rest_seconds INTEGER,
    cue_text TEXT,
    warmup_type TEXT  -- 'quick', 'standard', 'full'
);

-- Technique cues library
CREATE TABLE technique_cues (
    id TEXT PRIMARY KEY,
    cue_text TEXT NOT NULL,
    category TEXT,
    sort_order INTEGER
);

-- Warm-up activities
CREATE TABLE warmup_activities (
    id TEXT PRIMARY KEY,
    warmup_type TEXT,  -- 'quick', 'standard', 'full'
    activity_order INTEGER,
    activity TEXT,
    duration_seconds INTEGER
);
```

---

## Appendix: Session Examples

### Session 1.0 (from spreadsheet)
```
Duration: 14.8 min
Volume Load: 16758
Work Ratio: 0.548
Focus: First session, attempt to stick to times

Exercises:
1. Static reversals    | 5 reps | 10s hold | 25s rest | intensity 1.0
2. Static reversals    | 5 reps | 15s hold | 30s rest | intensity 1.0
3. Static, extend front| 5 reps | 10s hold | 20s rest | intensity 1.1
4. Static reversals    | 5 reps | 15s hold | 25s rest | intensity 1.0
5. Static reversals    | 3 reps | 10s hold | 25s rest | intensity 1.0
6. Static hold (long)  | 1 rep  | 30s hold | 0s rest  | intensity 1.0
```

### Session 1.5 (from spreadsheet)
```
Duration: 15.6 min
Volume Load: 21480
Work Ratio: 0.713
Focus: Increased holds
Requirements: Minimum 3 weeks at previous levels

Exercises:
1. Static reversals       | 3 reps | 20s hold | 30s rest | intensity 1.0
2. Static reversals       | 2 reps | 10s hold | 20s rest | intensity 1.0
3. Extend Front movement  | 3 reps | 15s hold | 25s rest | intensity 1.15
4. Static reversals       | 2 reps | 20s hold | 30s rest | intensity 1.0
5. Back end movement      | 3 reps | 15s hold | 25s rest | intensity 1.3
6. Static reversals       | 2 reps | 20s hold | 30s rest | intensity 1.0
7. Extend front movement  | 3 reps | 15s hold | 30s rest | intensity 1.3
8. Static reversals       | 3 reps | 15s hold | 25s rest | intensity 1.0
9. Long hold              | 1 rep  | 30s hold | 0s rest  | intensity 1.0
```

### Session 2.5 (from spreadsheet)
```
Duration: 30.0 min
Volume Load: 55488
Work Ratio: 1.146
Focus: Aiming intro
Requirements: Be comfortable with S1.5, 1.6

Exercises:
1. Static reversals              | 3 reps | 20s hold | 20s rest | intensity 1.0
2. Static reversals              | 2 reps | 30s hold | 25s rest | intensity 1.0
3. Front end extension, aimed    | 3 reps | 20s hold | 30s rest | intensity 1.25
4. Back end expansion, aimed     | 3 reps | 20s hold | 30s rest | intensity 1.4
5. Static                        | 3 reps | 30s hold | 25s rest | intensity 1.0
6. Both sides expansion aimed    | 5 reps | 20s hold | 20s rest | intensity 1.45
7. Slow expansion to far as poss | 3 reps | 30s hold | 25s rest | intensity 1.3
8. Static                        | 3 reps | 20s hold | 20s rest | intensity 1.0
9. Big, balanced movement both   | 5 reps | 30s hold | 30s rest | intensity 1.2
10. Static                       | 2 reps | 20s hold | 20s rest | intensity 1.0
11. Slow steady expansion        | 3 reps | 20s hold | 20s rest | intensity 1.2
12. Static                       | 2 reps | 30s hold | 30s rest | intensity 1.0
```

---

*Property of the OLY Training System, a trading style of Patrick Huston Ltd. Copyright Patrick Huston.*

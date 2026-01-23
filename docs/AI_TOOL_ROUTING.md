# AI Tool Routing Guide

Quick reference: Which AI tool for which job?

## The Simple Rule

**Z.ai** = Assembly line worker (fast, cheap, follows patterns)
**Claude Opus** = Senior architect (expensive, thinks deeply)

---

## Use Z.ai For (Cheap/Fast)

### ✅ Pattern-following work
- "Add another field like the existing ones"
- "Create a new screen that looks like [existing screen]"
- "Copy this pattern to a new file"

### ✅ Clear, specific fixes
- Error message says exactly what's wrong
- "Change this text from X to Y"
- "Move this button to the left"
- "Make this color gold instead of blue"

### ✅ Mechanical tasks
- Renaming variables/files
- Adding imports
- Formatting code
- Writing simple tests that follow existing test patterns
- Documentation updates

### ✅ Git housekeeping
- Commits, branches, status checks
- Simple merges

### ✅ When you can describe EXACTLY what you want
- "Add a cancel button that calls Navigator.pop()"
- "Show loading spinner while fetching"

---

## Use Claude Opus For (Worth the cost)

### 🧠 "I don't know what's wrong"
- Bug with no clear error message
- "It's just not working right"
- Intermittent/flaky issues

### 🧠 "I don't know how to do this"
- New feature with no existing pattern to copy
- Integrating a new service/library
- "What's the best way to..."

### 🧠 Architecture & design
- "Should I do it this way or that way?"
- Decisions that affect multiple parts of the app
- Database schema changes
- State management questions

### 🧠 When Z.ai is stuck or wrong
- Gave you broken code twice
- Going in circles
- Clearly doesn't understand the problem

### 🧠 Security-sensitive code
- Auth, payments, user data
- Anything that could leak or break badly

### 🧠 Performance problems
- "The app is slow" (needs investigation)
- Memory issues, battery drain

### 🧠 Complex debugging
- Issue spans multiple files
- Need to understand how systems interact

---

## Quick Decision Tree

```
START
  │
  ├─ Can you describe EXACTLY what change you want?
  │   ├─ YES → Does similar code already exist to copy?
  │   │         ├─ YES → Z.ai ✓
  │   │         └─ NO → Claude Opus
  │   └─ NO → Claude Opus
  │
  ├─ Is it a bug fix?
  │   ├─ Error message is clear → Z.ai ✓
  │   └─ "Something's wrong but IDK what" → Claude Opus
  │
  ├─ Does it touch auth/payments/security?
  │   └─ YES → Claude Opus
  │
  ├─ Is it purely cosmetic (colors, text, spacing)?
  │   └─ YES → Z.ai ✓
  │
  └─ Did Z.ai already fail at this twice?
      └─ YES → Claude Opus
```

---

## Examples from This Project

| Task | Tool | Why |
|------|------|-----|
| "Add a notes field to the session log" | Z.ai | Pattern exists, just copy it |
| "Why aren't scores saving?" | Opus | Debugging, unclear cause |
| "Change gold color to brighter" | Z.ai | Simple, specific |
| "Design offline sync system" | Opus | Architecture decision |
| "Add test for new button" | Z.ai | Follow existing test patterns |
| "Fix flaky test" | Opus | Investigation needed |
| "Rename ScoreCard to ScoreSheet" | Z.ai | Mechanical refactor |
| "Add Stripe integration" | Opus | New library, security |

---

## Cost Reality Check

Think of it like this:
- Z.ai = £0.01 per task (estimate)
- Opus = £0.10-0.50 per task (estimate)

Using Z.ai for 10 simple tasks = ~£0.10
Using Opus for those same 10 = ~£2-5

**Save Opus for the 20% of work that actually needs it.**

---

## When In Doubt

Ask yourself: "Is this following a recipe, or figuring out what recipe to use?"

- Following recipe → Z.ai
- Figuring out recipe → Claude Opus

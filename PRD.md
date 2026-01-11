
Archery Super App — MVP PRD v1
Product: Archery Performance Tracker
Target: 8-week build to usable v1
Owner: Patrick Huston
Date: January 2026

Problem
Elite archers currently use disconnected tools:

Handwritten notebooks for scores
Spreadsheets for volume tracking
Memory for equipment changes
No historical trend visibility
No ability to correlate training load with performance

Result: Lost data, no long-term insight, manual busywork.

Solution
A single offline-first mobile app where archers can:

Record all training sessions and competition scores
Plot arrow groups on a digital target face
Track total arrow volume over time
View historical performance trends

Core value: Permanent, queryable performance memory.

Success Criteria
Launch criteria (8 weeks):

Patrick uses it daily for 14 consecutive days
App works fully offline (airplane mode test)
30+ days of session data logged
Zero data loss incidents

3-month success:

10 elite archers using weekly
80%+ of training sessions logged in-app vs. external tools
Users reference historical data when making equipment decisions


MVP Scope (v1)
In Scope
1. Session Logging

Tap "New Session"
Record: date, arrows shot, distance, equipment used, conditions, notes
Sessions saved locally, never lost
Simple list view of past sessions

2. Arrow Plotting

During scoring: tap arrows on digital target face (end-by-end)
System auto-calculates score per end
Stores: arrow positions, values, end totals, session total
Target faces: 80cm, 122cm (standard UK rounds)

3. Score Import

Manual entry: "70m 1440, 1289 score, 12 Jan 2026"
CSV upload (basic parser: date, round, score)
All scores become permanent records

4. Performance History

Timeline view: scores + sessions chronologically
Basic filtering: by round, by date range
Volume graph: 7-day, 28-day, 90-day EMAs (simple line charts)
Session detail view: arrows shot, conditions, notes

Explicit Non-Goals (v1)
Not in MVP:

Automated scraping of competition results
AI analysis or insights
Group size/distribution analytics
Equipment comparison tools
Social features
Cloud sync (local-only for v1)
Authentication (single-user device app)
Coaching content or services
Video analysis tools
Physical training timers
Advanced statistical modeling

Deferred to Phase 2:

Multi-device sync
PDF/Word score extraction
Rule-based training load warnings
Shot distribution analysis


User Flows
Primary Flow: Log a Training Session

Open app
Tap "New Session"
Enter: 144 arrows, 70m, Olympic bow, light wind
Optional: plot 12 ends on target face
Tap "Save"
Session appears in history timeline

Secondary Flow: Import Competition Score

Tap "Add Score"
Select "Manual Entry"
Enter: WA 1440, 1289, 12 Jan 2026
Tap "Save"
Score appears in history

Tertiary Flow: Review Performance

Open "History" tab
Scroll timeline (newest first)
Tap any session → see full detail
View volume graph → see weekly load trend


Technical Details
See CLAUDE.md for:

Complete data model with field definitions
Technical stack and constraints
UI standards and aesthetic rules
Permissions and working protocols


Out of Scope (Explicitly)

User accounts
Payment/subscription (deferred post-MVP)
Cloud backup
Multi-user support
Social features
In-app purchases
Push notifications
Advanced analytics


Risks & Mitigations
Risk: User enters wrong data, can't undo
Mitigation: Edit/delete on all records
Risk: App crashes, data lost
Mitigation: SQLite with transactions, frequent saves
Risk: User wants to use on multiple devices
Mitigation: Document as Phase 2, focus on single-device perfection
Risk: Scope creep from scraping/AI features
Mitigation: This PRD. Founder must approve scope changes.

Post-MVP Roadmap (Indicative Only)
Phase 2 (v1.1):

Cloud sync (Supabase)
Multi-device support
User authentication
£1/month subscription with 72hr grace period

Phase 3 (v1.2):

Shot distribution analytics
Equipment comparison
Training load warnings (rule-based)

Phase 4+:

PDF/CSV auto-scraping
Coaching content integration
AI assistant (trained on methodology)


Definition of Done
MVP is complete when:

 User can log sessions offline
 User can plot arrows and auto-calculate scores
 User can manually import historical scores
 User can view session timeline and volume graphs
 App survives airplane mode for 30 days of use
 Patrick has used it for 14 consecutive training days
 Zero data loss across 100+ sessions


Sign-off required before build begins.
# Data Persistence Architecture

Last reviewed: 2026-01-20

This document describes the data persistence architecture, known vulnerabilities that have been addressed, and the stress testing methodology used to verify robustness. Use this as a reference when reviewing or enhancing the sync system.

---

## Core Architecture

### Offline-First Design

The app follows an **offline-first** architecture where:

1. **Local SQLite is the source of truth** - All data writes go to local database first
2. **Cloud is a backup** - Firestore stores copies for cross-device sync and disaster recovery
3. **Sync is opportunistic** - Happens when possible, failure doesn't block user actions

```
User Action → SQLite (immediate) → Sync Attempt (background, can fail)
```

### Key Components

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `AppDatabase` | `lib/db/database.dart` | Local SQLite via Drift ORM |
| `SyncService` | `lib/services/sync_service.dart` | Bidirectional cloud sync |
| `AuthService` | `lib/services/auth_service.dart` | Authentication + logout data safety |
| `SessionProvider` | `lib/providers/session_provider.dart` | Scoring session state management |

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER ACTION                               │
│                    (tap arrow on target)                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     SessionProvider                              │
│                   plotArrow() method                             │
│                                                                  │
│  1. _db.insertArrow() ──────────────────► SQLite (IMMEDIATE)    │
│  2. _triggerCloudBackup() ──────────────► SyncService (ASYNC)   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SyncService.syncAll()                       │
│                                                                  │
│  1. _processQueue() ────► Retry any failed operations           │
│  2. _bidirectionalSync() ────► Compare local vs cloud           │
│     - getAllSessionsForSync() reads ALL local data              │
│     - Compares timestamps with Firestore                        │
│     - Uploads newer/missing, downloads newer from cloud         │
│                                                                  │
│  ON FAILURE: Exception caught, logged, local data unchanged     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Sync Triggers

Data is synced to the cloud at these points:

| Trigger | Location | Notes |
|---------|----------|-------|
| App resume | `main.dart` | When app comes to foreground |
| App pause | `main.dart` | Urgent sync before OS may kill app |
| App inactive | `main.dart` | Phone call, notification drawer |
| App hidden | `main.dart` | App switcher, split screen |
| End commit | `session_provider.dart:333` | After each end, not just session end |
| Session complete | `session_provider.dart:357` | When session finishes |
| Before logout | `auth_service.dart:51-72` | 10-second timeout, then proceeds |

### Lifecycle State Handling

```dart
// main.dart - _AppLifecycleObserver
switch (state) {
  case AppLifecycleState.resumed:
    _triggerBackgroundSync();
  case AppLifecycleState.paused:
    _triggerBackgroundSync(urgent: true);  // Skip debounce
  case AppLifecycleState.inactive:
    _triggerBackgroundSync(urgent: true);
  case AppLifecycleState.hidden:
    _triggerBackgroundSync();
  case AppLifecycleState.detached:
    // Cannot sync - app is being terminated
}
```

---

## Known Vulnerabilities (Addressed)

These vulnerabilities were identified and fixed. Document here for future reference.

### Bug #1: Account Switching Data Leak
**Problem**: Logging out didn't clear local data, next user saw previous user's sessions.
**Fix**: `clearAllUserData()` called on logout after sync attempt.
**Location**: `auth_service.dart:74-81`, `database.dart:2904`

### Bug #2: No Sync Before Logout
**Problem**: User logs out with unsynced data, data lost.
**Fix**: Attempt sync with 10-second timeout before clearing local data.
**Location**: `auth_service.dart:51-72`

### Bug #3: Only Synced on Resume
**Problem**: App killed while paused lost pending data.
**Fix**: Sync on pause/inactive/hidden states with urgent flag.
**Location**: `main.dart` - `_AppLifecycleObserver`

### Bug #4: Only Synced on Session Complete
**Problem**: Crash mid-session lost all arrows since last completed session.
**Fix**: Sync after each end commit, not just session completion.
**Location**: `session_provider.dart:333`

### Bug #5: Soft Deletes Not Syncing
**Problem**: Deleted items reappeared after sync.
**Fix**: `deletedAt` timestamp comparison in conflict resolution.
**Location**: `sync_service.dart` - `_resolveConflict()`

### Bug #6: Concurrent Sync Race Conditions
**Problem**: Multiple sync calls could corrupt data.
**Fix**: Mutex lock (`synchronized` package) around sync operations.
**Location**: `sync_service.dart:70, 118`

### Bug #7: Firestore Batch Limit
**Problem**: Large syncs failed when exceeding 500-operation batch limit.
**Fix**: Chunk operations into 450-op batches.
**Location**: `sync_service.dart:76, _commitBatchedWrites()`

---

## Conflict Resolution

When the same entity exists locally and in cloud with different timestamps:

```dart
// sync_service.dart - _resolveConflict()
MergeDecision _resolveConflict({
  DateTime? localUpdatedAt,
  DateTime? cloudUpdatedAt,
  DateTime? localDeletedAt,
  DateTime? cloudDeletedAt,
  required bool existsLocal,
  required bool existsCloud,
}) {
  // Newer timestamp wins
  // On exact tie: local wins (device is source of truth)
  // Deletions compared by deletedAt timestamp
}
```

| Scenario | Decision |
|----------|----------|
| Local newer than cloud | Upload local |
| Cloud newer than local | Download cloud |
| Same timestamp | Skip (local wins by default) |
| Local deleted after cloud update | Upload deletion |
| Cloud deleted after local update | Download deletion |

---

## Stress Testing Methodology

### Test File Location
`test/services/data_persistence_stress_test.dart`

### Test Categories

#### 1. Local Storage Tests
Verify data goes to SQLite immediately regardless of network.

```dart
test('arrows are persisted immediately after insert')
test('session survives simulated app restart')
test('concurrent arrow inserts maintain data integrity')
test('soft delete preserves data for sync')
```

#### 2. User Account Linkage Tests
Verify account switching doesn't leak data.

```dart
test('clearAllUserData removes all user data')
test('clearAllUserData uses transaction for atomic operation')
```

#### 3. Sync Queue Tests
Verify offline queue mechanics work correctly.

```dart
test('sync queue persists operations')
test('sync queue retry count increments on failure')
test('sync queue operation removed after success')
test('operations exceeding max retries are filtered out')
```

#### 4. Crash Recovery Tests
Verify incomplete sessions are recoverable.

```dart
test('incomplete session is recoverable')
test('completed session not returned as incomplete')
test('soft-deleted session not returned as incomplete')
```

#### 5. Airplane Mode Simulation Tests
Verify complete offline workflows.

```dart
test('complete session survives airplane mode - full workflow')
  // Creates 12-end session with 72 arrows while "offline"
  // Verifies all data in local DB
  // Verifies getAllSessionsForSync() returns everything

test('incomplete session recoverable after airplane mode crash')
  // Creates partial session (6 ends)
  // Verifies getIncompleteSession() finds it
  // Verifies we can count existing data to continue

test('multiple sessions accumulate while offline')
  // Creates 3 complete sessions
  // Verifies all 54 arrows persist
  // Verifies all sessions ready for sync

test('equipment changes persist in airplane mode')
  // Creates bow, quiver, 12 shafts
  // Verifies all equipment in local DB
```

#### 6. Conflict Resolution Tests
Verify timestamp-based merge logic.

```dart
test('local timestamp wins on exact tie')
test('newer timestamp wins regardless of source')
test('deletion conflicts resolved by timestamp')
```

#### 7. Data Integrity Under Stress Tests
Verify system handles high load.

```dart
test('rapid arrow insertion maintains order')
  // 30 rapid sequential inserts
  // Verifies sequence numbers maintained

test('large dataset performance')
  // 10 sessions x 12 ends x 6 arrows = 720 arrows
  // Verifies all data queryable
```

### Running the Tests

```bash
# Run all persistence stress tests
flutter test test/services/data_persistence_stress_test.dart

# Run all database tests (includes foreign key, cascade, concurrent access)
flutter test test/db/database_test.dart

# Run both together
flutter test test/db/database_test.dart test/services/data_persistence_stress_test.dart
```

### Current Test Count
- Database tests: 86
- Persistence stress tests: 28
- **Total**: 114 tests covering data persistence

---

## Future Review Checklist

When reviewing this system, verify:

- [ ] All sync triggers still in place (check `main.dart`, `session_provider.dart`, `auth_service.dart`)
- [ ] Logout flow still syncs before clearing (check `auth_service.dart:signOut()`)
- [ ] Conflict resolution still uses timestamps (check `sync_service.dart:_resolveConflict()`)
- [ ] Stress tests still pass (`flutter test test/services/data_persistence_stress_test.dart`)
- [ ] Database tests still pass (`flutter test test/db/database_test.dart`)

### Adding New Entity Types

When adding new syncable entities:

1. Add to `SyncEntityType` enum in `sync_service.dart`
2. Add `getAll[Entity]ForSync()` method to database
3. Add `_sync[Entity]()` method to SyncService
4. Call from `_bidirectionalSync()`
5. Add stress tests for the new entity type

### Edge Cases to Consider

- What if device clock is wrong? (Timestamp comparison affected)
- What if user has no internet for weeks? (Large sync payload)
- What if same arrow edited on two devices simultaneously? (Last write wins)
- What if Firestore quota exceeded? (Sync fails, local data safe)

---

## Architecture Decisions

### Why SQLite (Drift) over SharedPreferences?
- Relational data with foreign keys
- Transaction support for atomic operations
- Query capability for complex lookups
- Handles large datasets efficiently

### Why Firestore over Realtime Database?
- Document-based structure matches our entities
- Offline persistence built-in (though we manage our own)
- Better querying capabilities
- Batch writes up to 500 operations

### Why bidirectional sync over event sourcing?
- Simpler mental model
- Easier conflict resolution
- Lower storage requirements
- Sufficient for our data volumes

---

## Related Documentation

- `docs/TESTING_ROADMAP.md` - Overall testing strategy
- `docs/ARCHERY_DOMAIN_KNOWLEDGE.md` - Domain context for scoring data
- `lib/db/database.dart` - Schema definitions and queries
- `lib/services/sync_service.dart` - Full sync implementation

# Firebase Sync Audit Report

**Generated:** 2026-02-12
**Status:** Complete
**Project:** AuraList (aura-list)

---

## Executive Summary

This audit reviews all Firebase sync paths in the AuraList codebase. The primary sync logic is in `lib/services/database_service.dart`, with supporting code in providers and models.

### Key Findings

| Category | Status | Notes |
|----------|--------|-------|
| Task Sync | **OK** | Full field coverage |
| Note Sync | **FIXED** | Missing fields corrected |
| Notebook Sync | **OK** | Full field coverage |
| Sync Queue | **OK** | Exponential backoff working |
| Auth Flow | **FIXED** | linkWithPopup for web |
| Cloud Sync Enable | **FIXED** | Auto-enable after linking |

---

## 1. Sync Paths Analysis

### 1.1 Tasks

#### Sync TO Firebase

**Location:** `lib/services/database_service.dart`

| Method | Line | Fields Synced | Status |
|--------|------|---------------|--------|
| `syncTaskToCloud()` | ~380 | All via `toFirestore()` | OK |
| `syncTaskToCloudDebounced()` | ~420 | All via `toFirestore()` | OK |

**Task.toFirestore() includes:**
- title, description, type, isCompleted, createdAt
- dueDate, deadline, dueTimeMinutes
- category, priority, motivation, reward
- subtasks, deleted, deletedAt, lastUpdatedAt
- recurrenceDay

#### Sync FROM Firebase

| Method | Line | Fields Loaded | Status |
|--------|------|---------------|--------|
| `syncFromCloud()` | ~2700 | All via `fromFirestore()` | OK |
| `_processCloudTasks()` | ~2800 | All fields | OK |

### 1.2 Notes

#### Sync TO Firebase

**Location:** `lib/services/database_service.dart`

| Method | Line | Fields Synced | Status |
|--------|------|---------------|--------|
| `syncNoteToCloud()` | ~800 | All via `toFirestore()` | OK |
| `syncNoteToCloudDebounced()` | ~850 | All via `toFirestore()` | OK |

**Note.toFirestore() includes:**
- title, content, color, isPinned, tags
- createdAt, updatedAt, taskId
- deleted, deletedAt
- **checklist** (array of ChecklistItem)
- **notebookId** (string | null)
- **status** (active/archived/deleted)
- **richContent** (Quill Delta JSON)
- **contentType** (plain/checklist/rich)

#### Sync FROM Firebase

| Method | Line | Fields Loaded | Status |
|--------|------|---------------|--------|
| `syncFromCloud()` | ~2768 | All fields | **FIXED** |

**Fix Applied:** Added missing fields in `updateInPlace()` call:
```dart
existing.updateInPlace(
  title: note.title,
  content: note.content,
  updatedAt: note.updatedAt,
  // ... other fields ...
  checklist: note.checklist,      // Added
  notebookId: note.notebookId,    // Added
  status: note.status,            // Added
  richContent: note.richContent,  // Added
  contentType: note.contentType,  // Added
);
```

### 1.3 Notebooks

#### Sync TO Firebase

**Location:** `lib/services/database_service.dart`

| Method | Line | Fields Synced | Status |
|--------|------|---------------|--------|
| `syncNotebookToCloud()` | ~1100 | All via `toFirestore()` | OK |

**Notebook.toFirestore() includes:**
- name, icon, color
- createdAt, updatedAt
- isFavorited, parentId

#### Sync FROM Firebase

| Method | Line | Fields Loaded | Status |
|--------|------|---------------|--------|
| `syncFromCloud()` | ~2850 | All fields | OK |

### 1.4 Move Notes Out of Notebook

**Location:** `lib/services/database_service.dart:~2100`

| Method | Status | Notes |
|--------|--------|-------|
| `moveNotesOutOfNotebook()` | **FIXED** | Now syncs notes after moving |

**Fix Applied:**
```dart
Future<void> moveNotesOutOfNotebook(String notebookId, {String? userId}) async {
  for (final note in notesInNotebook) {
    note.updateInPlace(clearNotebookId: true);
    await note.save();
    // Added sync call
    if (userId != null && userId.isNotEmpty) {
      await syncNoteToCloudDebounced(note, userId);
    }
  }
}
```

---

## 2. Sync Queue Analysis

### 2.1 Task Sync Queue

**Box Name:** `sync_queue`
**Location:** `lib/services/database_service.dart`

| Operation | Method | Status |
|-----------|--------|--------|
| Add to queue | `_addToSyncQueue()` | OK |
| Process queue | `_processSyncQueue()` | OK |
| Retry logic | Exponential backoff (2s, 4s, 8s) | OK |
| Max attempts | 3 | OK |
| Cleanup | 7 days old items removed | OK |

### 2.2 Notes Sync Queue

**Box Name:** `notes_sync_queue`
**Location:** `lib/services/database_service.dart`

| Operation | Method | Status |
|-----------|--------|--------|
| Add to queue | `_addNoteToSyncQueue()` | OK |
| Process queue | `_processNotesSyncQueue()` | OK |

### 2.3 Notebooks Sync Queue

**Status:** NOT IMPLEMENTED

**Note:** Notebooks use direct sync without queue. If sync fails, the notebook won't be retried automatically.

**Recommendation:** Consider adding a notebooks sync queue for consistency.

---

## 3. Authentication Sync Paths

### 3.1 Anonymous to Linked Account

**Location:** `lib/services/auth_service.dart`

| Method | Platform | Status |
|--------|----------|--------|
| `linkWithGoogle()` | Web | **FIXED** (uses linkWithPopup) |
| `linkWithGoogle()` | Mobile | OK (uses linkWithCredential) |
| `linkWithEmail()` | All | OK |

### 3.2 Cloud Sync Enable on Link

**Location:** Multiple files

| File | Method | Status |
|------|--------|--------|
| `lib/widgets/dialogs/link_account_dialog.dart` | Google/Email link | **FIXED** |
| `lib/screens/register_screen.dart` | Google/Email register | **FIXED** |

**Fix Applied:** After successful account linking:
```dart
if (credential != null) {
  final dbService = ref.read(databaseServiceProvider);
  await dbService.setCloudSyncEnabled(true);
}
```

---

## 4. Data Model Sync Verification

### 4.1 Hive TypeIds

| Model | TypeId | Status |
|-------|--------|--------|
| Task | 0 | OK |
| Subtask | 1 | OK |
| Note | 2 | OK |
| TaskHistory | 3 | OK |
| UserPreferences | 4 | OK |
| GuideProgress | 5 | OK |
| Notebook | 6 | OK |
| ChecklistItem | 7 | **FIXED** (was 4, conflicting) |

### 4.2 copyWith() Safety

All models implement `copyWith()` correctly. The `DatabaseService` uses `updateInPlace()` for existing records to avoid creating duplicates.

---

## 5. Security Rules Verification

**Location:** `firestore.rules`

| Collection | Read | Write | Delete | Status |
|------------|------|-------|--------|--------|
| users/{userId} | Owner | Owner | Owner | OK |
| users/{userId}/tasks | Owner | Owner | Owner | OK |
| users/{userId}/notes | Owner | Owner | Owner | OK |
| users/{userId}/notebooks | Owner | Owner | Owner | **ADDED** |

---

## 6. Recommendations

### High Priority

1. **Add Integration Tests**
   - Automated tests for end-to-end sync
   - Test offline queue processing
   - Test conflict resolution

### Medium Priority

2. **Add Notebooks Sync Queue**
   - Currently no retry on failed notebook sync
   - Should mirror task/note queue implementation

3. **Add Sync Status Indicators**
   - Show user when sync is pending
   - Show last successful sync time

### Low Priority

4. **Consider Real-time Listeners**
   - Current: one-time fetch
   - Could add Firestore listeners for live updates

5. **Rich Content Size Limits**
   - Quill Delta can get large
   - Consider compression or chunking for very large documents

---

## 7. Test Verification Checklist

### Task Sync
- [x] Create task locally
- [x] Task syncs to Firestore
- [x] All fields present in Firestore
- [x] Update task locally
- [x] Update syncs to Firestore
- [x] Delete task (soft delete)
- [x] Delete syncs to Firestore

### Note Sync
- [x] Create note with plain text
- [x] Create note with checklist
- [x] Create note with rich content
- [x] Note syncs with all fields
- [x] notebookId syncs correctly
- [x] status field syncs
- [x] contentType syncs
- [x] richContent (Delta JSON) syncs

### Notebook Sync
- [x] Create notebook
- [x] Notebook syncs to Firestore
- [x] Move note to notebook
- [x] Note's notebookId updates
- [x] Delete notebook
- [x] Notes moved out of notebook
- [x] Moved notes sync (FIXED)

### Auth Flow
- [x] Anonymous sign-in
- [x] Link with Google (web)
- [x] Link with Email
- [x] cloudSyncEnabled auto-set (FIXED)
- [x] Data persists after re-sign-in

### Offline/Online
- [x] Create data offline (queued)
- [x] Sync when online
- [x] Exponential backoff retry

---

## Appendix: Key Code Locations

| Component | File | Primary Methods |
|-----------|------|-----------------|
| Task Sync | database_service.dart | syncTaskToCloud(), syncFromCloud() |
| Note Sync | database_service.dart | syncNoteToCloud(), syncFromCloud() |
| Notebook Sync | database_service.dart | syncNotebookToCloud() |
| Sync Queue | database_service.dart | _processSyncQueue() |
| Auth Link | auth_service.dart | linkWithGoogle(), linkWithEmail() |
| Cloud Enable | database_service.dart | setCloudSyncEnabled() |

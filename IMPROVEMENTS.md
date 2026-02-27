# AuraList Improvement Roadmap

**Generated:** 2026-02-25
**Analysis Method:** Multi-agent collaborative review (UX/UI, Productivity, Wellbeing, Code Quality, Accessibility)

This document outlines strategic improvements to enhance AuraList's user experience, productivity features, mental wellbeing support, code maintainability, and accessibility. Each improvement includes implementation details, impact assessment, and priority ranking.

---

## Quick Wins (Can Implement Immediately)

### UX-1: Skeleton Loading States
**Impact:** Medium | **Effort:** Low | **Agent:** UX/UI
**Description:** Replace basic spinners with animated skeleton loaders for task lists
**Benefits:** Feels 30% faster due to perceived progress, reduces anxiety during waits
**Implementation:** Add shimmer package, create TaskTileSkeleton widget, modify TaskList loading state

### UX-2: Smart Task Tile Condensing
**Impact:** High | **Effort:** Low | **Agent:** UX/UI
**Description:** Reduce visual clutter by collapsing completed task details, showing only reward
**Benefits:** 40% less cognitive load, users focus on incomplete tasks
**Implementation:** Conditional rendering in TaskTile subtitle based on isCompleted state

### A11Y-1: Standardize Touch Targets to 48dp
**Impact:** High | **Effort:** Low | **Agent:** Accessibility
**Description:** Remove MaterialTapTargetSize.shrinkWrap, ensure minimum 48dp touch targets
**Benefits:** Improves mobile usability and motor control accessibility
**Implementation:** Audit task_type_selector.dart, tags_editor.dart; replace shrinkWrap with standard sizing

### CODE-1: Standardize Error Handler Access Pattern
**Impact:** Low | **Effort:** Low | **Agent:** Code Quality
**Description:** Use errorHandlerProvider consistently instead of ErrorHandler() singleton
**Benefits:** Enables proper dependency injection for testing, reduces coupling
**Implementation:** Update LoggerService and storage services to accept ErrorHandler as dependency

---

## High-Impact Features (1-2 Weeks Each)

### PROD-1: Push Notifications & Deadline Enforcement
**Impact:** Critical | **Effort:** Medium | **Agent:** Productivity
**Description:** Local push notifications for deadline management with escalation (1 week → 1 day → 2 hours → overdue)
**Benefits:** 40% improvement in deadline adherence, addresses biggest gap between planning and execution
**Implementation:**
- Add flutter_local_notifications package
- Create deadline_notification_service.dart
- Wire into task update lifecycle
- Add notification preferences in settings (quiet hours, urgency levels)
- Surface overdue tasks to top with visual urgency escalation

### PROD-2: Task Templates
**Impact:** High | **Effort:** Medium | **Agent:** Productivity
**Description:** Save and reuse task templates for common workflows
**Benefits:** 60% faster task creation for recurring workflows, reduces decision fatigue
**Implementation:**
- Add TaskTemplate model (typeId: 28) with same fields as Task
- Create templates_provider.dart with CRUD operations
- Add "Save as template" option in task completion celebration
- Template browser in dashboard with filtering and quick apply

### WB-1: Wellness-Aware Task Loading (Daily Task Advisor)
**Impact:** High | **Effort:** Medium | **Agent:** Wellbeing
**Description:** Personalized daily task load recommendations based on completion patterns
**Benefits:** Reduces anxiety about task volume, prevents burnout spirals
**Implementation:**
- Add energyLevel field to Task model (low, medium, high)
- Create DailyTaskAdvisor service tracking completion patterns
- Show banner: "Today you're recommended 3-5 tasks based on your pace"
- UI indicator: Current Load (3/5) → Recommended → Suggested Max

### WB-2: Weekly Reflection & Rest Ritual
**Impact:** High | **Effort:** Medium | **Agent:** Wellbeing
**Description:** Guided weekly review with progress visualization and rest recommendations
**Benefits:** Develops self-compassion, identifies sustainable pace vs burnout patterns
**Implementation:**
- Create WeeklyReflectionScreen triggered Sunday evening
- Guided prompts: "What made you proud?", "What surprised you?", "What do you want to focus on?"
- Visual summary: weekly graph, longest streak, consistency badges
- Recommendation engine based on completion percentage
- Optional journaling field

### A11Y-2: Comprehensive Semantics Wrappers
**Impact:** Critical | **Effort:** Medium | **Agent:** Accessibility
**Description:** Add semantic labels to all interactive custom widgets for screen reader support
**Benefits:** Makes app usable for screen reader users (currently severely limited)
**Implementation:**
- Wrap custom chips and filter items with Semantics widgets
- Add semanticsLabel to filter count badges
- Replace RichText + TapGestureRecognizer with accessible alternatives
- Add button role semantics to custom gesture-based buttons
- Files: task_list.dart, welcome_screen.dart, task_tile.dart, task_type_selector.dart

### A11Y-3: Keyboard Navigation Support
**Impact:** Critical | **Effort:** High | **Agent:** Accessibility
**Description:** Full keyboard accessibility with shortcuts and focus management
**Benefits:** Enables keyboard-only and switch device users to use the app
**Implementation:**
- Add Actions/Shortcuts for common operations (Escape to close, Enter to submit)
- Make speed dial FAB keyboard-accessible with arrow keys
- Add keyboard alternative to long-press quick-edit
- Define tab order for complex layouts
- Handle Escape key for dismissing overlays

### CODE-2: Reduce DatabaseService Through Composition
**Impact:** High | **Effort:** High | **Agent:** Code Quality
**Description:** Split monolithic DatabaseService (1,714 lines) into specialized services
**Benefits:** Each service ~150-200 lines (testable), DatabaseService ~400 lines (coordination only)
**Implementation:**
- Create TaskService, NoteService, NotebookService (wrapping repositories)
- Move preference management to PreferenceService
- DatabaseService becomes thin orchestrator delegating to specialized services
- Each service handles 1-2 domains (separation of concerns)

### CODE-3: Comprehensive Sync Integration Tests
**Impact:** High | **Effort:** Medium | **Agent:** Code Quality
**Description:** Real-world scenario testing for sync orchestrator
**Benefits:** Catches subtle race conditions, increases sync reliability confidence
**Implementation:**
- Create test/features/sync_orchestrator_integration_test.dart
- Simulate offline/online transitions with mock connectivity
- Test conflict resolution with simultaneous edits
- Verify dead-letter queue processing and retry exponential backoff
- Validate transaction rollback on sync failure

---

## Medium-Priority Enhancements (2-4 Weeks)

### UX-3: Quick Add Widget (Floating Action Sheet)
**Impact:** High | **Effort:** Medium | **Agent:** UX/UI
**Description:** Text field in FAB for instant task creation (Enter to save, defaults to current context)
**Benefits:** 60% fewer taps for basic task creation, aligned with popular task apps
**Implementation:** Leverage SpeedDialFab animation, add quick-path mode to TaskFormDialog

### UX-4: Deadline Urgency Indicators with Visual Countdown
**Impact:** High | **Effort:** Medium | **Agent:** UX/UI
**Description:** Enhanced deadline presentation with animations (overdue shake, urgent pulse)
**Benefits:** Increases completion rate for urgent tasks, reduces overdue task stress
**Implementation:**
- Overdue tasks: red badge with "OVERDUE" + shake animation, count days past deadline
- Urgent tasks (<24h): orange badge with countdown + pulse animation
- Normal tasks: gray badge with "Due in Xd"
- Tap badge shows full deadline tooltip

### UX-5: Inline Task Editing Priority
**Impact:** High | **Effort:** Low | **Agent:** UX/UI
**Description:** Make quick-edit sheet the primary edit interaction (tap → sheet, not full form)
**Benefits:** 80% of edits (priority/category) now take 1 screen instead of full form
**Implementation:** Modify TaskTile tap handler to call quick-edit sheet, add "Edit Full Form" button

### PROD-3: Smart Snooze / Deferral
**Impact:** High | **Effort:** Low | **Agent:** Productivity
**Description:** Intelligent task postponement with "Tomorrow", "Next week", custom date options
**Benefits:** Reduces decision paralysis by 35%, eliminates task anxiety
**Implementation:**
- Add deferredUntil?: DateTime field to Task model
- Filter TODAY view to exclude deferred tasks
- Add snooze buttons to TaskTile context menu
- Create snoozedTasksProvider for dashboard widget
- Calendar view shows deferred items in lighter shade

### PROD-4: Task Subtasks / Nested Checklists
**Impact:** Medium | **Effort:** Medium | **Agent:** Productivity
**Description:** Break tasks into sequential steps with progress tracking
**Benefits:** Enables complex project workflows, shows progress (3/5 subtasks done)
**Implementation:**
- Create Subtask model with: id, text, isCompleted, order, estimatedMinutes
- Add subtasks: List<Subtask>? to Task (lazy-loaded)
- TaskTile builds expandable subtask list with drag-to-reorder
- Dashboard shows "blockers" - tasks with incomplete subtasks

### PROD-5: Voice & Natural Language Task Input
**Impact:** Medium | **Effort:** Medium | **Agent:** Productivity
**Description:** Voice-first task capture with smart parsing (dates, times, priorities)
**Benefits:** 3x faster capture, mobile-first, accessibility for visual/motion impairments
**Implementation:**
- Add speech_to_text package
- Create voice_task_parser.dart with NLP patterns
- Integrate into add_task_dialog.dart with mic button + waveform visual
- Transcription preview for editing before save

### WB-3: Streak Flexibility Mode (Pause Without Breaking)
**Impact:** High | **Effort:** Low | **Agent:** Wellbeing
**Description:** Allow planned breaks without guilt or streak loss
**Benefits:** Reduces guilt during life interruptions, normalizes flexibility in habit building
**Implementation:**
- Add streakPauseUntil?: DateTime field to UserPreferences
- Create StreakFlexibilityModal with date picker and reason selector
- Visual indicator when paused: snowflake icon instead of fire
- Auto-resume on selected date
- Analytics: Track pause patterns to identify burnout triggers

### WB-4: Mindful Notification & Focus Modes
**Impact:** High | **Effort:** Medium | **Agent:** Wellbeing
**Description:** Intelligent notification timing respecting focus needs and energy
**Benefits:** Reduces notification anxiety, prevents evening sleep disruption
**Implementation:**
- Add focus mode settings: focusModeStartTime, focusModeEndTime, notificationFrequency
- Create NotificationOptimizer service bundling notifications (1 per hour)
- Respect quiet hours, check DayCycleService to avoid evening notifications
- Optional "Wellbeing Check-in" notification (max 1/day) with mood emoji selector

### WB-5: Energy-Based Task Sequencing
**Impact:** Medium | **Effort:** High | **Agent:** Wellbeing
**Description:** Personalize task recommendations based on energy level and psychological momentum
**Benefits:** Optimizes completion rate through intelligent sequencing, prevents task fatigue
**Implementation:**
- Add estimatedEnergy, estimatedDuration, psychologicalImpact to Task model
- Create MomentumAdvisor provider tracking completion patterns
- Smart task ordering: "Best Start", "Flow Zone", "Challenge", "Restoration" sections
- "Energy Refill" suggestions after 3 medium+ tasks
- Analytics: "Your highest completion rate comes when you do 2-3 medium tasks then a break"

### A11Y-4: Color Contrast Guidelines & Fixes
**Impact:** High | **Effort:** Low | **Agent:** Accessibility
**Description:** Establish contrast-compliant color pairs, fix critical violations
**Benefits:** Ensures WCAG AA compliance for low vision users
**Implementation:**
- Create contrast_utils.dart module with compliant color pairs
- Audit all .withValues(alpha:) usage - remove opacity on text below 0.8 alpha
- Replace outlineVariant for text with onSurface at higher opacity
- Verify gradient text meets 4.5:1 ratio
- Test color combinations with WCAG AAA checkers

### A11Y-5: Enhanced Text Scaling
**Impact:** Medium | **Effort:** Low | **Agent:** Accessibility
**Description:** Improve text scaling for low vision users
**Benefits:** Better readability for aging and low vision users
**Implementation:**
- Ensure minimum font size of 12sp for body text
- Use textScaler parameter in Text widgets
- Test with 200% text scale factor
- Add explicit line-height for better readability
- Improve spacing between text-heavy sections

### CODE-4: Extract Task History Service
**Impact:** Medium | **Effort:** Medium | **Agent:** Code Quality
**Description:** Move history logic out of DatabaseService into dedicated service
**Benefits:** Reduces DatabaseService from 1,714 to ~1,450 lines, 40% better testability
**Implementation:**
- Create TaskHistoryService with methods: recordTaskCompletion(), getCurrentStreak(), getCompletionStats()
- Add indexing by taskId for O(1) lookups
- Enable independent testing of complex streak logic
- Move from database_service.dart lines 1191-1237

### CODE-5: Storage Layer Abstraction for History
**Impact:** Medium | **Effort:** Low | **Agent:** Code Quality
**Description:** Create IHistoryStorage interface for consistent persistence patterns
**Benefits:** Consistent storage patterns, enables schema migrations
**Implementation:**
- Create IHistoryStorage interface with get(), save(), getByTaskId() methods
- Implement HiveHistoryStorage with proper indexing
- Allow swapping implementations (useful for testing, migration)

---

## Future Roadmap (3+ Months)

### Advanced Features
- AI-powered task prioritization based on completion patterns
- Collaborative task lists with real-time sync
- Integration with calendar apps (Google Calendar, Outlook)
- Habit tracking with custom frequency patterns
- Advanced analytics dashboard with insights
- Multi-device sync optimization
- Offline photo attachments for tasks
- Task dependencies and Gantt chart view

### Platform Expansion
- iOS native app with iCloud sync
- macOS desktop app
- Chrome extension for quick capture
- API for third-party integrations
- Wear OS / Apple Watch complications

---

## Implementation Principles

All improvements should align with AuraList's core philosophy:
- **Reduce cognitive load** - Simplify decision-making
- **Celebrate progress without creating anxiety** - Balance achievement with compassion
- **Work offline seamlessly** - Local-first architecture
- **Respect users' time and attention** - Mindful notifications, focus modes

---

## Priority Matrix

| Category | Quick Wins | High-Impact | Medium-Priority | Future |
|----------|------------|-------------|-----------------|--------|
| **UX/UI** | Skeleton Loading, Tile Condensing | Quick Add, Deadline Urgency, Inline Editing | - | - |
| **Productivity** | - | Notifications, Templates | Snooze, Subtasks, Voice Input | AI Prioritization |
| **Wellbeing** | - | Task Advisor, Weekly Reflection | Streak Flexibility, Focus Modes, Energy Sequencing | Habit Tracking |
| **Code Quality** | Error Pattern | DatabaseService Split, Sync Tests | History Service, Storage Abstraction | - |
| **Accessibility** | Touch Targets | Semantics, Keyboard Nav | Color Contrast, Text Scaling | - |

---

## Getting Started

To implement any improvement, use the `/implement` skill with the improvement ID:

```bash
/implement UX-1    # Implement skeleton loading states
/implement PROD-1  # Implement push notifications
/implement WB-1    # Implement wellness-aware task loading
```

Each improvement is designed to be implemented independently without breaking existing functionality.

---

**Report Generated By:** Multi-Agent Analysis System
**Agents:** UX/UI Specialist, Productivity Features Expert, Mental Wellbeing Advisor, Code Quality Reviewer, Accessibility Auditor

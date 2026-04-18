# MindNest - Complete Technical Report

## 1. Project Overview

### 1.1 Purpose and Core Functionality

**MindNest** is a comprehensive personal wellness and mental health companion application built with Flutter. The app helps users build and maintain healthy mental wellness habits through:

- **AI Chat Companion** — Personal AI friend powered by Google Gemini
- **Smart Routines** — Personalized daily routines with streak tracking
- **Meditation Library** — Guided meditations with categories (Sleep, Stress Relief, Focus)
- **Focus Sessions** — Pomodoro-style productivity timer
- **Breathing Exercises** — Guided breathing for anxiety and stress relief
- **Journaling** — Private journal with mood-aware reflection prompts
- **Smart Goals** — Create, track, and complete personal wellness goals
- **Daily Check-ins** — Mood tracking that influences recommendations
- **Progress Analytics** — Streak tracking and activity insights
- **Badges & Rewards** — Gamification for habit consistency

### 1.2 Overall Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              FRONTEND (Flutter)                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │    Screens   │  │   Widgets    │  │   Theme      │  │  Features    │ │
│  │  (UI Layer)  │  │ (Reusable UI)│  │ (Styling)    │  │ (Modules)    │ │
│  └──────┬───────┘  └──────────────┘  └──────────────┘  └──────────────┘ │
│         │                                                               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     STATE MANAGEMENT (Riverpod)                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │   │
│  │  │   Providers  │  │   Services   │  │   Data Models        │  │   │
│  │  │ (App State)  │  │ (Business)   │  │   (Entities)         │  │   │
│  │  └──────────────┘  └──────┬───────┘  └──────────────────────┘  │   │
│  └───────────────────────────│─────────────────────────────────────┘   │
└─────────────────────────────│─────────────────────────────────────────┘
                              │
┌─────────────────────────────│─────────────────────────────────────────┐
│                         BACKEND (Firebase)                               │
│  ┌──────────────────────────┼────────────────────────────────────────┐  │
│  │                    Firestore Database                                 │  │
│  │  ┌────────────┐  ┌───────┴───────┐  ┌────────────┐  ┌────────────┐ │  │
│  │  │   Users    │  │   Routines    │  │  Check-ins │  │   Badges   │ │  │
│  │  │ Collection │  │ Subcollection │  │ Collection │  │ Collection │ │  │
│  │  └────────────┘  └─────────────┘  └────────────┘  └────────────┘ │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │  │
│  │  │  Journals  │  │ Meditation │  │    Goals   │  │ Sleep Logs │    │  │
│  │  │ Collection │  │ Collection │  │ Collection │  │Subcollection│   │  │
│  │  └────────────┘  └────────────┘  └────────────┘  └────────────┘    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                     Firebase Authentication                        │   │
│  │         (Email/Password + Google Sign-In)                        │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────│─────────────────────────────────────────┐
│                    EXTERNAL SERVICES                                    │
│  ┌──────────────────────────┼────────────────────────────────────────┐ │
│  │                  Google Gemini AI                                   │ │
│  │              (AI Chat + Personalization)                            │ │
│  └──────────────────────────┼────────────────────────────────────────┘ │
│  ┌──────────────────────────┼────────────────────────────────────────┐  │
│  │               Local Notifications                                   │  │
│  │         (Routine Reminders via flutter_local_notifications)         │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Folder & File Structure

### 2.1 Project Structure Overview

```
Mind-Nest/
├── lib/
│   ├── main.dart                    # App entry point with bootstrap logic
│   ├── firebase_options.dart        # Firebase configuration
│   │
│   ├── config/                      # Configuration files
│   │   ├── routine_config.dart      # Activity definitions & time slots
│   │   ├── motive_config.dart       # User motive profiles (Sleep/Stress/Anxiety/Focus/Habit)
│   │   ├── app_branding.dart        # App name, logos, assets
│   │   └── notification_content.dart
│   │
│   ├── core/                        # Core utilities
│   │   ├── logger.dart              # Application logging
│   │   └── exceptions.dart          # Custom exceptions
│   │
│   ├── features/                    # Feature modules (modular architecture)
│   │   ├── calm/                    # Calm/relaxation feature
│   │   │   ├── application/         # Business logic services
│   │   │   │   ├── calm_recommendation_service.dart
│   │   │   │   ├── calm_progress_service.dart
│   │   │   │   ├── mood_tracking_service.dart
│   │   │   │   └── ...
│   │   │   └── models/              # Feature-specific models
│   │   │
│   │   ├── home/                    # Home feature
│   │   │   ├── application/
│   │   │   │   └── home_routine_engine.dart  # Routine generation algorithm
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   │   └── home_content_view.dart    # Main home UI
│   │   │   └── providers/
│   │   │
│   │   ├── journal/                 # Journaling feature
│   │   ├── meditation/              # Meditation feature
│   │   └── routines/                # Routine management feature
│   │
│   ├── models/                      # Data models (entities)
│   │   ├── user_model.dart          # User profile
│   │   ├── badge.dart               # Badge definitions
│   │   ├── daily_checkin.dart       # Check-in data
│   │   ├── journal_entry.dart       # Journal data
│   │   ├── guided_meditation.dart   # Meditation content
│   │   ├── routine_completion.dart  # Completion tracking
│   │   └── ...
│   │
│   ├── providers/                   # Riverpod state providers
│   │   ├── auth_provider.dart       # Authentication state
│   │   ├── user_provider.dart       # User profile state
│   │   ├── goal_provider.dart       # Goals state
│   │   ├── journal_provider.dart    # Journal state
│   │   ├── meditation_provider.dart # Meditation state
│   │   └── app_providers.dart       # Service providers
│   │
│   ├── screens/                     # UI Screens (33 screens)
│   │   ├── home_screen.dart         # Main navigation container
│   │   ├── chat_screen.dart         # AI chat interface
│   │   ├── daily_checkin_screen.dart
│   │   ├── manage_routine_screen.dart
│   │   ├── meditation_library_screen.dart
│   │   ├── badges_screen.dart
│   │   └── ...
│   │
│   ├── services/                    # Business logic services (16 services)
│   │   ├── auth_service.dart        # Firebase Auth operations
│   │   ├── chat_service.dart        # Gemini AI integration
│   │   ├── firestore_service.dart   # Database operations
│   │   ├── badge_service.dart       # Gamification logic
│   │   ├── checkin_service.dart     # Daily check-in processing
│   │   ├── routine_tracking_service.dart
│   │   ├── notification_service.dart
│   │   ├── personalization_service.dart
│   │   └── ...
│   │
│   ├── theme/                       # App theming
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   │
│   └── widgets/                     # Reusable UI components
│       ├── common/
│       ├── calm/
│       └── ...
│
├── assets/
│   ├── audio/                       # Ambient sound files
│   ├── images/                      # App images & backgrounds
│   └── screenshots/
│
├── test/                            # Unit and widget tests
├── firestore.rules                  # Security rules
├── storage.rules                    # Storage security rules
└── .env                             # API keys (gitignored)
```

---

## 3. Feature-wise Breakdown

### 3.1 Routine Management

**Main Files:**
- `lib/features/home/application/home_routine_engine.dart` — Routine generation algorithm
- `lib/screens/manage_routine_screen.dart` — Routine management UI
- `lib/services/routine_tracking_service.dart` — Completion tracking
- `lib/config/routine_config.dart` — Activity definitions & optimal time slots
- `lib/config/motive_config.dart` — Motive-based routine templates

**UI Trigger Flow:**
```dart
// User opens Manage Routine Screen
ManageRoutineScreen 
  → _loadUserRoutine() // Loads from Firestore
  → _saveRoutine()     // Saves changes
    → FirestoreService.updateUser() 
    → NotificationService.syncRoutineNotifications()
```

**Data Flow:**
```
User Action (Add/Remove Activity)
    ↓
ManageRoutineScreen._saveRoutine()
    ↓
RoutineTrackingService (for completion status)
    ↓
FirestoreService.updateUser() 
    ↓
Firebase (users/{uid}/routineSchedule, routineActivities)
    ↓
NotificationService.syncRoutineNotifications() (schedules reminders)
```

### 3.2 AI Chat

**Main Files:**
- `lib/services/chat_service.dart` — Core chat logic
- `lib/screens/chat_screen.dart` — Chat UI
- `lib/providers/app_providers.dart` — Chat service provider

**UI Trigger Flow:**
```dart
ChatScreen._sendMessage()
  → ChatService.sendMessage()
    → _fetchUserContext() // Gets mood, routine progress, sleep data
    → _buildPersonalizedSystemPrompt()
    → _sendMessageViaLocalModel()
      → Google Generative AI API
```

**Data Flow:**
```
User types message → ChatScreen._sendMessage()
    ↓
ChatService.sendMessage(sanitizedText)
    ↓
_crisisCheck() (suicide/self-harm detection)
    ↓
_fetchUserContext() from Firestore:
  - mood_logs (today's mood)
  - routines (completion status)
  - sleep_logs (last night's sleep)
    ↓
_buildPersonalizedSystemPrompt() 
  (injects user context into AI instructions)
    ↓
_sendMessageViaLocalModel()
  → Google Gemini API with fallback chain:
    gemini-1.5-flash → gemini-flash-lite → gemini-2.0-flash-lite
    ↓
Response displayed in ChatScreen
```

### 3.3 Mood Tracking & Daily Check-in

**Main Files:**
- `lib/screens/daily_checkin_screen.dart` — Check-in UI
- `lib/services/checkin_service.dart` — Check-in processing
- `lib/models/daily_checkin.dart` — Check-in data model

**UI Trigger Flow:**
```dart
DailyCheckInScreen._submitCheckIn()
  → CheckInService.submitCheckIn()
    → Firestore (daily_checkins collection)
    → FirestoreService.logActivityCompletion('daily_checkin')
    → _applyAdaptiveRoutine() (adds activities based on check-in)
```

**Adaptive Routine Logic:**
```dart
// From CheckInService._applyAdaptiveRoutine()
if (energyLevel < 4) → add 'Power Nap'
if (energyLevel > 8) → add 'Deep Work'
if (sleepQuality < 5) → add 'Early Bedtime'
if (mood in ['Anxious', 'Stress', 'Tired']) → add 'Meditation'
```

### 3.4 Meditation

**Main Files:**
- `lib/screens/meditation_library_screen.dart` — Meditation library
- `lib/screens/meditation_player_screen.dart` — Audio player
- `lib/models/guided_meditation.dart` — Meditation content (44536 bytes of curated content)
- `lib/services/meditation_service.dart` — Meditation business logic

**Data Flow:**
```
User selects meditation
    ↓
MeditationPlayerScreen
    ↓
AudioPlaybackService (just_audio plugin)
    ↓
Play from assets/audio/ or stream
    ↓
FirestoreService.logActivityCompletion('meditation')
    ↓
BadgeService.checkAndAwardBadges()
```

### 3.5 Badges & Gamification

**Main Files:**
- `lib/services/badge_service.dart` — Badge logic
- `lib/models/badge.dart` — Badge definitions
- `lib/screens/badges_screen.dart` — Badge display UI

**Badge Definitions:**
```dart
// From Badge.allBadges
'first_step'      → Completed first routine
'week_warrior'    → 7-day streak
'perfect_week'    → All activities for 7 days
'meditation_master' → 10 meditations completed
'journal_warrior' → 15 journal entries
'goal_crusher'    → 3 goals achieved
```

**Progress Calculation Flow:**
```
Activity Completion (routine/meditation/journal)
    ↓
FirestoreService.logActivityCompletion()
    ↓
BadgeService.checkAndAwardBadges(userId)
    ↓
getEarnedBadgeIds() (already earned badges)
getAllBadgesProgress() (calculate progress for each)
    ↓
For each badge:
  - first_step: weekCompletions.isNotEmpty
  - week_warrior: getCompletionStreak() ≥ 7
  - perfect_week: 7 days with 100% completion
  - meditation_master: activityCount ≥ 10
  - journal_warrior: activityCount ≥ 15
  - goal_crusher: completedGoals ≥ 3
    ↓
Award new badges to Firestore (badges/{uid}/earned/{badgeId})
    ↓
Return new badges to UI for celebration dialog
```

---

## 4. Working of Core Modules

### 4.1 HomeRoutineEngine - Algorithm & Scheduling

**File:** `lib/features/home/application/home_routine_engine.dart`

**Purpose:** Generates balanced daily routines by distributing activities across Morning, Afternoon, and Evening periods.

**Algorithm Pseudocode:**
```dart
class HomeRoutineEngine {
  // 1. Generate balanced routine from activity pool
  static List<String> generateBalancedRoutine(pool, targetCount) {
    // Divide target count equally across 3 periods
    baseCount = targetCount ~/ 3;
    remainder = targetCount % 3;
    
    mCount = baseCount + (remainder >= 1 ? 1 : 0);  // Morning gets first +1
    aCount = baseCount + (remainder >= 2 ? 1 : 0);  // Afternoon gets second +1
    eCount = baseCount;  // Evening gets base
    
    // Shuffle each period's pool with daily seed
    rng = Random(year + month + day);  // Same seed = same shuffle for the day
    morningPool.shuffle(rng);
    afternoonPool.shuffle(rng);
    eveningPool.shuffle(rng);
    
    // Pick from each period round-robin style
    result = [];
    pickFrom(morningPool, mCount);
    pickFrom(afternoonPool, aCount);
    pickFrom(eveningPool, eCount);
    
    return result;
  }
  
  // 2. Calculate optimal schedule times
  static Map<String, String> calculateDynamicSchedule(
    activities, wakeTime, bedTime
  ) {
    for each activity:
      period = RoutineConfig.getTimePeriod(activity);
      schedule[activity] = RoutineConfig.getOptimalTimeSlot(
        activity,
        wakeHour: wakeTime.hour,
        bedHour: bedTime.hour,
      );
    return schedule;
  }
}
```

**Time Slot Calculation (RoutineConfig):**
```dart
// Morning: offset from wake time
// Afternoon: offset from max(12:00, wake+5h)
// Evening: offset from (bedtime - 2 hours)

getOptimalTimeSlot(activity, wakeHour, bedHour) {
  period = getTimePeriod(activity);
  
  if (period == 'Morning') {
    anchor = wakeHour * 60;
    offset = _morningOffsets[activity] ?? 30;
  } else if (period == 'Afternoon') {
    anchor = max(12*60, wakeHour*60 + 5*60);
    offset = _afternoonOffsets[activity] ?? 60;
  } else { // Evening
    anchor = bedHour*60 - 120;
    offset = _eveningOffsets[activity] ?? 30;
  }
  
  totalMinutes = anchor + offset;
  return formatTime(totalMinutes);  // "7:30 AM"
}
```

### 4.2 ChatService - AI Interaction & Personalization

**File:** `lib/services/chat_service.dart`

**Key Components:**

1. **Multi-Model Fallback Chain:**
```dart
final List<String> _fallbackModels = [
  'gemini-1.5-flash',
  'gemini-flash-lite',
  'gemini-flash-lite-latest',
  'gemini-2.0-flash-lite',
  'gemini-exp-1206',
  'gemini-2.5-flash',
];

// On failure, automatically tries next model
if (_currentModelIndex < _fallbackModels.length - 1) {
  _currentModelIndex++;
  _initModel();  // Reinitialize with next model
  return _sendMessageViaLocalModel(userMessage);
}
```

2. **Personalization Flow:**
```dart
_sendMessage() 
  → _fetchUserContext()
    - mood_logs: today's mood
    - routines: completed/total activities
    - sleep_logs: last night's duration
  → _buildPersonalizedSystemPrompt()
    (injects context into AI instructions)
  → send to Gemini
```

3. **Crisis Detection:**
```dart
bool _containsCrisisKeywords(String message) {
  const crisisKeywords = [
    'suicide', 'suicidal', 'kill myself', 
    'end my life', 'self harm', 'self-harm',
    'don\'t want to live', 'better off dead',
  ];
  return crisisKeywords.any(lowerMessage.contains);
}

// Returns crisis resources instead of AI response
String _getCrisisResponse() {
  return '''I am really concerned about you...
  Tele MANAS: 14416
  Kiran (24/7): 1800-599-0019
  ...''';
}
```

### 4.3 BadgeService - Gamification Logic

**File:** `lib/services/badge_service.dart`

**Progress Tracking:**
```dart
class BadgeProgress {
  final double progressPercentage;  // 0.0 to 1.0
  final int current;
  final int target;
}

Future<Map<String, BadgeProgress>> getAllBadgesProgress(userId) async {
  // 1. First Step: Has completed at least 1 routine?
  weekCompletions = await _routineService.getWeekCompletions(userId);
  hasCompleted = weekCompletions.isNotEmpty;
  
  // 2. Week Warrior: Current streak
  streak = await _routineService.getCompletionStreak(userId);
  
  // 3. Perfect Week: Days with 100% completion
  perfectDays = weekCompletions.where(
    c => c.completedActivities.length == c.totalActivities
  ).length;
  
  // 4. Meditation Master: Count from activity_stats
  medCount = await _firestoreService.getActivityCompletionCount(
    userId, 'meditation'
  );
  
  // 5. Journal Warrior: Count from activity_stats
  journalCount = await _firestoreService.getActivityCompletionCount(
    userId, 'journaling'
  );
  
  // 6. Goal Crusher: Query smart_goals collection
  goalsCount = await _getCompletedGoalsCount(userId);
}
```

**Award Logic:**
```dart
Future<List<Badge>> checkAndAwardBadges(userId) async {
  earnedIds = await getEarnedBadgeIds(userId);  // Already earned
  allProgress = await getAllBadgesProgress(userId);
  
  newBadges = [];
  for (badge in Badge.allBadges) {
    if (earnedIds.contains(badge.id)) continue;  // Skip earned
    
    progress = allProgress[badge.id];
    if (progress.progressPercentage >= 1.0) {
      await _awardBadge(userId, badge);  // Save to Firestore
      newBadges.add(badge);
    }
  }
  return newBadges;  // Return to UI for celebration
}
```

### 4.4 State Management - Riverpod Architecture

**Provider Hierarchy:**
```
ProviderScope (root)
├── authStateProvider (Stream<User?>)
│   └── authServiceProvider
│
├── userProfileProvider (Stream<UserModel?>)
│   └── currentUserProvider
│       └── authStateProvider
│
├── firestoreServiceProvider
│   └── firebaseFirestoreProvider
│
├── routineServiceProvider
│   └── firebaseFirestoreProvider
│
├── checkInServiceProvider
│   ├── firebaseFirestoreProvider
│   └── firestoreServiceProvider
│
├── chatServiceProvider (Stateless)
│
└── badgeServiceProvider (Stateless)
```

**Key Provider Patterns:**

1. **Stream-based Real-time Updates:**
```dart
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(null);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUser(currentUser.uid);
});
```

2. **Service Provider Pattern:**
```dart
final routineServiceProvider = Provider<RoutineTrackingService>((ref) {
  return RoutineTrackingService(
    firestore: ref.read(firebaseFirestoreProvider),
  );
});
```

---

## 5. Data Flow & State Management

### 5.1 Widget → Provider → Service → Database Flow

**Example: Completing a Routine Activity**

```
1. USER ACTION
   User taps checkbox on Routine Card (UI)
              ↓
2. WIDGET LAYER
   onChanged: () => _toggleActivity(activity)
              ↓
3. PROVIDER LAYER (Riverpod)
   ref.read(routineServiceProvider)
     .markActivityComplete(userId, activity, allActivities)
              ↓
4. SERVICE LAYER
   RoutineTrackingService.markActivityComplete()
   ├─→ Generate document ID: "{userId}_{yyyy-MM-dd}"
   ├─→ Check if doc exists
   ├─→ Update: FieldValue.arrayUnion([activity])
   └─→ Firestore update
              ↓
5. DATABASE (Firestore)
   routine_completions/{userId}_{date}
   {
     userId: "...",
     date: Timestamp,
     completedActivities: ["Morning mindfulness", "Drink water"],
     totalActivities: 6
   }
              ↓
6. STREAM UPDATE (Real-time)
   Firestore → StreamBuilder → UI automatically rebuilds
   Progress bar updates, streak recalculates
              ↓
7. SIDE EFFECTS
   BadgeService.checkAndAwardBadges()
   → Checks if new badges earned
   → Shows celebration dialog if yes
```

### 5.2 Riverpod State Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                    STATE LIFECYCLE                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Provider Creation                                          │
│  ┌─────────────┐                                            │
│  │   Provider  │──→ Service instantiated                    │
│  │  (lazy init)│    on first read                           │
│  └─────────────┘                                            │
│         ↓                                                   │
│  ref.watch() / ref.read()                                   │
│         ↓                                                   │
│  ┌─────────────────┐                                        │
│  │  State Access   │──→ Returns current state               │
│  │  (reactive)     │    Rebuilds widget when state changes  │
│  └─────────────────┘                                        │
│         ↓                                                   │
│  State Update                                               │
│  ┌─────────────────┐                                        │
│  │  Stream/Event   │──→ notifyListeners()                  │
│  │  from Firestore │    Widgets rebuild                     │
│  └─────────────────┘                                        │
│         ↓                                                   │
│  Provider Disposal (auto)                                   │
│  ┌─────────────────┐                                        │
│  │  AutoDispose    │──→ Cleans up when no longer watched   │
│  │  (configurable) │                                        │
│  └─────────────────┘                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Backend & Database (Firestore)

### 6.1 Collections & Sub-collections Structure

```
Firestore Database
│
├── users (collection)
│   ├── {userId} (document)
│   │   ├── uid, email, displayName, createdAt
│   │   ├── primaryMotive, secondaryMotives
│   │   ├── supportAreas, experienceLevel
│   │   ├── preferredTime, dailyCommitment
│   │   ├── onboardingCompleted
│   │   ├── routineActivities (list)
│   │   ├── routineSchedule (map: activity → time)
│   │   ├── temporarySchedule (map)
│   │   ├── lastGeneratedDate
│   │   │
│   │   ├── mood_logs (subcollection)
│   │   │   └── {dateId} → mood, timestamp
│   │   │
│   │   ├── sleep_logs (subcollection)
│   │   │   └── {dateId} → durationMinutes, qualityScore
│   │   │
│   │   ├── dailyMotives (subcollection)
│   │   │   └── {dateId} → motive, timestamp
│   │   │
│   │   ├── loginTracking (subcollection)
│   │   │   └── {monthKey} → {day}: timestamp
│   │   │
│   │   └── activity_stats (subcollection)
│   │       ├── meditation → completionCount, lastCompleted
│   │       ├── journaling → completionCount, lastCompleted
│   │       ├── daily_checkin → completionCount
│   │       └── ...
│   │
│   └── {userId} ...
│
├── daily_checkins (collection)
│   └── {checkInId} → userId, date, mood, sleepQuality, 
│       energyLevel, activeGoalsChecked, notes
│
├── routine_completions (collection)
│   └── {userId}_{date} → userId, date, completedActivities[], 
│       totalActivities
│
├── smart_goals (collection)
│   └── {goalId} → userId, title, description, colorValue,
│       createdAt, isCompleted, completedAt
│
├── journal_entries (collection)
│   └── {entryId} → userId, content, mood, createdAt, updatedAt
│
├── badges (collection)
│   └── {userId} (document)
│       └── earned (subcollection)
│           └── {badgeId} → badgeId, badgeName, earnedDate
│
└── (indexes defined in firestore.indexes.json)
```

### 6.2 Query Patterns & Optimizations

**Optimized Reads:**
```dart
// Single document read instead of collection scan
Future<int> getActivityCompletionCount(uid, activityKey) async {
  final doc = await _usersCollection
    .doc(uid)
    .collection('activity_stats')
    .doc(activityKey)
    .get();  // Single doc read (0.02% of quota vs full scan)
  return doc.data()?['completionCount'] ?? 0;
}

// Date-partitioned login tracking
Future<void> _updateLoginDateOptimized(uid, now) async {
  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final dayKey = now.day.toString().padLeft(2, '0');
  
  await _usersCollection
    .doc(uid)
    .collection('loginTracking')
    .doc(monthKey)
    .set({
      dayKey: Timestamp.fromDate(now),  // Partitioned by month
    }, SetOptions(merge: true));
}

// Week completions with limit
Future<List<RoutineCompletion>> getWeekCompletions(uid) async {
  final weekAgo = now.subtract(Duration(days: 7));
  return await _completionsCollection
    .where('userId', isEqualTo: uid)
    .where('date', isGreaterThanOrEqualTo: weekAgo)
    .orderBy('date', descending: false)
    .limit(400)  // Prevent unbounded reads
    .get();
}
```

---

## 7. API & External Services

### 7.1 Gemini API Integration

**File:** `lib/services/chat_service.dart`

**Configuration:**
```dart
// API Key from .env (never committed)
static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

// Model configuration
GenerativeModel(
  model: 'gemini-1.5-flash',
  apiKey: _apiKey,
  systemInstruction: Content.system(_buildPersonalizedSystemPrompt()),
)
```

**Fallback Chain:**
```
Primary:    gemini-1.5-flash
Fallback 1: gemini-flash-lite
Fallback 2: gemini-flash-lite-latest
Fallback 3: gemini-2.0-flash-lite
Fallback 4: gemini-exp-1206
Fallback 5: gemini-2.5-flash
```

**Error Handling:**
```dart
try {
  final response = await _chat!.sendMessage(Content.text(userMessage));
  return response.text;
} catch (e) {
  if (e.contains('API_KEY_INVALID')) 
    return 'API key issue. Check configuration.';
  if (e.contains('429') || e.contains('Quota')) 
    return 'Quota exhausted. Try again later.';
  
  // Try next model in fallback chain
  if (_currentModelIndex < _fallbackModels.length - 1) {
    _currentModelIndex++;
    _initModel();
    return _sendMessageViaLocalModel(userMessage);
  }
  
  return 'Connection issue. Please try again.';
}
```

### 7.2 Environment Configuration (.env)

**File:** `.env` (gitignored)
```env
GEMINI_API_KEY=your_gemini_api_key_here
```

**Loading in Main:**
```dart
// lib/main.dart:49
await dotenv.load(fileName: ".env");
```

**Security:**
- `.env` is listed in `.gitignore` — never committed
- API key only used server-side via Gemini SDK (client-side but API key restricted to app)
- No hardcoded keys in source code

### 7.3 Audio Playback (just_audio)

**File:** `lib/services/audio_playback_service.dart`

**Features:**
- Play ambient sounds from `assets/audio/`
- Background audio support
- Notification controls
- Audio session management

---

## 8. Security & Error Handling

### 8.1 Authentication Flow (Firebase Auth)

**Sign Up:**
```dart
AuthService.signUpWithEmail(email, password)
  → FirebaseAuth.createUserWithEmailAndPassword()
  → FirestoreService.createUser(UserModel)
  → User document created in Firestore
```

**Google Sign-In:**
```dart
AuthService.signInWithGoogle()
  → GoogleSignIn.signIn()
  → GoogleAuthProvider.credential(accessToken, idToken)
  → FirebaseAuth.signInWithCredential()
  → Check if user exists → Create if new
```

**Auth State Persistence:**
```dart
// lib/providers/auth_provider.dart:29-32
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;  // Firebase handles persistence
});
```

### 8.2 Firestore Security Rules

**File:** `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == userId;
      
      // Subcollections inherit parent rules
      match /{subcollection}/{document} {
        allow read, write: if request.auth != null 
          && request.auth.uid == userId;
      }
    }
    
    // Collection-level rules
    match /daily_checkins/{docId} {
      allow read, write: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
    
    // ... similar for other collections
  }
}
```

### 8.3 Error Handling Strategy

**Layered Error Handling:**

1. **UI Layer** — User-friendly messages
```dart
try {
  await service.operation();
} on TimeoutException {
  showDialog('Connection issue. Please check internet.');
} on AuthenticationException catch (e) {
  showDialog(e.message);  // Mapped from Firebase codes
} catch (e) {
  showDialog('Something went wrong. Please try again.');
}
```

2. **Service Layer** — Exception mapping
```dart
// lib/services/auth_service.dart:161-182
String _mapAuthExceptionMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'weak-password': return 'The password is too weak.';
    case 'email-already-in-use': return 'Account already exists.';
    case 'user-not-found': return 'No user found with this email.';
    // ... etc
  }
}
```

3. **Logging** — Debug information
```dart
// lib/core/logger.dart
appLogger.e('Error message', error: e, stackTrace: stackTrace);
```

---

## 9. Execution Flow (End-to-End)

### 9.1 User Login Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                         USER LOGIN FLOW                            │
└────────────────────────────────────────────────────────────────────┘

1. APP BOOTSTRAP
   ┌─────────────┐
   │  main.dart  │ → AppBootstrapper._initialize()
   └──────┬──────┘
          │ 1. Load .env
          │ 2. Initialize Firebase
          │ 3. Initialize Notifications
          │ 4. Configure Firestore (persistence, cache)
          ↓
   ┌─────────────┐
   │  AuthWrapper│ (ConsumerWidget with Riverpod)
   └──────┬──────┘
          ↓

2. AUTH STATE CHECK
   authStateProvider (Stream<User?>)
          │
    ┌────┴────┐
    │         │
   null    User exists
    │         │
    ↓         ↓
 Welcome    userProfileProvider
 Screen        │
              ↓
        ┌─────┴─────┐
        │           │
       null    Profile exists
        │           │
        ↓           ↓
    Onboarding    onboardingCompleted?
    Flow Screen   ├─ true → HomeScreen
                  └─ false → OnboardingFlowScreen

3. POST-LOGIN INITIALIZATION
   HomeScreen (with 4 tabs via IndexedStack)
   ├── HomeContentView
   │   └─ RoutineEngine generates today's routine
   │   └─ Fetch completion status
   │   └─ Load recommendations
   │
   ├── CalmScreen
   ├── ChatScreen
   │   └─ ChatService initialized with user context
   └── ProfileScreen
```

### 9.2 Daily Check-in Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                      DAILY CHECK-IN FLOW                           │
└────────────────────────────────────────────────────────────────────┘

User taps "Check In" button
    ↓
DailyCheckInScreen (PageView with 4 steps)
    │
    ├── Step 1: Sleep Quality (Slider 1-10)
    │   └── Emoji: 😴 😐 🤩
    │
    ├── Step 2: Mood Selection
    │   └── Happy 😊, Calm 😌, Sad 😔, 
    │       Anxious 😰, Excited 🤩, Tired 😴
    │
    ├── Step 3: Energy Level (Slider 1-10)
    │   └── ⚡ emoji with color change
    │
    └── Step 4: Goal Focus
        └── Checkboxes for active goals

User taps "Complete Check-in"
    ↓
_submitCheckIn()
    ↓
CheckInService.submitCheckIn(DailyCheckIn)
    │
    ├── 1. Save to daily_checkins collection
    │   └── Document with userId, date, mood, 
    │       sleepQuality, energyLevel
    │
    ├── 2. Log activity completion
    │   └── FirestoreService.logActivityCompletion(
    │         userId, 'daily_checkin')
    │
    └── 3. Apply adaptive routine logic
        └── _applyAdaptiveRoutine(checkIn)
            │
            ├── If energy < 4 → Add 'Power Nap'
            ├── If energy > 8 → Add 'Deep Work'
            ├── If sleep < 5 → Add 'Early Bedtime'
            └── If mood is Anxious/Stress/Tired → Add 'Meditation'
                │
                └── Update users/{uid}/routineActivities
                    Update users/{uid}/routineSchedule
    ↓
Show completion dialog
    ├── If activities added: "Routine Updated" + list
    └── Else: "Great job checking in!"
    ↓
Return to HomeScreen (routine refreshed)
```

### 9.3 Chat Message Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                      CHAT MESSAGE FLOW                             │
└────────────────────────────────────────────────────────────────────┘

User types message → _sendMessage(text)
    ↓
Validation & Sanitization
    ├── Trim whitespace
    ├── Check length ≤ 500 chars
    └── Remove HTML-like tags [<>]
    ↓
Crisis Check (safety first)
    └── _containsCrisisKeywords(text)?
        └── YES → Return crisis resources immediately
                (Tele MANAS, Kiran Helpline, etc.)
        └── NO → Continue to AI
    ↓
ChatService.sendMessage(sanitizedText, usePersonalization: true)
    │
    ├── Fetch User Context (from Firestore)
    │   ├── mood_logs: Today's mood
    │   ├── routines: completedActivities / totalActivities
    │   └── sleep_logs: Last night's duration
    │
    ├── Build Personalized System Prompt
    │   └── Base prompt + context injection
    │   "User's mood today: Happy"
    │   "Today's routine: 3 of 6 activities completed"
    │   "Last night's sleep: 7.5 hours"
    │
    └── _sendMessageViaLocalModel(userMessage)
        ├── Initialize Gemini model (with fallback chain)
        ├── Send message with personalized context
        └── Return AI response
    ↓
Display response in ChatScreen
    ├── User message bubble (right, primary color)
    └── AI message bubble (left, white)
    ↓
Get personalized suggestions for UI chips
    └── ChatService.getPersonalizedSuggestions()
        ├── Mood-based: "Try breathing exercise"
        ├── Routine-based: "Complete next activity"
        └── Sleep-based: "Try sleep meditation"
```

---

## 10. Important Logic Explanation

### 10.1 Routine Generation Algorithm (Step-by-Step)

**Pseudocode:**
```
FUNCTION generateDailyRoutine(userId, motive, commitment):
  
  // Step 1: Determine activity limit from commitment
  SWITCH commitment:
    "5min"   → limit = 3   (1 per period)
    "10min"  → limit = 6   (2 per period)
    "15min"  → limit = 9   (3 per period)
    "30+min" → limit = 12  (4 per period)
  
  // Step 2: Build candidate pool
  supportActivities = MotiveConfig.getActivitiesForSupportAreas(
    motive, selectedSupportAreas
  )
  baseActivities = MotiveConfig.getRoutineActivities(motive)
  fullPool = supportActivities + baseActivities + defaultPool
  
  // Step 3: Bucket by time period
  morningPool = fullPool.filter(a => getTimePeriod(a) == 'Morning')
  afternoonPool = fullPool.filter(a => getTimePeriod(a) == 'Afternoon')
  eveningPool = fullPool.filter(a => getTimePeriod(a) == 'Evening')
  
  // Step 4: Shuffle with daily seed (same day = same order)
  seed = today.year + today.month + today.day
  rng = Random(seed)
  morningPool.shuffle(rng)
  afternoonPool.shuffle(rng)
  eveningPool.shuffle(rng)
  
  // Step 5: Calculate distribution
  basePerPeriod = limit / 3  // integer division
  remainder = limit % 3
  
  targetMorning = basePerPeriod + (remainder > 0 ? 1 : 0)
  targetAfternoon = basePerPeriod + (remainder > 1 ? 1 : 0)
  targetEvening = basePerPeriod
  
  // Step 6: Round-robin selection
  result = []
  WHILE result.length < limit:
    IF morningPool.hasNext() AND morningCount < targetMorning:
      result.add(morningPool.next())
    IF afternoonPool.hasNext() AND afternoonCount < targetAfternoon:
      result.add(afternoonPool.next())
    IF eveningPool.hasNext() AND eveningCount < targetEvening:
      result.add(eveningPool.next())
    
    IF no activities added in this iteration:
      BREAK  // All pools exhausted
  
  RETURN result
END FUNCTION
```

### 10.2 Streak Calculation Algorithm

**File:** `lib/services/routine_tracking_service.dart`

```dart
Future<int> getCompletionStreak(String userId) async {
  // 1. Query last 365 days of completions (limit for performance)
  final snapshot = await _completionsCollection
    .where('userId', isEqualTo: userId)
    .where('date', isGreaterThanOrEqualTo: oneYearAgo)
    .orderBy('date', descending: true)
    .limit(400)
    .get();
  
  // 2. Extract unique days with any completion
  final activeDays = <String>{};
  for (doc in snapshot.docs) {
    final completed = doc.data()['completedActivities'] ?? [];
    if (completed.isEmpty) continue;
    
    final date = doc.data()['date'].toDate();
    final dayKey = '${date.year}-${date.month}-${date.day}';
    activeDays.add(dayKey);
  }
  
  // 3. Count consecutive days from today backwards
  var streak = 0;
  var cursor = today;
  while (true) {
    final dayKey = '${cursor.year}-${cursor.month}-${cursor.day}';
    if (!activeDays.contains(dayKey)) break;
    
    streak++;
    cursor = cursor.subtract(Duration(days: 1));
  }
  
  return streak;
}
```

**Complexity:** O(n) where n = number of completion records (max 400)

---

## Summary

MindNest is a well-architected Flutter application using:

- **Clean Architecture** with clear separation of concerns (UI → Providers → Services → Database)
- **Riverpod** for reactive state management with automatic disposal
- **Firebase** for authentication, real-time database, and security
- **Google Gemini** for AI personalization with multi-model fallback
- **Feature-based modular structure** for maintainability
- **Comprehensive gamification** via badges and streaks
- **Personalization engine** that adapts content based on user motives and check-in data

The application demonstrates best practices for:
- Error handling at multiple layers
- Firestore query optimization (single-doc reads, limits, indexes)
- Security (Firestore rules, .env for secrets)
- User experience (adaptive routines, personalized AI, real-time updates)

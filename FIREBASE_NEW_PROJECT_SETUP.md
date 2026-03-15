# Firebase New Project Setup Guide

## 1. Create New Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name (e.g., "mindnest-v2")
4. Enable Google Analytics (optional)
5. Choose or create Analytics account

## 2. Enable Required Services

### Authentication
- Go to Authentication → Sign-in method
- Enable Email/Password
- Enable Google Sign-in
- Add your domain to authorized domains

### Firestore Database
- Go to Firestore Database
- Click "Create database"
- Choose "Start in test mode" (we'll add rules later)
- Select location (choose closest to your users)

### Storage (if needed for user uploads)
- Go to Storage
- Click "Get started"
- Choose security rules mode

## 3. Database Structure Overview

Your MindNest app uses the following Firestore collections and structure:

### Main Collections
#### 1. users/{userId}
```json
{
  "uid": "string",
  "email": "string", 
  "displayName": "string",
  "createdAt": "timestamp",
  "lastLogin": "timestamp",
  "photoURL": "string?",
  "signInMethod": "string?",
  "loginDates": ["timestamp[]"],
  "sleepData": {
    "bedtime": "string",
    "wakeTime": "string", 
    "sleepQuality": "number"
  },
  "primaryMotive": "Sleep|Stress|Anxiety|Focus|Habit Building",
  "secondaryMotives": ["string[]"],
  "preferredTime": "Morning|Afternoon|Evening|Before Bed",
  "dailyCommitment": "5min|10min|15min|30+min"
}
```

**Subcollections:**
- `users/{userId}/meditation_stats/{statsId}`
- `users/{userId}/dailyMotives/{motiveId}` 
- `users/{userId}/sleepData/{sleepId}`
- `users/{userId}/activity_stats/{activityId}`
- `users/{userId}/loginTracking/{monthKey}` (optimized login tracking)

#### 2. daily_checkins/{checkInId}
```json
{
  "userId": "string",
  "date": "timestamp",
  "mood": "number (1-10)",
  "energy": "number (1-10)", 
  "stress": "number (1-10)",
  "sleep": "number (1-10)",
  "notes": "string?",
  "completedActivities": ["string[]"],
  "createdAt": "timestamp"
}
```
#### 3. meditation_sessions/{sessionId}
```json
{
  "userId": "string",
  "type": "guided|breathing|visualization",
  "duration": "number (minutes)",
  "completed": "boolean",
  "startTime": "timestamp",
  "endTime": "timestamp?",
  "technique": "string",
  "notes": "string?",
  "rating": "number (1-5)?",
  "moodBefore": "number (1-10)?",
  "moodAfter": "number (1-10)?"
}
```

#### 4. mood_sessions/{sessionId}
```json
{
  "userId": "string",
  "techniqueId": "string",
  "preMoodRating": "number (1-10)?",
  "postMoodRating": "number (1-10)?", 
  "startTime": "timestamp",
  "endTime": "timestamp?",
  "moodImprovement": "number?"
}
```

#### 5. smart_goals/{goalId}
```json
{
  "userId": "string",
  "title": "string",
  "description": "string",
  "category": "meditation|sleep|exercise|habit",
  "targetValue": "number",
  "currentValue": "number",
  "unit": "string",
  "deadline": "timestamp",
  "isCompleted": "boolean",
  "createdAt": "timestamp",
  "completedAt": "timestamp?"
}
```
#### 6. routine_completions/{completionId}
```json
{
  "userId": "string",
  "date": "string (YYYY-MM-DD)",
  "completedActivities": {
    "meditation": "boolean",
    "exercise": "boolean", 
    "journaling": "boolean",
    "reading": "boolean"
  },
  "totalCompleted": "number",
  "streakCount": "number",
  "timestamp": "timestamp"
}
```

#### 7. focus_sessions/{sessionId}
```json
{
  "userId": "string",
  "duration": "number (minutes)",
  "completed": "boolean",
  "startTime": "timestamp",
  "endTime": "timestamp?",
  "technique": "pomodoro|deep_work|time_blocking",
  "distractions": "number",
  "productivity": "number (1-10)?",
  "notes": "string?"
}
```

#### 8. journal_entries/{entryId}
```json
{
  "userId": "string",
  "title": "string",
  "content": "string",
  "mood": "number (1-10)?",
  "tags": ["string[]"],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```
#### 9. motive_adaptations/{adaptationId}
```json
{
  "userId": "string",
  "motive": "string",
  "adaptationType": "technique|timing|frequency",
  "oldValue": "string",
  "newValue": "string", 
  "reason": "string",
  "timestamp": "timestamp",
  "effectiveness": "number (1-10)?"
}
```

#### 10. badges/{userId}/earned/{badgeId}
```json
{
  "badgeId": "string",
  "earnedAt": "timestamp",
  "category": "meditation|streak|goal|milestone",
  "description": "string"
}
```

## 4. Firestore Security Rules

Copy the rules from your `firestore.rules` file to the new project:

1. Go to Firestore → Rules
2. Replace the default rules with your custom rules
3. Click "Publish"

## 5. Firestore Indexes

Your app requires these composite indexes:

### Required Indexes
```javascript
// For meditation sessions by user and date
{
  "collectionGroup": "meditation_sessions",
  "queryScope": "COLLECTION", 
  "fields": [
    {"fieldPath": "userId", "order": "ASCENDING"},
    {"fieldPath": "startTime", "order": "DESCENDING"}
  ]
}
```
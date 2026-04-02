# Connectivity Notifications Implementation Summary
**Date**: April 2, 2026  
**Approach**: One-time SnackBar notifications on connectivity transitions  
**Risk Level**: MINIMAL - Non-invasive, no layout changes

---

## Implementation Details

### File Modified
**`lib/screens/home_screen.dart`** - Main navigation parent screen

### Why This File Was Chosen
1. **Remains Mounted**: HomeScreen stays mounted while users navigate between tabs (Home, Calm, Chat, Profile)
2. **Has Scaffold Context**: Reliable ScaffoldMessenger access for SnackBars
3. **Global Scope**: Notifications visible regardless of which tab user is on
4. **Stable Lifecycle**: initState/dispose called once per app session (unless user logs out)
5. **Non-Crowded**: Clean structure with clear state management

**Alternative Considered**: main.dart app shell - rejected because it's more complex and HomeScreen is simpler

---

## Changes Made

### 1. Added Imports
```dart
import 'dart:async';
import '../features/calm/application/offline_data_service.dart';
```

### 2. Added State Fields
```dart
StreamSubscription<bool>? _connectivitySubscription;
bool? _previousOfflineState; // null = not initialized
```

### 3. Added initState Method
- Calls `_setupConnectivityListener()`
- Sets initial state without showing notification
- Subscribes to `OfflineDataService.instance.offlineStatusStream`

### 4. Added _setupConnectivityListener Method
- Gets OfflineDataService instance
- Stores initial offline state
- Listens to connectivity changes
- Only triggers notification on actual state transitions
- Checks `mounted` before showing notifications

### 5. Added _showConnectivityNotification Method
- Hides any existing SnackBar first (prevents stacking)
- Shows floating SnackBar with:
  - Icon (cloud_off for offline, cloud_done for online)
  - Message text
  - Orange background for offline, green for online
  - 3-second duration
  - Positioned above bottom navigation (margin: bottom 100px)

### 6. Added dispose Method
- Cancels StreamSubscription
- Prevents memory leaks

---

## Behavior

### App Starts Online
1. `initState` runs
2. `_previousOfflineState` set to `false` (online)
3. **No notification shown** (initial state, not a transition)
4. User sees normal app

### App Starts Offline
1. `initState` runs
2. `_previousOfflineState` set to `true` (offline)
3. **No notification shown** (initial state, not a transition)
4. User sees normal app
5. When connection restored, notification shows: "Back online: syncing changes..."

### Online → Offline Transition
1. Connectivity changes
2. Stream emits `isOffline = true`
3. Detects transition (`_previousOfflineState` was `false`, now `true`)
4. Shows SnackBar: **"Offline mode: changes will sync when connected"**
5. Orange background, cloud_off icon
6. Disappears after 3 seconds
7. Updates `_previousOfflineState` to `true`

### Offline → Online Transition
1. Connectivity changes
2. Stream emits `isOffline = false`
3. Detects transition (`_previousOfflineState` was `true`, now `false`)
4. Shows SnackBar: **"Back online: syncing changes..."**
5. Green background, cloud_done icon
6. Disappears after 3 seconds
7. Updates `_previousOfflineState` to `false`

### Rapid Transitions
- Previous SnackBar hidden before showing new one
- No stacking or overlap
- Each transition shows exactly one notification

### Screen Navigation
- User switches tabs (Home → Calm → Chat → Profile)
- HomeScreen remains mounted
- Connectivity listener stays active
- Notifications show regardless of current tab

---

## Assumptions Made

### Widget Lifecycle
- HomeScreen is created once per app session
- HomeScreen is disposed when user logs out or app closes
- HomeScreen remains mounted during tab navigation
- Scaffold context is always available when mounted

### Scaffold Context
- ScaffoldMessenger.of(context) is available
- SnackBars can be shown from HomeScreen
- Floating SnackBars position correctly above bottom navigation

### OfflineDataService
- Service is initialized before HomeScreen is created
- `offlineStatusStream` emits boolean values
- `isOffline` getter returns current state
- Service remains available throughout app lifecycle

---

## Technical Safety Features

### Memory Management
- ✅ StreamSubscription stored and cancelled in dispose()
- ✅ No memory leaks
- ✅ Proper cleanup on widget disposal

### State Management
- ✅ Tracks previous state to detect transitions
- ✅ Only shows notifications on actual changes
- ✅ No repeated notifications on rebuilds
- ✅ Null-safe initial state handling

### UI Safety
- ✅ Checks `mounted` before showing SnackBar
- ✅ Hides existing SnackBar before showing new one
- ✅ No layout changes or permanent UI elements
- ✅ Non-blocking, dismissible notifications
- ✅ Positioned above bottom navigation (no overlap)

### Error Handling
- ✅ Try-catch around listener setup
- ✅ Graceful failure if OfflineDataService not available
- ✅ Debug print for troubleshooting
- ✅ App continues normally if listener fails

---

## Remaining Risks

### Low Risk
1. **SnackBar Timing**: If user navigates away immediately, they might miss notification
   - **Mitigation**: 3-second duration is reasonable
   - **Impact**: Minimal - user will see next transition

2. **Multiple HomeScreen Instances**: If app architecture creates multiple instances
   - **Mitigation**: Unlikely with current navigation structure
   - **Impact**: Would show duplicate notifications

3. **Scaffold Context Loss**: If HomeScreen loses Scaffold context
   - **Mitigation**: Checks `mounted` before showing
   - **Impact**: Notification silently fails, no crash

### No Risk
- ✅ No breaking changes to existing code
- ✅ No layout modifications
- ✅ No persistent UI elements
- ✅ No navigation changes
- ✅ No state management changes

---

## Testing Notes

### Manual Test 1: Online → Offline
1. Start app with WiFi on
2. Turn WiFi off
3. **Expected**: Orange SnackBar appears: "Offline mode: changes will sync when connected"
4. SnackBar disappears after 3 seconds
5. Complete a routine or technique
6. Should work offline

### Manual Test 2: Offline → Online
1. App running with WiFi off
2. Turn WiFi on
3. **Expected**: Green SnackBar appears: "Back online: syncing changes..."
4. SnackBar disappears after 3 seconds
5. Check logs for "Sync completed"

### Manual Test 3: App Starts Offline
1. Turn WiFi off
2. Start app
3. **Expected**: No notification on startup
4. Turn WiFi on
5. **Expected**: Green SnackBar appears

### Manual Test 4: App Starts Online
1. WiFi is on
2. Start app
3. **Expected**: No notification on startup
4. Turn WiFi off
5. **Expected**: Orange SnackBar appears

### Manual Test 5: Rapid Transitions
1. Turn WiFi on/off rapidly (5 times)
2. **Expected**: Each transition shows one notification
3. No stacking or overlap
4. Previous notification hidden before new one shows

### Manual Test 6: Tab Navigation
1. Turn WiFi off (see orange notification)
2. Switch to Calm tab
3. Turn WiFi on
4. **Expected**: Green notification shows on Calm tab
5. Notifications work on all tabs

### Manual Test 7: Background/Foreground
1. Turn WiFi off
2. Put app in background
3. Turn WiFi on
4. Bring app to foreground
5. **Expected**: Green notification shows (if transition detected)

---

## Comparison with Persistent Banner

### Persistent Banner (Not Implemented)
- ❌ Permanent layout change
- ❌ Takes up screen space
- ❌ Always visible when offline
- ❌ Requires careful positioning
- ❌ Can interfere with content

### SnackBar Notifications (Implemented)
- ✅ No layout changes
- ✅ Temporary, non-intrusive
- ✅ Only shows on transitions
- ✅ Auto-dismisses
- ✅ Doesn't interfere with content
- ✅ Familiar UI pattern

---

## Files Status

### Modified
- `lib/screens/home_screen.dart` - Added connectivity notifications

### Unchanged (Kept for Future Use)
- `lib/widgets/common/offline_banner.dart` - Persistent banner widget (not used)
- Can be used later if persistent indicator is desired
- No compile issues, just unused

---

## Lines of Code

**Total Changes**: ~80 lines added to home_screen.dart
- 2 imports
- 2 state fields
- 3 methods (initState, _setupConnectivityListener, _showConnectivityNotification)
- 1 dispose method

**Impact**: Minimal, isolated to one file

---

## Success Criteria Met ✅

- [x] Shows one-time message when app goes offline
- [x] Shows one-time message when app comes back online
- [x] Avoids permanent layout changes
- [x] Avoids modifying crowded screens unnecessarily
- [x] Messages shown only on transitions, not on rebuilds
- [x] No "Back online" message on initial app startup if online
- [x] No spam if app starts offline
- [x] Uses SnackBar for minimal UI risk
- [x] Reuses existing OfflineDataService
- [x] Proper StreamSubscription management
- [x] Tracks previous state for transition detection
- [x] No new architecture or global state
- [x] Minimal and additive changes
- [x] File compiles successfully

---

## Conclusion

Successfully implemented non-invasive connectivity notifications using SnackBars in HomeScreen. The implementation:
- ✅ Shows clear user feedback on connectivity changes
- ✅ Requires no layout modifications
- ✅ Uses familiar UI patterns
- ✅ Has minimal code footprint
- ✅ Properly manages resources
- ✅ Works across all navigation tabs
- ✅ Compiles without errors

**Ready for manual testing!**

---

**Document Version**: 1.0  
**Implementation Date**: April 2, 2026  
**Implemented By**: Kiro AI Assistant  
**Status**: COMPLETE - Ready for Testing

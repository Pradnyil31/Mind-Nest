# Manual Step: Add Offline Banner to HomeScreen

## Why Manual Step Required

The `home_screen.dart` file has complex nested Scaffold structure that makes automated modification risky. The import is already added, but the widget placement needs manual integration to avoid breaking the existing layout.

---

## Step-by-Step Instructions

### Option 1: Add to Inner Scaffold Body (Recommended)

Find this section in `lib/screens/home_screen.dart` (around line 107):

```dart
        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          extendBody: true,
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: Container(
```

Replace with:

```dart
        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          extendBody: true,
          body: Stack(
            children: [
              IndexedStack(index: _currentIndex, children: _screens),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: OfflineBanner(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
```

---

### Option 2: Add to Outer Stack (Alternative)

If Option 1 doesn't work due to layout issues, find the outer Stack (around line 85):

```dart
              body: Stack(
                children: [
                  // Background
                  Container(color: _getBackgroundColor()),
                  Positioned(
                    top: -100,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeAssetImage(
                      _getBackgroundImage(),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Positioned.fill(child: Container(color: Colors.white.withOpacity(0.1))),

                  Scaffold(
```

Add the banner before the inner Scaffold:

```dart
              body: Stack(
                children: [
                  // Background
                  Container(color: _getBackgroundColor()),
                  Positioned(
                    top: -100,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeAssetImage(
                      _getBackgroundImage(),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Positioned.fill(child: Container(color: Colors.white.withOpacity(0.1))),

                  Scaffold(
                    // ... existing scaffold code
                  ),

                  // Add banner on top of everything
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: OfflineBanner(),
                    ),
                  ),
                ],
              ),
```

---

## Verification

After adding the banner:

1. Save the file
2. Run `flutter analyze lib/screens/home_screen.dart`
3. Should show no errors
4. Run the app
5. Turn off WiFi
6. Orange banner should appear at top of screen
7. Turn on WiFi
8. Banner should disappear

---

## Troubleshooting

### Banner Not Showing
- Check logs for "Offline service initialized successfully"
- Check logs for "Connectivity changed: offline"
- Verify OfflineBanner widget is in the Stack children
- Verify SafeArea is wrapping the banner

### Layout Issues
- Try Option 2 if Option 1 causes layout problems
- Adjust `top` position if banner is hidden behind other widgets
- Check z-index by placing banner last in Stack children

### Banner Shows When Online
- Check logs for connectivity state
- Verify WiFi is actually on
- Check if offline service initialized correctly

---

## Alternative: Skip Banner for Now

If you want to test offline functionality without the banner:

1. Skip this manual step entirely
2. Check logs instead of UI for offline status
3. Look for these log messages:
   - "Connectivity changed: offline"
   - "Routine completion queued offline"
   - "Technique completion queued offline"
   - "Sync completed"

The offline functionality works without the banner - it's just a visual indicator for users.

---

## Import Already Added

The import is already in place:

```dart
import '../widgets/common/offline_banner.dart';
```

You only need to add the widget to the UI, not the import.

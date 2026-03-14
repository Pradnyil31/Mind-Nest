import 'package:flutter/material.dart';
import 'mood_tracking_service.dart';
import 'calm_progress_service.dart';
import '../../../widgets/calm/mood_tracking_dialog.dart';
import '../../../core/logger.dart';

/// Example integration showing how MoodTrackingService works with calm techniques
/// This demonstrates the complete flow from pre-mood to post-mood tracking
class MoodTrackingIntegrationExample {
  final MoodTrackingService _moodTrackingService = MoodTrackingService();
  final CalmProgressService _progressService = CalmProgressService();

  /// Complete technique session with mood tracking
  /// This is the main integration point for the calm system
  Future<void> executeTechniqueWithMoodTracking({
    required BuildContext context,
    required String userId,
    required String techniqueId,
    required String techniqueName,
    required int durationMinutes,
    required VoidCallback onTechniqueStart,
    required VoidCallback onTechniqueComplete,
  }) async {
    try {
      // Step 1: Show pre-mood dialog and collect rating
      final preMoodRating = await MoodTrackingDialog.showPreMoodDialog(
        context,
        techniqueName: techniqueName,
        onRatingSubmitted: (rating) async {
          // This will be handled by the dialog
        },
      );

      if (preMoodRating == null) {
        // User skipped mood tracking, proceed without it
        onTechniqueStart();
        return;
      }

      // Step 2: Start mood tracking session
      final moodSessionId = await _progressService.startTechniqueSession(
        userId: userId,
        techniqueId: techniqueId,
        preMoodRating: preMoodRating,
      );

      // Step 3: Execute the technique
      onTechniqueStart();

      // Wait for technique completion (this would be handled by the technique UI)
      // In real implementation, this would be triggered by technique completion
      await _waitForTechniqueCompletion();

      // Step 4: Show post-mood dialog and collect rating
      if (!context.mounted) return;

      final postMoodRating = await MoodTrackingDialog.showPostMoodDialog(
        context,
        techniqueName: techniqueName,
        previousRating: preMoodRating,
        onRatingSubmitted: (rating) async {
          // This will be handled by the dialog
        },
      );

      if (postMoodRating == null) {
        // User skipped post-mood rating, complete without it
        onTechniqueComplete();
        return;
      }

      // Step 5: Complete the session with mood tracking
      await _progressService.completeTechniqueSession(
        userId: userId,
        moodSessionId: moodSessionId,
        techniqueId: techniqueId,
        techniqueName: techniqueName,
        durationMinutes: durationMinutes,
        postMoodRating: postMoodRating,
      );

      onTechniqueComplete();

      // Step 6: Show improvement feedback (optional)
      final improvement = postMoodRating - preMoodRating;
      if (improvement > 0 && context.mounted) {
        _showImprovementFeedback(context, improvement);
      }
    } catch (e) {
      // Handle errors gracefully
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error tracking mood: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Still allow technique to complete
      onTechniqueComplete();
    }
  }

  /// Get mood trends for display in progress widgets
  Future<Map<String, dynamic>> getMoodTrendsForUser(String userId) async {
    return await _moodTrackingService.getMoodTrends(userId);
  }

  /// Check if user has mood tracking data for personalization
  Future<bool> hasUserMoodData(String userId) async {
    return await _moodTrackingService.hasAnyMoodData(userId);
  }

  /// Get technique effectiveness for recommendations
  Future<Map<String, double>> getTechniqueEffectiveness(String userId) async {
    return await _moodTrackingService.getTechniqueEffectiveness(userId);
  }

  /// Private helper methods
  Future<void> _waitForTechniqueCompletion() async {
    // In real implementation, this would be replaced by actual technique completion logic
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showImprovementFeedback(BuildContext context, int improvement) {
    String message;
    IconData icon;
    Color color;

    if (improvement >= 3) {
      message = 'Great improvement! You feel $improvement points better! 🎉';
      icon = Icons.celebration;
      color = Colors.green;
    } else if (improvement > 0) {
      message =
          'Nice! You feel $improvement point${improvement > 1 ? 's' : ''} better! 😊';
      icon = Icons.mood;
      color = Colors.blue;
    } else {
      return; // Don't show feedback for no improvement
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Usage example in a technique screen
class TechniqueScreenExample extends StatefulWidget {
  final String techniqueId;
  final String techniqueName;

  const TechniqueScreenExample({
    super.key,
    required this.techniqueId,
    required this.techniqueName,
  });

  @override
  State<TechniqueScreenExample> createState() => _TechniqueScreenExampleState();
}

class _TechniqueScreenExampleState extends State<TechniqueScreenExample> {
  final MoodTrackingIntegrationExample _integration =
      MoodTrackingIntegrationExample();
  bool _isExecuting = false;

  Future<void> _startTechnique() async {
    setState(() {
      _isExecuting = true;
    });

    await _integration.executeTechniqueWithMoodTracking(
      context: context,
      userId: 'current-user-id', // Get from auth service
      techniqueId: widget.techniqueId,
      techniqueName: widget.techniqueName,
      durationMinutes: 5, // Technique duration
      onTechniqueStart: () {
        // Start technique UI
        appLogger.i('Starting technique: ${widget.techniqueName}');
      },
      onTechniqueComplete: () {
        // Complete technique UI
        appLogger.i('Completed technique: ${widget.techniqueName}');
        setState(() {
          _isExecuting = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.techniqueName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.techniqueName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isExecuting ? null : _startTechnique,
              child: _isExecuting
                  ? const CircularProgressIndicator()
                  : const Text('Start with Mood Tracking'),
            ),
          ],
        ),
      ),
    );
  }
}

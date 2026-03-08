import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/guided_meditation.dart';
import '../models/meditation_session.dart';
import '../services/auth_service.dart';
import '../services/meditation_service.dart';
import '../services/meditation_analytics_service.dart';

class MeditationPlayerScreen extends StatefulWidget {
  final GuidedMeditation meditation;

  const MeditationPlayerScreen({super.key, required this.meditation});

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen> with TickerProviderStateMixin {
  bool _isActive = false;
  int _currentStep = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  void _startMeditation() {
    setState(() {
      _isActive = true;
      _remainingSeconds = widget.meditation.durationMinutes * 60;
      _currentStep = 0;
    });

    // Calculate seconds per step
    final secondsPerStep = (_remainingSeconds / widget.meditation.scriptSteps.length).floor();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          // Move to next step based on time
          final elapsed = (widget.meditation.durationMinutes * 60) - _remainingSeconds;
          _currentStep = (elapsed / secondsPerStep).floor().clamp(0, widget.meditation.scriptSteps.length - 1);
        });
      } else {
        _completeMeditation();
      }
    });
  }

  Future<void> _completeMeditation() async {
    _timer?.cancel();
    
    final user = AuthService().currentUser;
    if (user != null) {
      // Save session
      final session = MeditationSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        startTime: DateTime.now(),
        durationMinutes: widget.meditation.durationMinutes,
        type: MeditationType.guided,
        meditationId: widget.meditation.id,
        completed: true,
      );
      await MeditationService().saveSession(session);

      // Update analytics
      await MeditationAnalyticsService().updateStats(user.uid, widget.meditation.durationMinutes);
    }

    setState(() => _isActive = false);

    if (mounted) {
      // Get updated streak
      final streak = user != null 
          ? await MeditationAnalyticsService().getCurrentStreak(user.uid)
          : 0;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('✨ Session Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Great job completing "${widget.meditation.title}"!',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9575CD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        '$streak Day Streak!',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF9575CD),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to meditation library
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  void _stopMeditation() {
    _timer?.cancel();
    setState(() => _isActive = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isActive) {
      return _buildActiveView();
    }
    return _buildPreparationView();
  }

  Widget _buildPreparationView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9575CD).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(widget.meditation.category),
                        size: 80,
                        color: const Color(0xFF9575CD),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.meditation.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.meditation.description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoChip(
                          '${widget.meditation.durationMinutes} min',
                          Icons.access_time,
                        ),
                        const SizedBox(width: 16),
                        _buildInfoChip(
                          widget.meditation.difficulty,
                          Icons.bar_chart,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startMeditation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9575CD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Begin Meditation',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveView() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Stack(
          children: [
            // Breathing animation
            Center(
              child: AnimatedBuilder(
                animation: _breathingController,
                builder: (context, child) {
                  return Container(
                    width: 300 + (_breathingController.value * 20),
                    height: 300 + (_breathingController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF9575CD).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Timer
                    Text(
                      _formatTime(_remainingSeconds),
                      style: GoogleFonts.lato(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Current meditation step
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        widget.meditation.scriptSteps[_currentStep],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: Colors.white,
                          height: 1.6,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Step indicator
                    Text(
                      'Step ${_currentStep + 1} of ${widget.meditation.scriptSteps.length}',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stop button
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.large(
                  onPressed: _stopMeditation,
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.stop),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9575CD)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(MeditationCategory category) {
    switch (category) {
      case MeditationCategory.sleep:
        return Icons.nightlight_round;
      case MeditationCategory.stress:
        return Icons.spa;
      case MeditationCategory.focus:
        return Icons.center_focus_strong;
      case MeditationCategory.anxiety:
        return Icons.waves;
      case MeditationCategory.mindfulness:
        return Icons.self_improvement;
      case MeditationCategory.compassion:
        return Icons.favorite;
    }
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

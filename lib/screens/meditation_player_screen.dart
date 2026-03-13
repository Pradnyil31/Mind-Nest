import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/guided_meditation.dart';
import '../models/meditation_session.dart';
import '../services/auth_service.dart';
import '../services/meditation_service.dart';
import '../services/meditation_analytics_service.dart';
import '../services/voice_service.dart';

class MeditationPlayerScreen extends StatefulWidget {
  final GuidedMeditation meditation;

  const MeditationPlayerScreen({Key? key, required this.meditation}) : super(key: key);

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen> with TickerProviderStateMixin {
  bool _isActive = false;
  int _currentStep = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  late AnimationController _breathingController;
  late AnimationController _bgController;
  final VoiceService _voice = VoiceService();
  int _lastSpokenStep = -1;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _voice.init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    _bgController.dispose();
    _voice.dispose();
    super.dispose();
  }

  // Returns the psychology-backed gradient pair for this meditation's category
  List<Color> _getCategoryColors() {
    switch (widget.meditation.category) {
      case MeditationCategory.sleep:
        return [const Color(0xFF0D1B2A), const Color(0xFF1B2845)];
      case MeditationCategory.stress:
        return [const Color(0xFF1A2E3A), const Color(0xFF1F2D3B)];
      case MeditationCategory.anxiety:
        return [const Color(0xFF1A3A35), const Color(0xFF1E3040)];
      case MeditationCategory.focus:
        return [const Color(0xFF0B1D2E), const Color(0xFF1A2A3F)];
      case MeditationCategory.mindfulness:
        return [const Color(0xFF2A1F3D), const Color(0xFF1F1F3A)];
      case MeditationCategory.compassion:
        return [const Color(0xFF2E1A2A), const Color(0xFF3A1F30)];
    }
  }

  void _startMeditation() {
    setState(() {
      _isActive = true;
      _remainingSeconds = widget.meditation.durationMinutes * 60;
      _currentStep = 0;
      _lastSpokenStep = -1;
    });

    // Speak the very first step immediately
    _voice.speak(widget.meditation.scriptSteps[0]);
    _lastSpokenStep = 0;

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
        // Speak whenever step index changes
        if (_currentStep != _lastSpokenStep) {
          _lastSpokenStep = _currentStep;
          _voice.speak(widget.meditation.scriptSteps[_currentStep]);
        }
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
                    color: const Color(0xFF9575CD).withAlpha(25),
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
    _voice.stop();
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
                        color: const Color(0xFF9575CD).withValues(alpha: 0.15),
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
    final colors = _getCategoryColors();
    final labels = widget.meditation.stepLabels;
    final totalSteps = widget.meditation.scriptSteps.length;
    final accentColor = colors[1];

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          final t = _bgController.value;
          final bg1 = Color.lerp(colors[0], colors[1], t)!;
          final bg2 = Color.lerp(colors[1], colors[0], t)!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg1, bg2],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // --- Floating orbs ---
                  // Orb top-left
                  Positioned(
                    top: -80 + (t * 30),
                    left: -100 + (t * 20),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentColor.withAlpha(38),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Orb bottom-right
                  Positioned(
                    bottom: -60 + (t * 25),
                    right: -80 + (t * 15),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colors[0].withAlpha(60),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Orb center-right
                  Positioned(
                    top: 200 - (t * 20),
                    right: -60,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentColor.withAlpha(25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- Header row ---
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _stopMeditation,
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                        Text(
                          widget.meditation.title,
                          style: GoogleFonts.lato(
                            color: Colors.white54,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                        // Mute button
                        StatefulBuilder(
                          builder: (ctx, setLS) => IconButton(
                            icon: Icon(
                              _voice.isEnabled
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () async {
                              await _voice.setEnabled(!_voice.isEnabled);
                              setLS(() {});
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Central content ---
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulsing breath orb (decorative)
                        AnimatedBuilder(
                          animation: _breathingController,
                          builder: (_, __) => Container(
                            width: 120 + (_breathingController.value * 16),
                            height: 120 + (_breathingController.value * 16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withAlpha(
                                  (8 + (_breathingController.value * 10)).round()),
                              border: Border.all(
                                color: Colors.white.withAlpha(
                                    (30 + (_breathingController.value * 20)).round()),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Step label — large, minimal
                        Text(
                          (labels.length > _currentStep)
                              ? labels[_currentStep]
                              : '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Remaining time
                        Text(
                          _formatTime(_remainingSeconds),
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Colors.white38,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Step dots at bottom ---
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalSteps, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentStep ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i == _currentStep
                                ? Colors.white
                                : Colors.white24,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

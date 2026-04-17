import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/guided_meditation.dart';
import '../models/meditation_session.dart';
import '../services/voice_service.dart';
import '../providers/app_providers.dart';
import '../providers/meditation_provider.dart';
import '../widgets/activity_completion_dialog.dart';

class MeditationPlayerScreen extends ConsumerStatefulWidget {
  final GuidedMeditation meditation;

  const MeditationPlayerScreen({super.key, required this.meditation});

  @override
  ConsumerState<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

enum MeditationPhase { script, breathing }

class _MeditationPlayerScreenState extends ConsumerState<MeditationPlayerScreen> with TickerProviderStateMixin {
  bool _isActive = false;
  int _currentStep = 0;
  int _remainingSeconds = 0;
  Timer? _sessionTimer;
  Timer? _stepTimer;
  late AnimationController _breathingController;
  late AnimationController _bgController;
  DateTime? _sessionStartedAt;
  late final VoiceService _voice;
  
  MeditationPhase _phase = MeditationPhase.script;
  bool _isInhale = true;
  String _lastSpokenPhase = '';

  @override
  void initState() {
    super.initState();
    _voice = ref.read(voiceServiceProvider);
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
      if (!mounted) return;
      // During the breathing phase: speak Inhale/Exhale in sync with animation
      // During the script phase: animation runs silently (orb still pulses)
      if (status == AnimationStatus.completed) {
        if (_phase == MeditationPhase.breathing) {
          setState(() => _isInhale = false);
          _speakPhaseInstruction('Exhale');
        }
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_phase == MeditationPhase.breathing) {
          setState(() => _isInhale = true);
          _speakPhaseInstruction('Inhale');
        }
        _breathingController.forward();
      }
    });
    _breathingController.forward();
    
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _voice.init();
  }

  // Speak during the continuous breathing phase (deduped)
  void _speakPhaseInstruction(String text) {
    if (_lastSpokenPhase != text) {
      _lastSpokenPhase = text;
      _voice.speak(text);
    }
  }

  /// Estimate how many seconds to display a script step.
  /// Uses a comfortable reading/listening pace of ~2.5 words/sec.
  int _stepDurationSeconds(String text) {
    final wordCount = text.trim().split(RegExp(r'\s+')).length;
    final listenSeconds = (wordCount / 2.5).ceil();
    // Minimum 8 seconds, maximum 60 seconds per step
    return listenSeconds.clamp(8, 60);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _stepTimer?.cancel();
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
      _phase = MeditationPhase.script;
      _isInhale = true;
      _sessionStartedAt = DateTime.now();
    });

    _startSessionTimer();
    _startScriptSequence();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        // Timer is king — end the session immediately.
        _completeMeditation();
      }
    });
  }

  /// Timer-driven script sequence. TTS is fire-and-forget narration only.
  /// Each step shows for a duration based on its word count.
  /// The session timer ending always wins and calls _completeMeditation directly.
  void _startScriptSequence() {
    _advanceToStep(0);
  }

  void _advanceToStep(int step) {
    if (!mounted || !_isActive) return;
    final steps = widget.meditation.scriptSteps;

    if (step >= steps.length) {
      // Script done, move to breathing phase if time remains
      if (mounted && _isActive) {
        setState(() {
          _phase = MeditationPhase.breathing;
          _isInhale = true;
          _lastSpokenPhase = '';
        });
        _breathingController.forward(from: 0.0);
        _speakPhaseInstruction('Inhale');
      }
      return;
    }

    setState(() => _currentStep = step);

    // Narrate the step — fire and forget, does NOT gate progression
    _voice.speak(steps[step]);

    // Advance to next step after display duration — always runs regardless of TTS
    final duration = _stepDurationSeconds(steps[step]);
    _stepTimer?.cancel();
    _stepTimer = Timer(Duration(seconds: duration), () {
      if (mounted && _isActive) _advanceToStep(step + 1);
    });
  }

  Future<void> _completeMeditation() async {
    _sessionTimer?.cancel();
    // Stop any in-progress narration so it doesn't replay on unmute
    _voice.stop();
    
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await ActivityCompletionDialog.show(
        context,
        savingText: 'Saving meditation...',
        onComplete: () async {
          // Save session
          final session = MeditationSession(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: user.uid,
            startTime: _sessionStartedAt ?? DateTime.now(),
            durationMinutes: widget.meditation.durationMinutes,
            type: MeditationType.guided,
            meditationId: widget.meditation.id,
            completed: true,
          );
          await ref.read(meditationServiceProvider).saveSession(session);

          // Update analytics
          await ref
              .read(meditationAnalyticsProvider)
              .updateStats(user.uid, widget.meditation.durationMinutes);

          // Log to activity_stats so badge system tracks meditation count
          await ref.read(firestoreServiceProvider).logActivityCompletion(user.uid, 'meditation');
        },
      );
    }

    setState(() {
      _isActive = false;
      _sessionStartedAt = null;
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _stopMeditation() {
    _sessionTimer?.cancel();
    _voice.stop();
    setState(() {
      _isActive = false;
      _sessionStartedAt = null;
    });
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
    final colors = _getCategoryColors();
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient with Mesh Effect
          _buildMeshBackground(colors),

          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Category Icon with glow
                        _buildCategoryHero(colors),
                        const SizedBox(height: 48),
                        // Title & Description
                        Text(
                          widget.meditation.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.meditation.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Glassmorphic Info Grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildGlassChip(
                              '${widget.meditation.durationMinutes}m',
                              Icons.access_time_rounded,
                            ),
                            const SizedBox(width: 16),
                            _buildGlassChip(
                              widget.meditation.difficulty,
                              Icons.bolt_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 100), // Space for button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Button
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: _buildBeginButton(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshBackground(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[0],
            colors[1].withValues(alpha: 0.8),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors[1].withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          ),
          Text(
            'MEDITATION',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 48), // Balance
        ],
      ),
    );
  }

  Widget _buildCategoryHero(List<Color> colors) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated glow
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.3),
                      blurRadius: 40 + (_bgController.value * 20),
                      spreadRadius: 10,
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: Icon(
              _getCategoryIcon(widget.meditation.category),
              size: 64,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassChip(String text, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeginButton(List<Color> colors) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            colors[0],
            colors[1],
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _startMeditation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Text(
          'Begin Meditation',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveView() {
    final colors = _getCategoryColors();
    final labels = widget.meditation.stepLabels;
    final totalSteps = widget.meditation.scriptSteps.length;

    return Scaffold(
      body: Stack(
        children: [
          // Immersive Background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              final t = _bgController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(colors[0], const Color(0xFF0F172A), 0.5)!,
                      Color.lerp(colors[1], const Color(0xFF0F172A), 0.8)!,
                      const Color(0xFF020617),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Moving ambient blobs
                    Positioned(
                      top: 100 + (math.sin(t * math.pi * 2) * 50),
                      left: -50 + (math.cos(t * math.pi * 2) * 30),
                      child: _buildAmbientBlob(colors[0], 300, 0.15),
                    ),
                    Positioned(
                      bottom: 100 + (math.cos(t * math.pi * 2) * 40),
                      right: -50 + (math.sin(t * math.pi * 2) * 40),
                      child: _buildAmbientBlob(colors[1], 350, 0.1),
                    ),
                  ],
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // Minimal Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _stopMeditation,
                        icon: const Icon(Icons.close_rounded, color: Colors.white38),
                      ),
                      Expanded(
                        child: Text(
                          widget.meditation.title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Fluid Visualizer
                      AnimatedBuilder(
                        animation: _breathingController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: MeditationFluidPainter(
                              progress: _breathingController.value,
                              color: colors[0],
                              category: widget.meditation.category,
                            ),
                            size: const Size(double.infinity, double.infinity),
                          );
                        },
                      ),

                      // Central Instruction
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 800),
                            child: Text(
                              _phase == MeditationPhase.breathing
                                  ? (_isInhale ? 'Inhale' : 'Exhale')
                                  : ((labels.length > _currentStep)
                                      ? labels[_currentStep]
                                      : ''),
                              key: ValueKey(_instructionText),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 42,
                                fontWeight: FontWeight.w200,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatTime(_remainingSeconds),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.3),
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Step Progression
                if (_phase == MeditationPhase.script)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: _buildModernStepDots(totalSteps),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _instructionText => _phase == MeditationPhase.breathing
      ? (_isInhale ? 'Inhale' : 'Exhale')
      : ((widget.meditation.stepLabels.length > _currentStep)
          ? widget.meditation.stepLabels[_currentStep]
          : '');

  Widget _buildAmbientBlob(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildModernStepDots(int totalSteps) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isActive = i == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
            boxShadow: isActive ? [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 8,
              )
            ] : null,
          ),
        );
      }),
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

class MeditationFluidPainter extends CustomPainter {
  final double progress;
  final Color color;
  final MeditationCategory category;

  MeditationFluidPainter({
    required this.progress,
    required this.color,
    required this.category,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final baseRadius = math.min(size.width, size.height) * 0.25;
    final pulseRadius = baseRadius + (progress * 50);

    // Draw multiple organic layers
    for (int i = 0; i < 3; i++) {
      _drawOrganicShape(canvas, center, pulseRadius - (i * 20), paint, i);
    }

    // Core glow
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: pulseRadius));
    canvas.drawCircle(center, pulseRadius, corePaint);
  }

  void _drawOrganicShape(Canvas canvas, Offset center, double radius, Paint paint, int index) {
    final path = Path();
    const int segments = 8;
    for (int i = 0; i < segments; i++) {
      final angle = (i * 2 * math.pi / segments);
      // Add some noise/variance to radius
      final variance = math.sin(progress * math.pi * 2 + index + i) * 15;
      final x = center.dx + (radius + variance) * math.cos(angle);
      final y = center.dy + (radius + variance) * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MeditationFluidPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

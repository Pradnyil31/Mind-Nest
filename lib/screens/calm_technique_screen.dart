import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/calm_technique.dart';
import '../services/voice_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/activity_completion_dialog.dart';

class CalmTechniqueScreen extends StatefulWidget {
  final CalmTechnique technique;

  const CalmTechniqueScreen({Key? key, required this.technique}) : super(key: key);

  @override
  State<CalmTechniqueScreen> createState() => _CalmTechniqueScreenState();
}

class _CalmTechniqueScreenState extends State<CalmTechniqueScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _isStarted = false;
  bool _isPaused = false;
  int _countdownSeconds = 0;

  final VoiceService _voice = VoiceService();
  Timer? _stepTimer;
  late AnimationController _progressController;
  late AnimationController _bgController;

  // Returns the two background gradient colors for this technique
  List<Color> _getThemeColors() {
    switch (widget.technique.id) {
      case 'cold-water-visualization':
        return [const Color(0xFF0A1F2E), const Color(0xFF0D2A35)];
      case 'worry-banking':
        return [const Color(0xFF2A1E10), const Color(0xFF2E2018)];
      case '5-4-3-2-1':
      default:
        return [const Color(0xFF112A1A), const Color(0xFF162E22)];
    }
  }

  Color get _techniqueColor {
    switch (widget.technique.type) {
      case TechniqueType.grounding:
        return const Color(0xFF81C784);
      case TechniqueType.affirmation:
        return const Color(0xFF9575CD);
      case TechniqueType.breathing:
        return const Color(0xFF64B5F6);
      case TechniqueType.visualization:
        return const Color(0xFF4DB6AC);
    }
  }

  // Per-step durations. Default for each technique type if not overridden.
  List<int> get _stepDurations {
    final steps = widget.technique.steps ?? [];
    switch (widget.technique.id) {
      case 'cold-water-visualization':
        // Visualization — 12 s per calming beat
        return List.filled(steps.length, 12);
      case 'worry-banking':
        // Reflective steps need more time
        return [15, 20, 20, 20, 15, 20, 15];
      default:
        // Default: 15 s per step
        return List.filled(steps.length, 15);
    }
  }

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _voice.init();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _progressController.dispose();
    _bgController.dispose();
    _voice.dispose();
    super.dispose();
  }

  void _startStep(int step) {
    final steps = widget.technique.steps ?? [];
    if (step >= steps.length) {
      setState(() => _currentStep = steps.length); // completion
      return;
    }

    // Discard stale TTS from the previous step — prevents replay on unmute
    _voice.stop();
    _voice.cancelPendingResume();

    final durations = _stepDurations;
    final dur = (step < durations.length) ? durations[step] : 15;

    setState(() {
      _currentStep = step;
      _countdownSeconds = dur;
      _isPaused = false;
    });

    _progressController.duration = Duration(seconds: dur);
    _progressController.forward(from: 0.0);

    _voice.speak(steps[step]);

    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        _startStep(step + 1);
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _progressController.stop();
    } else {
      _progressController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStarted) return _buildIntroView();
    final steps = widget.technique.steps ?? [];
    final isComplete = _currentStep >= steps.length;
    return isComplete ? _buildCompletionView() : _buildStepView();
  }

  Widget _buildIntroView() {
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
                        color: _techniqueColor.withAlpha(38),
                        shape: BoxShape.circle,
                      ),
                      child: Text(widget.technique.icon, style: const TextStyle(fontSize: 80)),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.technique.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.technique.description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Info chips: duration + voice status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 16, color: _techniqueColor),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.technique.durationMinutes} min',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D2D2D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.record_voice_over, size: 16, color: _techniqueColor),
                              const SizedBox(width: 6),
                              Text(
                                'Voice Guided',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D2D2D),
                                ),
                              ),
                            ],
                          ),
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
                  onPressed: () {
                    setState(() => _isStarted = true);
                    _startStep(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _techniqueColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Begin Exercise',
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

  Widget _buildStepView() {
    final steps = widget.technique.steps!;
    final colors = _getThemeColors();

    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        final t = _bgController.value;
        final bg1 = Color.lerp(colors[0], colors[1], t)!;
        final bg2 = Color.lerp(colors[1], colors[0], t)!;

        return Scaffold(
          body: Container(
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
                  // Decorative orb
                  Positioned(
                    top: -50 + (t * 20),
                    right: -60,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          _techniqueColor.withAlpha(28),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40 + (t * 20),
                    left: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          _techniqueColor.withAlpha(18),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Colors.white54),
                            ),
                            Text(
                              widget.technique.title,
                              style: GoogleFonts.lato(
                                color: Colors.white70,
                                fontSize: 15,
                                letterSpacing: 1.2,
                              ),
                            ),
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
                      // Thin progress line
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 8, 40, 0),
                        child: LinearProgressIndicator(
                          value: _currentStep / steps.length,
                          backgroundColor: Colors.white10,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_techniqueColor),
                          minHeight: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Step content — icon + countdown only
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.technique.icon,
                                    style: const TextStyle(fontSize: 80)),
                                const SizedBox(height: 32),
                                // Step number label
                                Text(
                                  'Step ${_currentStep + 1} of ${steps.length}',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    color: Colors.white54,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                // Countdown ring
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _progressController,
                                        builder: (_, __) =>
                                            CircularProgressIndicator(
                                          value: 1 - _progressController.value,
                                          strokeWidth: 4,
                                          backgroundColor: Colors.white12,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  _techniqueColor),
                                        ),
                                      ),
                                      Text(
                                        '$_countdownSeconds',
                                        style: GoogleFonts.lato(
                                          color: Colors.white70,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Pause button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                        child: TextButton.icon(
                          onPressed: _togglePause,
                          icon: Icon(
                            _isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: Colors.white38,
                          ),
                          label: Text(
                            _isPaused ? 'Resume' : 'Pause',
                            style: GoogleFonts.lato(
                                color: Colors.white38, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionView() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _techniqueColor.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, size: 80, color: _techniqueColor),
                ),
                const SizedBox(height: 32),
                Text(
                  'Exercise Complete!',
                  style: GoogleFonts.lato(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You\'ve completed the ${widget.technique.title} exercise.\nTake a moment to notice how you feel.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.white70, height: 1.6),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final user = AuthService().currentUser;
                      if (user != null) {
                        await ActivityCompletionDialog.show(
                          context,
                          savingText: 'Saving progress...',
                          onComplete: () async {
                            await FirestoreService().logActivityCompletion(user.uid, 'calm_technique');
                          },
                        );
                      }
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _techniqueColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _startStep(0),
                  child: Text('Start Over',
                      style: GoogleFonts.lato(color: Colors.white70, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

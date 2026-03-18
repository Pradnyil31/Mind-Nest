import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/voice_service.dart';

class GroundingExerciseScreen extends StatefulWidget {
  const GroundingExerciseScreen({Key? key}) : super(key: key);

  @override
  State<GroundingExerciseScreen> createState() => _GroundingExerciseScreenState();
}

class _GroundingExerciseScreenState extends State<GroundingExerciseScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _isPaused = false;
  int _countdownSeconds = 0;

  final VoiceService _voice = VoiceService();
  Timer? _stepTimer;
  late AnimationController _progressController;
  late AnimationController _bgController;

  // Short labels shown on screen (voice narrates the full text)
  final List<String> _stepLabels = [
    'Settle & Breathe',
    'Find 5 Things You See',
    'Notice 4 Things You Feel',
    'Hear 3 Sounds',
    'Notice 2 Scents',
    'Notice 1 Taste',
    'Complete',
  ];

  // Step text and matching durations (in seconds)
  final List<String> _steps = [
    'Welcome. We are going to gently guide your mind back to the present moment. Begin by sitting comfortably, with both feet flat on the floor if you can. Close your eyes, or soften your gaze downward. Now take one slow, full breath in through your nose... and release it completely through your mouth. Let your shoulders drop, and let your jaw unclench. You are safe. You are here.',
    'Now, slowly open your eyes and look around you. We are going to find five things you can actually see right now. Take your time with each one — notice its shape, its colour, how the light falls on it. Maybe it is a window, a chair, a pattern on the floor, or the colour of a wall. Silently name each thing in your mind as you notice it. One... two... three... four... five. Well done.',
    'Now bring your attention to what you can physically feel. We are looking for four sensations of touch. Notice the weight of your body on the seat. Feel the texture of your clothing against your skin. Press your feet gently into the floor and feel the ground beneath you. You might notice the temperature of the air on your hands or face. Name four things you can feel, one at a time. Stay with each sensation for a moment before moving to the next.',
    'Now be very still, and just listen. Notice three sounds you can hear right now. They might be close or far away — the hum of a room, a sound from outside, the sound of your own breathing. Do not judge the sounds, just notice them. Hear the first one... then the second... then the third. You are fully present in this moment.',
    'Now turn your attention to your sense of smell. Notice two things you can smell, even faintly. It might be the air in the room, your own skin, fabric nearby, or even just a neutral freshness. If you cannot smell anything, that is perfectly fine — simply bring to mind two scents that you enjoy. Perhaps coffee, rain, or something familiar and comforting. Take a moment to stay with each one.',
    'Finally, bring your attention to your sense of taste. Notice what is present in your mouth right now, however subtle. If you cannot taste anything at all, that is completely normal. Simply bring to mind one food or drink that you truly enjoy. Let yourself imagine the taste, the texture, the warmth or coolness of it. This moment of pleasure belongs entirely to you.',
    'You have done it. You have been present with all five of your senses. Now take three slow, deep breaths together. Breathe in deeply... and out slowly. In again... and out. One final breath in... and a long, complete exhale. Notice how much calmer you feel than when we began. You are grounded. You are present. You are safe. Whenever you feel overwhelmed, you can return to this practice at any time.',
  ];

  final List<String> _stepIcons = ['👀', '5️⃣', '4️⃣', '3️⃣', '2️⃣', '1️⃣', '✅'];

  final List<int> _stepDurations = [45, 50, 50, 45, 40, 38, 50];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: Duration(seconds: _stepDurations[0]));
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat(reverse: true);
    _voice.init().then((_) => _startStep(0));
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
    if (step >= _steps.length) {
      setState(() => _currentStep = _steps.length);
      return;
    }

    // Cancel any stale TTS from the previous step so unmuting won't replay it
    _voice.stop();
    _voice.cancelPendingResume();
    _stepTimer?.cancel();

    setState(() {
      _currentStep = step;
      _countdownSeconds = _stepDurations[step];
      _isPaused = false;
    });

    _progressController.duration = Duration(seconds: _stepDurations[step]);
    _progressController.forward(from: 0.0);

    // Narration: speak the step text (fire-and-forget — does NOT gate progression)
    _voice.speak(_steps[step]);

    // Timer-based progression: always advances regardless of mute state
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        final nextStep = step + 1;
        if (nextStep < _steps.length) {
          _startStep(nextStep);
        } else {
          _startStep(nextStep); // transition to completion
        }
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
    final isComplete = _currentStep >= _steps.length;

    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final t = _bgController.value;
        final bg1 = Color.lerp(const Color(0xFF1A2E1A), const Color(0xFF1E3028), t)!;
        final bg2 = Color.lerp(const Color(0xFF1E3028), const Color(0xFF1A2E1A), t)!;
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
                  // Orb top-right
                  Positioned(
                    top: -60 + (t * 25),
                    right: -80,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFF81C784).withAlpha(30),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                  // Orb bottom-left
                  Positioned(
                    bottom: -40 + (t * 20),
                    left: -60,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFF4CAF50).withAlpha(22),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                  // Main content column
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
                              '5-4-3-2-1 Grounding',
                              style: GoogleFonts.lato(
                                color: Colors.white70,
                                fontSize: 15,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (!isComplete)
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
                              )
                            else
                              const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      // Thin step progress line
                      if (!isComplete)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 8, 40, 0),
                          child: LinearProgressIndicator(
                            value: _currentStep / _steps.length,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF81C784)),
                            minHeight: 2,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            isComplete ? _buildCompletionView() : _buildStepView(),
                      ),
                      // Pause button
                      if (!isComplete)
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

  Widget _buildStepView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step icon — large
            Text(_stepIcons[_currentStep],
                style: const TextStyle(fontSize: 80)),

            const SizedBox(height: 32),

            // Short step label — minimal text
            Text(
              _stepLabels[_currentStep],
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),

            const SizedBox(height: 32),

            // Countdown ring
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (_, __) => CircularProgressIndicator(
                      value: 1 - _progressController.value,
                      strokeWidth: 4,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF81C784)),
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
    );
  }

  Widget _buildCompletionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF81C784).withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 80, color: Color(0xFF81C784)),
            ),
            const SizedBox(height: 32),
            Text(
              'Well Done!',
              style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'You\'ve completed the 5-4-3-2-1 grounding exercise.\nYou are present, calm, and safe.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 16, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF81C784),
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
              child: Text('Start Over', style: GoogleFonts.lato(color: Colors.white70, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

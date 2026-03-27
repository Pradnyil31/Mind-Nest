import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../models/breathing_technique.dart';
import '../services/voice_service.dart';
import '../providers/app_providers.dart';

class BreathingExerciseScreen extends ConsumerStatefulWidget {
  final BreathingTechnique technique;

  const BreathingExerciseScreen({super.key, required this.technique});

  @override
  ConsumerState<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends ConsumerState<BreathingExerciseScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _breatheAnimation;
  
  // Multiple controllers for the "Bloom" layers to allow staggered offsets
  late List<AnimationController> _bloomControllers;
  
  Timer? _timer;
  int _currentStepIndex = 0; // 0=Inhale, 1=Hold, 2=Exhale, 3=Hold
  int _secondsRemaining = 0;
  String _instructionText = 'Get Ready...';
  bool _isActive = false;
  
  // Duration settings
  int? _targetDurationMinutes; // null = open-ended
  int _totalElapsedSeconds = 0;
  bool _isSettingUp = true;

  bool _sessionLogged = false;

  // Voice
  late final VoiceService _voice;
  String _lastSpokenInstruction = '';

  // Background animation
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(voiceServiceProvider);
    _setupAnimations();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
    _voice.init();
    // Do not auto-start; wait for user to select duration
  }

  void _setupAnimations() {
    // Main controller for the core breathing cycle duration
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Will be updated dynamically
    );

    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    // Create 3 staggered bloom layers
    _bloomControllers = List.generate(3, (index) => AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Synced with main
    ));
  }

  void _startSession(int? durationMinutes) {
    setState(() {
      _targetDurationMinutes = durationMinutes;
      _isSettingUp = false;
      _isActive = true;
      _currentStepIndex = -1; // Start before the first step
      _totalElapsedSeconds = 0;
    });
    
    // Initial delay before starting the loop
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _nextStep();
    });
  }

  void _nextStep() {
    if (!mounted || !_isActive) return;
    // Silence stale narration from the previous step before the next one starts
    _voice.stop();

    // Graceful completion: check if time is up when we are about to start a NEW round (index 0)
    // or if we just finished the last step (index 3 or previous was 2/3)
    bool isRoundComplete = _currentStepIndex == widget.technique.pattern.length - 1 || 
                           (_currentStepIndex == 2 && widget.technique.pattern[3] == 0);

    if (isRoundComplete && _totalElapsedSeconds >= (_targetDurationMinutes ?? 0) * 60 && _targetDurationMinutes != null) {
      _sessionLogged = true;
      _timer?.cancel();
      setState(() => _isActive = false);
      _logCompletionAndShowDialog();
      return;
    }

    setState(() {
      _currentStepIndex = (_currentStepIndex + 1) % 4;
      // Skip steps with 0 duration (e.g., 4-7-8 has no hold after exhale)
      while (widget.technique.pattern[_currentStepIndex] == 0) {
        _currentStepIndex = (_currentStepIndex + 1) % 4;
      }

      _secondsRemaining = widget.technique.pattern[_currentStepIndex];
    });

    _updateInstruction();
    _animatePhase();
    _startTimer();
  }

  void _checkDuration() {
    // Only update the timer. Completion check moved to _nextStep for graceful ending.
  }

  Future<void> _logCompletionAndShowDialog() async {
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid != null) {
      await ref.read(firestoreServiceProvider).logActivityCompletion(uid, 'breathing');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🌬️  Session Complete!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          (_targetDurationMinutes != null) 
              ? 'You completed your $_targetDurationMinutes minute breathing session. Great work!'
              : 'You completed a breathing session. Great work!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Reset to setup
              setState(() {
                _sessionLogged = false;
                _isSettingUp = true;
                _totalElapsedSeconds = 0;
              });
            },
            child: const Text('Go Again', style: TextStyle(color: Color(0xFF26C6DA))),
          ),
        ],
      ),
    );
  }  void _updateInstruction() {
    switch (_currentStepIndex) {
      case 0:
        _instructionText = 'Inhale';
        break;
      case 1:
        _instructionText = 'Hold';
        break;
      case 2:
        _instructionText = 'Exhale';
        break;
      case 3:
        _instructionText = 'Hold';
        break;
    }
    // Speak the instruction only when it changes
    if (_instructionText != _lastSpokenInstruction) {
      _lastSpokenInstruction = _instructionText;
      _voice.speak(_instructionText);
    }
  }

  void _animatePhase() {
    final duration = Duration(seconds: _secondsRemaining);
    
    // Reset durations
    _mainController.duration = duration;
    for (var c in _bloomControllers) {
      c.duration = duration;
    }

    if (_currentStepIndex == 0) {
      // Inhale: Expand
      _mainController.forward();
      // Stagger blooms
      for (int i = 0; i < _bloomControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 200), () {
          if (mounted) _bloomControllers[i].forward();
        });
      }
    } else if (_currentStepIndex == 2) {
      // Exhale: Contract
      _mainController.reverse();
      // Stagger blooms reverse
      for (int i = 0; i < _bloomControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 200), () {
          if (mounted) _bloomControllers[i].reverse();
        });
      }
    } 
    // Hold phases (1 & 3): Do nothing, animation stays at end/start
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _totalElapsedSeconds++;
        _checkDuration();
        
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          timer.cancel();
          _nextStep();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mainController.dispose();
    for (var c in _bloomControllers) {
      c.dispose();
    }
    _voice.dispose();
    super.dispose();
  }

  Widget _buildSetupView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF26C6DA).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.air, size: 80, color: Color(0xFF26C6DA)),
            ),
            const SizedBox(height: 32),
            Text(
              widget.technique.title,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select session duration',
              style: GoogleFonts.lato(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDurationOption('1\nmin', 1),
                _buildDurationOption('3\nmin', 3),
                _buildDurationOption('5\nmin', 5),
              ],
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => _startSession(null), // Open-ended
              child: Text(
                'Open-Ended (Continuous)',
                style: GoogleFonts.lato(
                  color: const Color(0xFF6C63FF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOption(String label, int minutes) {
    return GestureDetector(
      onTap: () => _startSession(minutes),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final t = _bgController.value;
        final bg1 = Color.lerp(const Color(0xFF0A1A28), const Color(0xFF0D2233), t)!;
        final bg2 = Color.lerp(const Color(0xFF0D2233), const Color(0xFF0A1A28), t)!;
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
                  // Back Button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white38),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  
            
            // Central Content
            if (_isSettingUp)
              _buildSetupView()
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.technique.title,
                    style: GoogleFonts.lato(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Animation Visualization
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Bloom Layers (Outer Rims)
                         ...List.generate(_bloomControllers.length, (index) {
                           return AnimatedBuilder(
                             animation: _bloomControllers[index],
                             builder: (context, child) {
                               final value = _bloomControllers[index].value;
                               final scale = 1.0 + (0.6 * value) + (index * 0.15);
                               final opacity = 0.2 - (0.05 * index);
                               
                               return Transform.scale(
                                 scale: scale,
                                 child: Container(
                                   width: 200,
                                   height: 200,
                                   decoration: BoxDecoration(
                                     shape: BoxShape.circle,
                                     gradient: RadialGradient(
                                       colors: [
                                         const Color(0xFF1A5276).withAlpha((opacity * value * 255).round()),
                                         const Color(0xFF26C6DA).withAlpha(0),
                                       ],
                                       stops: const [0.2, 1.0],
                                     ),
                                   ),
                                 ),
                               );
                             },
                           );
                         }),

                        // Core Breathing Circle (The "Lung")
                        AnimatedBuilder(
                          animation: _mainController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _breatheAnimation.value,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6C63FF).withAlpha((128 * _mainController.value).round()),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.lerp(const Color(0xFF4A148C), const Color(0xFF26C6DA), _mainController.value)!,
                                      Color.lerp(const Color(0xFF311B92), const Color(0xFF00ACC1), _mainController.value)!,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _secondsRemaining.toString(),
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  Text(
                    _instructionText,
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.technique.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


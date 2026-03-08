import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../models/breathing_technique.dart';

class BreathingExerciseScreen extends StatefulWidget {
  final BreathingTechnique technique;

  const BreathingExerciseScreen({super.key, required this.technique});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _breatheAnimation;
  
  // Multiple controllers for the "Bloom" layers to allow staggered offsets
  late List<AnimationController> _bloomControllers;
  
  Timer? _timer;
  int _currentStepIndex = 0; // 0=Inhale, 1=Hold, 2=Exhale, 3=Hold
  int _secondsRemaining = 0;
  String _instructionText = 'Get Ready...';
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSession();
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

  void _startSession() {
    setState(() {
      _isActive = true;
      _currentStepIndex = -1; // Start before the first step
    });
    
    // Initial delay before starting the loop
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _nextStep();
    });
  }

  void _nextStep() {
    if (!mounted || !_isActive) return;

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

  void _updateInstruction() {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Deep dark peaceful background
      body: SafeArea(
        child: Stack(
          children: [
            // Back Button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            
            // Central Content
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
                               final value = _bloomControllers[index].value; // 0.0 to 1.0
                               final scale = 1.0 + (0.6 * value) + (index * 0.15); // Staggered sizes
                               final opacity = 0.2 - (0.05 * index); // Fading outer layers
                               
                               return Transform.scale(
                                 scale: scale,
                                 child: Container(
                                   width: 200,
                                   height: 200,
                                   decoration: BoxDecoration(
                                     shape: BoxShape.circle,
                                     gradient: RadialGradient(
                                       colors: [
                                         const Color(0xFF6C63FF).withOpacity(opacity * value),
                                         const Color(0xFF26C6DA).withOpacity(0.0), // Fade to transparent
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
                                      color: const Color(0xFF6C63FF).withOpacity(0.5 * _mainController.value),
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
    );
  }
}

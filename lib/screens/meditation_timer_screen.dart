import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meditation_session.dart';
import '../providers/auth_provider.dart';
import '../providers/meditation_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/activity_completion_dialog.dart';

class MeditationTimerScreen extends ConsumerStatefulWidget {
  const MeditationTimerScreen({super.key});

  @override
  ConsumerState<MeditationTimerScreen> createState() => _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends ConsumerState<MeditationTimerScreen> with TickerProviderStateMixin {
  int _selectedDuration = 10; // default 10 minutes
  bool _isActive = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  DateTime? _sessionStartedAt;
  late AnimationController _breathingController;

  final List<int> _durationOptions = [5, 10, 15, 20, 30];

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

  void _startTimer() {
    setState(() {
      _isActive = true;
      _remainingSeconds = _selectedDuration * 60;
      _sessionStartedAt = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    
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
            durationMinutes: _selectedDuration,
            type: MeditationType.timer,
            completed: true,
          );
          await ref.read(meditationServiceProvider).saveSession(session);

          // Update analytics
          await ref.read(meditationAnalyticsProvider).updateStats(user.uid, _selectedDuration);

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

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _sessionStartedAt = null;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isActive) {
      return _buildActiveTimerView();
    }
    return _buildSetupView();
  }

  Widget _buildSetupView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        title: Text(
          'Free Timer',
          style: GoogleFonts.lato(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: Padding(
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
                      color: const Color(0xFF81C784).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.self_improvement,
                      size: 80,
                      color: Color(0xFF81C784),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Meditate Your Way',
                    style: GoogleFonts.lato(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose your duration and find your inner peace',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Duration selection
                  Text(
                    'Duration',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _durationOptions.map((duration) {
                      final isSelected = _selectedDuration == duration;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDuration = duration),
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF81C784) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF81C784) : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: const Color(0xFF81C784).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ] : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                duration.toString(),
                                style: GoogleFonts.lato(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF2D2D2D),
                                ),
                              ),
                              Text(
                                'min',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF81C784),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Start Meditation',
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
    );
  }

  Widget _buildActiveTimerView() {
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
                          const Color(0xFF81C784).withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Timer
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_remainingSeconds),
                    style: GoogleFonts.lato(
                      fontSize: 72,
                      fontWeight: FontWeight.w100,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Breathe and be present',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            // Stop button
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.large(
                  onPressed: _stopTimer,
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

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}


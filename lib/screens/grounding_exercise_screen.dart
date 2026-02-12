import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroundingExerciseScreen extends StatefulWidget {
  const GroundingExerciseScreen({Key? key}) : super(key: key);

  @override
  State<GroundingExerciseScreen> createState() => _GroundingExerciseScreenState();
}

class _GroundingExerciseScreenState extends State<GroundingExerciseScreen> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Take a deep breath and look around you.',
    'Name 5 things you can see around you.',
    'Name 4 things you can physically feel (texture of clothes, ground beneath feet, etc.).',
    'Name 3 things you can hear right now.',
    'Name 2 things you can smell (or 2 scents you like).',
    'Name 1 thing you can taste (or your favorite food).',
    'Take three deep breaths. You are present and safe.',
  ];

  final List<String> _stepIcons = ['👀', '5️⃣', '4️⃣', '3️⃣', '2️⃣', '1️⃣', '✅'];

  @override
  Widget build(BuildContext context) {
    final isComplete = _currentStep >= _steps.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Text(
                    '5-4-3-2-1 Grounding',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the close button
                ],
              ),
            ),

            // Progress indicator
            if (!isComplete)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _steps.length,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
                ),
              ),

            const SizedBox(height: 20),

            // Content
            Expanded(
              child: isComplete ? _buildCompletionView() : _buildStepView(),
            ),

            // Navigation buttons
            if (!isComplete)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: () => setState(() => _currentStep--),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_back, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(
                              'Back',
                              style: GoogleFonts.lato(color: Colors.white70),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(),
                    
                    ElevatedButton(
                      onPressed: () => setState(() => _currentStep++),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81C784),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        _currentStep == _steps.length - 1 ? 'Finish' : 'Next',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildStepView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step icon
            Text(
              _stepIcons[_currentStep],
              style: const TextStyle(fontSize: 80),
            ),
            
            const SizedBox(height: 32),

            // Step instruction
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                _steps[_currentStep],
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 20,
                  color: Colors.white,
                  height: 1.6,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Step counter
            Text(
              'Step ${_currentStep + 1} of ${_steps.length}',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.white60,
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
                color: const Color(0xFF81C784).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: Color(0xFF81C784),
              ),
            ),
            
            const SizedBox(height: 32),

            Text(
              'Well Done!',
              style: GoogleFonts.lato(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'You\'ve completed the 5-4-3-2-1 grounding exercise.\nYou are present, calm, and safe.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.white70,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF81C784),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: Text(
                'Start Over',
                style: GoogleFonts.lato(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

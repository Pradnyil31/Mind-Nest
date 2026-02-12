import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/calm_technique.dart';

class CalmTechniqueScreen extends StatefulWidget {
  final CalmTechnique technique;

  const CalmTechniqueScreen({Key? key, required this.technique}) : super(key: key);

  @override
  State<CalmTechniqueScreen> createState() => _CalmTechniqueScreenState();
}

class _CalmTechniqueScreenState extends State<CalmTechniqueScreen> {
  int _currentStep = 0;
  bool _isStarted = false;

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

  @override
  Widget build(BuildContext context) {
    if (!_isStarted) {
      return _buildIntroView();
    }

    final isComplete = _currentStep >= (widget.technique.steps?.length ?? 0);
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
                        color: _techniqueColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        widget.technique.icon,
                        style: const TextStyle(fontSize: 80),
                      ),
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
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => setState(() => _isStarted = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _techniqueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
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
                    widget.technique.title,
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / steps.length,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(_techniqueColor),
              ),
            ),

            const SizedBox(height: 20),

            // Step content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.technique.icon,
                        style: const TextStyle(fontSize: 60),
                      ),
                      
                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          steps[_currentStep],
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

                      Text(
                        'Step ${_currentStep + 1} of ${steps.length}',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation
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
                      backgroundColor: _techniqueColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      _currentStep == steps.length - 1 ? 'Finish' : 'Next',
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
                    color: _techniqueColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: _techniqueColor,
                  ),
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
                      backgroundColor: _techniqueColor,
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
        ),
      ),
    );
  }
}

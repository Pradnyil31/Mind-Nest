import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/calm_technique.dart';

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({Key? key}) : super(key: key);

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<String> _affirmations = CalmTechnique.defaults
      .firstWhere((t) => t.id == 'positive-affirmations')
      .content!;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Calming Affirmations',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: _affirmations.length,
              itemBuilder: (context, index) {
                return _buildAffirmationCard(_affirmations[index]);
              },
            ),
          ),

          // Page indicator
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _affirmations.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _currentIndex ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _currentIndex
                            ? const Color(0xFF9575CD)
                            : Colors.white30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Swipe for next affirmation',
                  style: GoogleFonts.lato(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_currentIndex + 1} of ${_affirmations.length}',
                  style: GoogleFonts.lato(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffirmationCard(String affirmation) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF9575CD).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '💬',
                style: TextStyle(fontSize: 60),
              ),
            ),
            
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                affirmation,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 24,
                  color: Colors.white,
                  height: 1.6,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'Take a deep breath and repeat this to yourself',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.white60,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

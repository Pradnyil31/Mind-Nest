import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/calm_technique.dart';
import 'grounding_exercise_screen.dart';
import 'affirmations_screen.dart';
import 'calm_technique_screen.dart';

class CalmScreen extends StatefulWidget {
  const CalmScreen({super.key});

  @override
  State<CalmScreen> createState() => _CalmScreenState();
}

class _CalmScreenState extends State<CalmScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        title: Text(
          'Calm',
          style: GoogleFonts.lato(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          100,
        ), // Added bottom padding for nav bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Calm Techniques Section
            _buildSectionHeader(
              '🆘 Quick Calm Techniques',
              'Instant anxiety relief',
            ),
            const SizedBox(height: 16),
            _buildTechniquesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTechniquesList() {
    return Column(
      children: CalmTechnique.defaults.map((technique) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTechniqueCard(technique),
        );
      }).toList(),
    );
  }

  Widget _buildTechniqueCard(CalmTechnique technique) {
    Color techniqueColor;
    switch (technique.type) {
      case TechniqueType.grounding:
        techniqueColor = const Color(0xFF81C784);
        break;
      case TechniqueType.affirmation:
        techniqueColor = const Color(0xFF9575CD);
        break;
      case TechniqueType.breathing:
        techniqueColor = const Color(0xFF64B5F6);
        break;
      case TechniqueType.visualization:
        techniqueColor = const Color(0xFF4DB6AC);
        break;
    }

    return GestureDetector(
      onTap: () {
        // Navigate to appropriate screen based on technique
        if (technique.id == '5-4-3-2-1') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroundingExerciseScreen()),
          );
        } else if (technique.id == 'positive-affirmations') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AffirmationsScreen()),
          );
        } else {
          // Generic technique screen for others
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CalmTechniqueScreen(technique: technique),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: techniqueColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(technique.icon, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technique.title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    technique.description,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: techniqueColor),
                      const SizedBox(width: 4),
                      Text(
                        '${technique.durationMinutes} min',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: techniqueColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

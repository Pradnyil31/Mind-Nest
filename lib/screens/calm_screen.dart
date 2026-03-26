import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ambient_sound.dart';
import '../models/calm_technique.dart';
import 'grounding_exercise_screen.dart';
import 'affirmations_screen.dart';
import 'calm_technique_screen.dart';
import 'enhanced_calm_screen.dart';
import '../theme/app_colors.dart';

class CalmScreen extends StatefulWidget {
  const CalmScreen({super.key});

  @override
  State<CalmScreen> createState() => _CalmScreenState();
}

class _CalmScreenState extends State<CalmScreen> {
  final Set<String> _activeSounds = {};
  double _volume = 0.7;
  int _timerMinutes = 30;
  final List<int> _timerOptions = [15, 30, 60, 90];
  final bool _useEnhancedVersion = true; // Toggle for testing

  @override
  Widget build(BuildContext context) {
    // Use enhanced version by default
    if (_useEnhancedVersion) {
      return const EnhancedCalmScreen();
    }

    // Original implementation as fallback
    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      appBar: AppBar(
        title: Text(
          'Calm',
          style: GoogleFonts.lato(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
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
              'Quick Calm Techniques',
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
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.lato(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildSoundscapeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: AmbientSound.defaults.length,
      itemBuilder: (context, index) {
        final sound = AmbientSound.defaults[index];
        final isActive = _activeSounds.contains(sound.id);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isActive) {
                _activeSounds.remove(sound.id);
              } else {
                _activeSounds.add(sound.id);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? AppColors.info : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? AppColors.info.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: isActive ? 12 : 8,
                  offset: Offset(0, isActive ? 6 : 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sound.emoji,
                  style: TextStyle(fontSize: isActive ? 42 : 36),
                ),
                const SizedBox(height: 8),
                Text(
                  sound.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active sounds indicator
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _activeSounds.map((soundId) {
              final sound = AmbientSound.defaults.firstWhere(
                (s) => s.id == soundId,
              );
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sound.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      sound.name,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Volume Control
          Row(
            children: [
              const Icon(Icons.volume_down, color: AppColors.info),
              Expanded(
                child: Slider(
                  value: _volume,
                  onChanged: (value) => setState(() => _volume = value),
                  activeColor: AppColors.info,
                  inactiveColor: AppColors.info.withValues(alpha: 0.2),
                ),
              ),
              const Icon(Icons.volume_up, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                '${(_volume * 100).round()}%',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Timer Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Timer:',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              DropdownButton<int>(
                value: _timerMinutes,
                underline: const SizedBox(),
                items: _timerOptions.map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text(
                      minutes >= 60
                          ? '${minutes ~/ 60} hour${minutes > 60 ? 's' : ''}'
                          : '$minutes min',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _timerMinutes = value);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Note about MVP
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audio playback coming soon! UI is ready.',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        techniqueColor = AppColors.info;
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
              color: Colors.black.withValues(alpha: 0.05),
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
                color: techniqueColor.withValues(alpha: 0.15),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    technique.description,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: AppColors.textSecondary,
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
              color: AppColors.navBarUnselected,
            ),
          ],
        ),
      ),
    );
  }
}



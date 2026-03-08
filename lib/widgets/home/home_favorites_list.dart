import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/focus_screen.dart';
import '../../screens/breathing_screen.dart';
import '../../screens/meditation_library_screen.dart';
import '../../screens/smart_goals_screen.dart';
import '../../screens/journaling_screen.dart';
import '../../screens/daily_checkin_screen.dart';

class HomeFavoritesList extends StatelessWidget {
  final List<String> activities;
  final Map<String, dynamic> routine;
  final Color textColor;
  final VoidCallback onCheckInComplete;

  const HomeFavoritesList({
    super.key,
    required this.activities,
    required this.routine,
    required this.textColor,
    required this.onCheckInComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return SizedBox(
        height: 130,
        child: ListView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          children: [
            _FavoriteItem(
              label: 'Journaling',
              icon: Icons.book_outlined,
              iconColor: const Color(0xFF4DB6AC),
              textColor: textColor,
            ),
            const SizedBox(width: 16),
            _FavoriteItem(
              label: 'Mood\nTracking',
              icon: Icons.mood,
              iconColor: const Color(0xFFFFB74D),
              textColor: textColor,
            ),
            const SizedBox(width: 16),
            _FavoriteItem(
              label: 'Bamboo Forest',
              assetPath: 'assets/images/bamboo_forest_icon.png',
              textColor: textColor,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: activities.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityItem(context, activity);
        },
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String activity) {
    IconData icon;
    Color color;
    String label = activity;

    switch (activity) {
      case 'Daily Check-ins':
        icon = Icons.calendar_today_outlined;
        color = const Color(0xFF6C63FF).withOpacity(0.8);
        label = 'Daily\nCheck-ins';
        break;
      case 'Journaling':
        icon = Icons.book_outlined;
        color = const Color(0xFF4DB6AC);
        break;
      case 'Focus Sessions':
        icon = Icons.timer_outlined;
        color = const Color(0xFF7986CB);
        label = 'Focus\nSessions';
        break;
      case 'Breathing':
        icon = Icons.air_rounded;
        color = const Color(0xFF4DD0E1);
        label = 'Breathe';
        break;
      case 'Meditation':
        icon = Icons.self_improvement_rounded;
        color = const Color(0xFF9575CD);
        label = 'Meditate';
        break;
      case 'Smart Goals':
        icon = Icons.flag_rounded;
        color = const Color(0xFF81C784);
        label = 'Goals';
        break;
      default:
        icon = Icons.star_outline;
        color = const Color(0xFFA78BFA);
    }

    return _FavoriteItem(
      label: label,
      icon: icon,
      iconColor: color,
      textColor: textColor,
      onTap: () async {
        Widget? screen;
        switch (activity) {
          case 'Focus Sessions':
            screen = const FocusScreen();
            break;
          case 'Breathing':
            screen = const BreathingScreen();
            break;
          case 'Meditation':
            screen = const MeditationLibraryScreen();
            break;
          case 'Smart Goals':
            screen = const SmartGoalsScreen();
            break;
          case 'Journaling':
            screen = const JournalingScreen();
            break;
          case 'Daily Check-ins':
            screen = const DailyCheckInScreen();
            break;
        }

        if (screen != null) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen!),
          );
          if (result == true && activity == 'Daily Check-ins') {
            onCheckInComplete();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label feature coming soon!')),
          );
        }
      },
    );
  }
}

class _FavoriteItem extends StatelessWidget {
  final String label;
  final String? assetPath;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Color textColor;

  const _FavoriteItem({
    required this.label,
    this.assetPath,
    this.icon,
    this.iconColor,
    this.onTap,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (iconColor ?? Colors.grey).withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: assetPath != null && assetPath!.isNotEmpty
                      ? Image.asset(assetPath!, fit: BoxFit.contain)
                      : Icon(
                          icon ?? Icons.circle,
                          color: iconColor ?? Colors.grey,
                          size: 30,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

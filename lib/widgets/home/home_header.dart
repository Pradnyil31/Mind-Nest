import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../screens/badges_screen.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../config/tour_keys.dart';

class HomeHeader extends StatelessWidget {
  final String displayName;
  final String greeting;
  final Color textColor;
  final String? motiveHint;
  final VoidCallback? onNotificationTap;

  const HomeHeader({
    super.key,
    required this.displayName,
    required this.greeting,
    this.textColor = AppColors.textPrimary,
    this.motiveHint,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Showcase(
            key: TourKeys.headerKey,
            title: 'Review your Day',
            description: 'Check your greeting and get an overview of your current time.',
            targetBorderRadius: BorderRadius.circular(16),
            targetPadding: const EdgeInsets.all(8),
            tooltipBackgroundColor: const Color(0xFF1C1C2E),
            textColor: Colors.white,
            titleTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            descTextStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFFCBCBDB),
              height: 1.5,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  displayName,
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (motiveHint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    motiveHint!,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Badges Icon
        Showcase(
          key: TourKeys.badgesKey,
          title: '🏆 My Badges',
          description: 'Collect achievement badges as you build healthy habits and hit your goals!',
          targetShapeBorder: const CircleBorder(),
          tooltipBackgroundColor: const Color(0xFF1C1C2E),
          textColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          descTextStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFFCBCBDB),
            height: 1.5,
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BadgesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.emoji_events_rounded),
            iconSize: 28,
            color: const Color(0xFFFFA726),
            tooltip: 'My Badges',
          ),
        ),
      ],
    );
  }
}


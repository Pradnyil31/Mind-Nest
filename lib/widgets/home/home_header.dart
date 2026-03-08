import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../screens/badges_screen.dart';

class HomeHeader extends StatelessWidget {
  final String displayName;
  final String greeting;
  final Color textColor;
  final VoidCallback? onNotificationTap;

  const HomeHeader({
    super.key,
    required this.displayName,
    required this.greeting,
    this.textColor = AppColors.textPrimary,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.8),
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
            ],
          ),
        ),
        // Badges Icon
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BadgesScreen()),
            );
          },
          icon: const Icon(Icons.emoji_events_rounded),
          iconSize: 28,
          color: const Color(0xFFFFA726), // Keep specific brand color for badge
          tooltip: 'My Badges',
        ),
      ],
    );
  }
}

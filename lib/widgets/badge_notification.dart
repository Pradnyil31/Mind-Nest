import 'package:flutter/material.dart' hide Badge;
import 'package:google_fonts/google_fonts.dart';
import '../models/badge.dart';
import '../theme/app_colors.dart';

// Helper function to show notification
void showBadgeNotification(BuildContext context, Badge? badge) {
  // If we don't have BadgeModel, we can pass dynamic. 
  // For now assuming BadgeModel exists or similar structure.
  
  if (badge == null) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.1),
               blurRadius: 10,
               offset: const Offset(0, 5),
             ),
          ],
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'New Badge Unlocked!',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    badge.name,
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


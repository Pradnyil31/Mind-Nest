import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../config/tour_keys.dart';

class HomeCheckInCard extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onTap;

  final Map<String, dynamic>? checkInData;

  const HomeCheckInCard({
    super.key,
    required this.isCompleted,
    required this.onTap,
    this.checkInData,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent;
    if (isCompleted) {
      cardContent = Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Check-in Complete',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                     checkInData != null && checkInData!['mood'] != null
                        ? 'Feeling ${checkInData!['mood']} today'
                        : 'Great job tracking your well-being!',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      cardContent = GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
             gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8B9DFF)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
               BoxShadow(
                 color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wb_sunny, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review your ${_getTimePeriod()}',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log sleep & mood to adapt routine.',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      );
    }

    return Showcase(
      key: TourKeys.headerKey,
      title: 'Review your Day',
      description: 'Take a moment to center yourself and check in with your daily feelings.',
      targetBorderRadius: BorderRadius.circular(24),
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
      child: cardContent,
    );
  }

  String _getTimePeriod() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

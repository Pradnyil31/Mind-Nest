import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../config/tour_keys.dart';

class HomeAICoachCard extends StatelessWidget {
  final VoidCallback onTap;

  const HomeAICoachCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: TourKeys.aiCoachKey,
      title: 'Talk to your AI coach',
      description: 'Get personalized insights and chat with your companion.',
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7E8FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Talk to your AI coach',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Get a journaling prompt, a calming suggestion, or gentle support.',
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D2D2D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                'Start conversation',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}


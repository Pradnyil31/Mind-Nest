import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        title: Text(
          'About App',
          style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/panda_character.png', // Or another appropriate asset
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.spa_rounded, size: 80, color: Color(0xFF6C63FF)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'MindNest',
              style: GoogleFonts.lato(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Our Mission',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MindNest is dedicated to helping you cultivate mindfulness, establish healthy routines, and achieve personal growth. We believe that small, consistent actions lead to profound transformations.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      height: 1.6,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, color: Colors.red.shade400, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Made with care',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

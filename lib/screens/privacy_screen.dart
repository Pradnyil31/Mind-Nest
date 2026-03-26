import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Information We Collect'),
            _buildSectionContent(
                'We collect information you provide directly to us when you create an account, update your profile, and use the application. This includes your name, email address, chosen daily routines, and journaling entries.'),
            _buildSectionTitle('2. How We Use Your Information'),
            _buildSectionContent(
                'The information we collect is used to personalize your experience, provide personalized AI insights, notify you of your routines, and improve the app\'s overall functionality.'),
            _buildSectionTitle('3. Data Storage and Security'),
            _buildSectionContent(
                'Your data is stored securely using industry-standard cloud infrastructure. We implement robust security measures to protect your personal information from unauthorized access, alteration, or disclosure. Routine data is also stored locally on your device for fast access.'),
            _buildSectionTitle('4. Third-Party Services'),
            _buildSectionContent(
                'We do not sell, trade, or otherwise transfer to outside parties your Personally Identifiable Information unless we provide users with advance notice. This does not include website hosting partners and other parties who assist us in operating our application.'),
            _buildSectionTitle('5. Your Rights'),
            _buildSectionContent(
                'You have the right to access, update, or delete your personal information at any time from the account settings. If you wish to permanently delete your account, you can do so through the app or by contacting our support team.'),
            _buildSectionTitle('6. Changes to this Policy'),
            _buildSectionContent(
                'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.'),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last Updated: March 2026',
                style: GoogleFonts.lato(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: GoogleFonts.lato(
        fontSize: 15,
        height: 1.6,
        color: const Color(0xFF4B5563),
      ),
    );
  }
}

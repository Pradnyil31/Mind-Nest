import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../services/auth_service.dart';
import 'journal_entry_screen.dart';

class JournalingScreen extends StatelessWidget {
  const JournalingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF4),
      appBar: AppBar(
        title: Text(
          'My Journal',
          style: GoogleFonts.lato(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalEntryScreen()),
          );
        },
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New Entry'),
      ),
      body: user == null
          ? const Center(child: Text("Please sign in to view your journal."))
          : StreamBuilder<List<JournalEntry>>(
              stream: JournalService().getEntriesStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final entries = snapshot.data ?? [];

                if (entries.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _buildJournalCard(context, entry);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.book_outlined, size: 50, color: Color(0xFF6C63FF)),
          ),
          const SizedBox(height: 24),
          Text(
            'Start Your Journal',
            style: GoogleFonts.lato(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Reflect on your day, track your mood,\nand clear your mind.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(BuildContext context, JournalEntry entry) {
    // Pick color/icon based on mood (Simplified logic for listing)
    Color moodColor = const Color(0xFFFDBB2D);
    IconData moodIcon = Icons.sentiment_neutral;
    
    switch (entry.mood) {
      case 'Happy':
      case 'Excited':
        moodColor = const Color(0xFFFDBB2D);
        moodIcon = Icons.sentiment_very_satisfied;
        break;
      case 'Sad':
        moodColor = const Color(0xFF90A4AE);
        moodIcon = Icons.sentiment_dissatisfied;
        break;
      case 'Calm':
        moodColor = const Color(0xFF4DB6AC);
        moodIcon = Icons.spa;
        break;
      case 'Anxious':
        moodColor = const Color(0xFFFF8A65);
        moodIcon = Icons.waves;
        break;
       case 'Tired':
        moodColor = const Color(0xFF9575CD);
        moodIcon = Icons.bedtime;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JournalEntryScreen(entry: entry)),
          );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: moodColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(moodIcon, color: moodColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMM d, yyyy').format(entry.timestamp),
                      style: GoogleFonts.lato(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('h:mm a').format(entry.timestamp),
                  style: GoogleFonts.lato(
                     color: Colors.grey.shade400,
                     fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: const Color(0xFF546E7A), // Blue-grey text
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

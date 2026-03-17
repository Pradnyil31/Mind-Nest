import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../services/auth_service.dart';
import '../widgets/activity_completion_dialog.dart';

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry? entry; // Null if creating a new entry

  const JournalEntryScreen({Key? key, this.entry}) : super(key: key);

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedMood = 'Happy';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _moods = [
    {'label': 'Happy', 'icon': Icons.sentiment_very_satisfied, 'color': Color(0xFFFDBB2D)},
    {'label': 'Calm', 'icon': Icons.spa, 'color': Color(0xFF4DB6AC)},
    {'label': 'Sad', 'icon': Icons.sentiment_dissatisfied, 'color': Color(0xFF90A4AE)},
    {'label': 'Anxious', 'icon': Icons.waves, 'color': Color(0xFFFF8A65)},
    {'label': 'Excited', 'icon': Icons.bolt, 'color': Color(0xFFFFD54F)},
    {'label': 'Tired', 'icon': Icons.bedtime, 'color': Color(0xFF9575CD)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedMood = widget.entry!.mood;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) throw 'User not logged in';

      final entry = JournalEntry(
        id: widget.entry?.id ?? '', // Service will handle ID generation for empty string if needed, or we handle it.
        userId: user.uid,
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        mood: _selectedMood,
        timestamp: widget.entry?.timestamp ?? DateTime.now(),
        tags: [],
      );

      final service = JournalService();
      await ActivityCompletionDialog.show(
        context,
        savingText: 'Saving entry...',
        onComplete: () async {
          if (widget.entry == null) {
            await service.addEntry(entry);
          } else {
            await service.updateEntry(entry);
          }
        },
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getMoodColor() {
    return _moods.firstWhere((m) => m['label'] == _selectedMood, orElse: () => _moods[0])['color'];
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = _getMoodColor();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _isLoading ? null : _saveEntry,
              style: TextButton.styleFrom(
                backgroundColor: moodColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Save',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mood Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: _moods.map((mood) {
                  final isSelected = mood['label'] == _selectedMood;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = mood['label']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? mood['color'] : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? mood['color'] : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: (mood['color'] as Color).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            mood['icon'],
                            size: 20,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Text(
                              mood['label'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            
            // Content Input
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.lato(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2D2D2D),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contentController,
                      maxLines: null, // Grows as user types
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        height: 1.5,
                        color: const Color(0xFF455A64),
                      ),
                      decoration: InputDecoration(
                        hintText: 'How are you feeling today?',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

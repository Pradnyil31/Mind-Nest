import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 
import '../models/smart_goal.dart';
import '../services/goal_service.dart';
import '../services/auth_service.dart';
import 'create_goal_screen.dart';
import '../widgets/activity_completion_dialog.dart';

class SmartGoalsScreen extends StatelessWidget {
  const SmartGoalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF4),
      appBar: AppBar(
        title: Text(
          'Smart Goals',
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_circle_outline, size: 24),
          label: Text(
            'New Goal',
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Please sign in to view your goals."))
          : StreamBuilder<List<SmartGoal>>(
              stream: GoalService().getGoalsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final goals = snapshot.data ?? [];

                if (goals.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return _buildGoalCard(context, goal);
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
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
             child: const Center(
               child: Icon(Icons.track_changes, size: 60, color: Color(0xFF6C63FF)),
             ), 
          ),
          const SizedBox(height: 32),
          Text(
            'No Goals Yet',
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Turn your dreams into reality.\nSet a specific, measurable goal now.',
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

  Widget _buildGoalCard(BuildContext context, SmartGoal goal) {
    final double progress = goal.currentValue / goal.targetValue;
    final int percent = (progress * 100).toInt().clamp(0, 100);
    final Color color = Color(goal.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular Progress
                 Stack(
                   alignment: Alignment.center,
                   children: [
                     SizedBox(
                       width: 60,
                       height: 60,
                       child: CircularProgressIndicator(
                         value: progress,
                         backgroundColor: color.withOpacity(0.1),
                         valueColor: AlwaysStoppedAnimation(color),
                         strokeWidth: 6,
                       ),
                     ),
                     Text(
                       '$percent%',
                       style: GoogleFonts.lato(
                         fontWeight: FontWeight.bold,
                         fontSize: 14,
                         color: color,
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(width: 20),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         goal.title,
                         style: GoogleFonts.lato(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                           color: const Color(0xFF2D2D2D),
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         'Target: ${goal.targetValue.toStringAsFixed(0)} ${goal.unit}',
                         style: GoogleFonts.lato(
                           fontSize: 14,
                           color: Colors.grey.shade500,
                         ),
                       ),
                     ],
                   ),
                 ),
                 IconButton(
                   icon: const Icon(Icons.more_vert),
                   color: Colors.grey,
                   onPressed: () {
                     // Potential Edit/Delete options
                     _showDeleteConfirm(context, goal.id);
                   },
                 ),
              ],
            ),
          ),
          
          // Divider
          Container(height: 1, color: Colors.grey.shade100),
          
          // Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                   'Due ${DateFormat('MMM d').format(goal.deadline)}',
                   style: GoogleFonts.lato(
                     fontSize: 13,
                     fontWeight: FontWeight.bold,
                     color: Colors.grey.shade400,
                   ),
                 ),
                   InkWell(
                     onTap: () async {
                        final newVal = goal.currentValue + 1;
                        if (newVal <= goal.targetValue) {
                           await ActivityCompletionDialog.show(
                             context,
                             savingText: 'Logging progress...',
                             onComplete: () async {
                               await GoalService().updateProgress(goal.id, newVal);
                             },
                           );
                        }
                     },
                   borderRadius: BorderRadius.circular(20),
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: color.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Row(
                       children: [
                         Icon(Icons.add, size: 16, color: color),
                         const SizedBox(width: 4),
                         Text(
                           'Log Progress',
                           style: GoogleFonts.lato(
                             fontWeight: FontWeight.bold,
                             fontSize: 13,
                             color: color,
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String goalId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              GoalService().deleteGoal(goalId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

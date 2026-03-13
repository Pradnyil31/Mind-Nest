import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/voice_service.dart';
import '../models/user_model.dart';
import '../config/motive_config.dart';
import '../config/notification_content.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _voiceEnabled = true;

  @override
  void initState() {
    super.initState();
    VoiceService.getSavedPreference().then((v) => setState(() => _voiceEnabled = v));
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirestoreService().getUserStream(user?.uid ?? ''),
        builder: (context, snapshot) {
          String displayName = 'User';
          String email = user?.email ?? '';
          String? primaryMotive;
          TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 0);
          TimeOfDay bedTime = const TimeOfDay(hour: 22, minute: 0);
          String dailyCommitment = '10 minutes';
          List<String> supportAreas = [];
          
          if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              displayName = data['displayName'] ?? 'User';
              email = user?.email ?? '';
              primaryMotive = data['primaryMotive'] as String?;
              dailyCommitment = data['dailyCommitment'] as String? ?? '10 minutes';
              if (data['supportAreas'] != null) {
                supportAreas = List<String>.from(data['supportAreas']);
              }
              
              if (data.containsKey('routine')) {
                 final routine = data['routine'] as Map<String, dynamic>;
                 if (routine.containsKey('wakeUpTime')) {
                    wakeTime = _parseTime(routine['wakeUpTime']);
                 }
                 if (routine.containsKey('bedTime')) {
                    bedTime = _parseTime(routine['bedTime']);
                 }
              }
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, displayName, email),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('My Goal'),
                      _buildMotiveCard(context, primaryMotive, dailyCommitment, supportAreas),
                      const SizedBox(height: 32),
                      
                      _buildSectionHeader('Routine Settings'),
                      const SizedBox(height: 16),
                      _buildSettingTile(
                        context: context,
                        icon: Icons.wb_sunny_rounded,
                        iconColor: Colors.orange,
                        title: 'Wake Up Time',
                        value: _formatTime(wakeTime),
                        onTap: () => _pickTime(context, user?.uid, 'wakeUpTime', wakeTime),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingTile(
                        context: context,
                        icon: Icons.bedtime_rounded,
                        iconColor: Colors.indigo,
                        title: 'Bedtime',
                        value: _formatTime(bedTime),
                        onTap: () => _pickTime(context, user?.uid, 'bedTime', bedTime),
                      ),
                       const SizedBox(height: 12),
                      _buildCommitmentSection(context, dailyCommitment, primaryMotive, supportAreas),

                      const SizedBox(height: 32),
                      _buildSectionHeader('Account'),
                       const SizedBox(height: 16),
                       _buildActionTile(
                        icon: Icons.edit_outlined,
                        title: 'Edit Name',
                        onTap: () => _editName(context, user?.uid, displayName),
                      ),
                      _buildActionTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Reminders',
                        trailing: Switch(
                           value: true, 
                           onChanged: (val) {}, 
                           activeColor: const Color(0xFF6C63FF),
                        ),
                        onTap: () {},
                      ),
                       _buildActionTile(
                         icon: Icons.record_voice_over_rounded,
                         title: 'Voice Assistant',
                         trailing: Switch(
                           value: _voiceEnabled,
                           onChanged: (val) async {
                             await VoiceService().setEnabled(val);
                             setState(() => _voiceEnabled = val);
                           },
                           activeColor: const Color(0xFF6C63FF),
                         ),
                         onTap: () {},
                       ),
                      _buildActionTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => _showPrivacyDialog(context),
                      ),
                      
                      const SizedBox(height: 40),

                      // ── DEVELOPER TEST SECTION ──────────────────────────
                      _buildSectionHeader('🧪 Notification Tests'),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Fire Test Notification (5s)',
                        onTap: () async {
                          final ns = NotificationService();
                          await ns.init();
                          await ns.requestPermissions();
                          await ns.flutterLocalNotificationsPlugin.zonedSchedule(
                            id: 99,
                            title: '✅ Test Notification',
                            body: 'MindNest notifications are working!',
                            scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
                            notificationDetails: const NotificationDetails(
                              android: AndroidNotificationDetails(
                                'daily_routine_channel',
                                'Daily Routine Reminders',
                                importance: Importance.max,
                                priority: Priority.high,
                              ),
                              iOS: DarwinNotificationDetails(),
                            ),
                            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                            matchDateTimeComponents: null,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⏱ Notification will arrive in 5 seconds — minimize the app!'),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.list_alt_rounded,
                        title: 'Check Pending Notifications',
                        onTap: () async {
                          final pending = await NotificationService()
                              .flutterLocalNotificationsPlugin
                              .pendingNotificationRequests();
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text(
                                  'Pending: ${pending.length} notification${pending.length == 1 ? '' : 's'}',
                                  style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                                ),
                                content: pending.isEmpty
                                    ? Text('No notifications scheduled yet.\nSave your routine to schedule them.', style: GoogleFonts.lato())
                                    : SizedBox(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: pending.length,
                                          itemBuilder: (_, i) => ListTile(
                                            leading: const Icon(Icons.notifications, color: Color(0xFF6C63FF)),
                                            title: Text(pending[i].title ?? '(no title)', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                                            subtitle: Text(pending[i].body ?? '', style: GoogleFonts.lato(fontSize: 12)),
                                          ),
                                        ),
                                      ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text('OK', style: GoogleFonts.lato(color: const Color(0xFF6C63FF))),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      // ────────────────────────────────────────────────────

                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () async {
                             final shouldSignOut = await _showSignOutDialog(context);
                             if (shouldSignOut == true) {
                                await authService.signOut();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                                    (route) => false,
                                  );
                                }
                             }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Sign Out',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String name, String email) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF6C63FF),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: GoogleFonts.lato(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                style: GoogleFonts.lato(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMotiveCard(BuildContext context, String? currentMotive, String commitment, List<String> supportAreas) {
    final profile = MotiveConfig.getProfile(currentMotive);
    final displayMotive = profile?.displayName ?? currentMotive ?? 'Set Motive';
    final emoji = profile?.emoji ?? '🎯';

    return Container(
      margin: const EdgeInsets.only(top: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMotiveSelection(context, currentMotive, commitment, supportAreas),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayMotive,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to change your focus',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
       decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: Colors.grey.shade600, size: 24),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
      ),
    );
  }

  // --- Actions ---

  Widget _buildCommitmentSection(BuildContext context, String currentCommitment, String? primaryMotive, List<String> supportAreas) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _pickCommitment(context, AuthService().currentUser?.uid, currentCommitment, primaryMotive, supportAreas),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.timer_rounded, color: Colors.teal, size: 22),
                  ),
                   const SizedBox(width: 16),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('Daily Commitment', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                       const SizedBox(height: 4),
                       Text(
                         currentCommitment, 
                         style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF6C63FF)),
                       ),
                     ],
                   ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                 "Based on your selection: ${_getCommitmentDescription(currentCommitment)}",
                 style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCommitmentDescription(String commitment) {
     if (commitment.startsWith('5')) return 'Light: ~3 tasks/day';
     if (commitment.startsWith('10')) return 'Balanced: ~5 tasks/day';
     if (commitment.startsWith('15')) return 'Solid: ~7 tasks/day';
     return 'Intense: ~9 tasks/day';
  }

  Future<void> _pickTime(BuildContext context, String? uid, String field, TimeOfDay initial) async {
    if (uid == null) return;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted = "${picked.hour}:${picked.minute.toString().padLeft(2, '0')} ${picked.period == DayPeriod.am ? 'AM' : 'PM'}";
      
      // Check if we should force regenerate today's routine
      bool forceRegenerate = false;
      final now = DateTime.now();
      if (now.hour < 12) {
          // It's morning. Check if user has done any tasks.
          // We need to fetch the user doc again to be sure or pass it in. 
          // For simplicity, let's look at the snapshot data if possible, but better to query fresh.
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final data = userDoc.data();
            // check routine_completions collection for today? 
            // Or simpler: check if 'completedActivities' list in user doc is empty? 
            // The Home Screen logic maintains a local list or state. 
            // In Firestore, we usually track completions in a subcollection or separate collection. 
            // Let's assume we check the 'routine_completions' collection for today.
             final startOfDay = DateTime(now.year, now.month, now.day);
             final query = await FirebaseFirestore.instance
                  .collection('routine_completions')
                  .where('userId', isEqualTo: uid)
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                  .get();
             
             if (query.docs.isEmpty) {
                // No completed tasks today!
                forceRegenerate = true;
             }
          }
      }

      await FirestoreService().updateUser(uid, {
         'routine.$field': formatted,
         if (forceRegenerate) 'lastGeneratedDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });
      
      // Reschedule notifications with new time
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
         final data = userDoc.data() as Map<String, dynamic>;
         final name = data['displayName'] ?? 'there';
         final motive = data['dailyMotive'] ?? 'Wellness';
         final routine = Map<String, dynamic>.from(data['routine'] ?? {});
         
         TimeOfDay wakeTime = _parseTime(routine['wakeTime'] ?? "7:00 AM");
         TimeOfDay bedTime = _parseTime(routine['bedTime'] ?? "10:00 PM");
         
         if (field == 'wakeTime') wakeTime = picked;
         if (field == 'bedTime') bedTime = picked;
         
         await _rescheduleNotifications(name, motive, wakeTime, bedTime);
      }
      
      if (forceRegenerate && context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Morning update! Routine regenerated for today.')),
         );
      } else if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule updated! Changes will apply tomorrow.')),
         );
      }
    }
  }

  Future<void> _pickCommitment(BuildContext context, String? uid, String current, String? primaryMotive, List<String> supportAreas) async {
     if (uid == null) return;
     final options = ['5 minutes', '10 minutes', '15 minutes', '30+ minutes'];
     
     final selected = await showModalBottomSheet<String>(
       context: context,
       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
       builder: (context) => SafeArea(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const SizedBox(height: 16),
             Text('Daily Commitment', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             ...options.map((opt) => ListTile(
               title: Text(opt, style: GoogleFonts.lato(fontSize: 16)),
               leading: opt == current 
                  ? const Icon(Icons.check_circle, color: Color(0xFF6C63FF))
                  : const Icon(Icons.circle_outlined, color: Colors.grey),
               onTap: () => Navigator.pop(context, opt),
             )),
             const SizedBox(height: 16),
           ],
         ),
       ),
     );
     
     if (selected != null && selected != current) {
       // Generate new base routine based on new commitment
       final newRoutine = MotiveConfig.generateRoutine(
         motive: primaryMotive,
         commitment: selected,
         supportAreas: supportAreas,
       );

       await FirestoreService().updateUser(uid, {
         'dailyCommitment': selected,
         'baseRoutine': newRoutine,
       });

       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commitment updated! Tasks will adjust tomorrow.')));
       }
     }
  }
  
  Future<void> _editName(BuildContext context, String? uid, String currentName) async {
    if (uid == null) return;
    final controller = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
             onPressed: () async {
               if (controller.text.isNotEmpty) {
                   await FirestoreService().updateUser(uid, {'displayName': controller.text.trim()});
                   
                   // Reschedule notifications with new name
                   final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                   if (userDoc.exists && userDoc.data() != null) {
                      final data = userDoc.data() as Map<String, dynamic>;
                      final motive = data['dailyMotive'] ?? 'Wellness';
                      // Need wake/bed times. They might not be in this scope easily without refetching or passing.
                      // Let's refetch to be safe and clean.
                      final routine = Map<String, dynamic>.from(data['routine'] ?? {});
                      final wakeTime = _parseTime(routine['wakeTime'] ?? "7:00 AM");
                      final bedTime = _parseTime(routine['bedTime'] ?? "10:00 PM");
                      
                      await _rescheduleNotifications(controller.text.trim(), motive, wakeTime, bedTime);
                   }
                   
                   Navigator.pop(ctx);
               }
             },
             child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showSignOutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
  
  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text('Your privacy is important to us. \n\nWe store your routine data locally and in the cloud to provide you with a seamless experience across devices. We do not share your data with third parties.\n\n(Full policy placeholder)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // --- Helpers ---
  
  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final period = parts[1]; 
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 7, minute: 0); 
    }
  }
  
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _showMotiveSelection(BuildContext context, String? currentMotive, String commitment, List<String> supportAreas) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Choose Your Focus',
                style: GoogleFonts.lato(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: MotiveConfig.allMotives.length,
                itemBuilder: (context, index) {
                  final motive = MotiveConfig.allMotives[index];
                  final profile = MotiveConfig.getProfile(motive);
                  final isSelected = motive == currentMotive;

                  return GestureDetector(
                    onTap: () async {
                      final user = AuthService().currentUser;
                      if (user != null) {
                         // 1. Generate new activities
                         final newActivities = MotiveConfig.generateRoutine(
                            motive: motive, 
                            commitment: commitment,
                            supportAreas: supportAreas,
                         );
                         
                         // 2. Check if user has completed any tasks *today*
                         // We'll query routine_completions for today
                         final now = DateTime.now();
                         final startOfDay = DateTime(now.year, now.month, now.day);
                         
                         final completionSnap = await FirebaseFirestore.instance
                              .collection('routine_completions')
                              .where('userId', isEqualTo: user.uid)
                              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                              .get();
                         
                         bool hasActivityToday = false;
                         if (completionSnap.docs.isNotEmpty) {
                            // double check if the list is not empty
                           for(var doc in completionSnap.docs) {
                             final data = doc.data();
                              if (data['completedActivities'] != null && (data['completedActivities'] as List).isNotEmpty) {
                                hasActivityToday = true;
                                break;
                              }
                           }
                         }

                         if (context.mounted) Navigator.pop(context);

                         if (hasActivityToday) {
                           // Case A: Has activity -> Update baseRoutine only (Apply Tomorrow)
                           await FirestoreService().updateUser(user.uid, {
                              'primaryMotive': motive,
                              'baseRoutine': newActivities,
                           });
                           
                           // Reschedule notifications
                           final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                           if (userDoc.exists && userDoc.data() != null) {
                              final data = userDoc.data() as Map<String, dynamic>;
                              final name = data['displayName'] ?? 'there';
                              final routine = Map<String, dynamic>.from(data['routine'] ?? {});
                              final wakeTime = _parseTime(routine['wakeTime'] ?? "7:00 AM");
                              final bedTime = _parseTime(routine['bedTime'] ?? "10:00 PM");
                              
                              await _rescheduleNotifications(name, motive, wakeTime, bedTime);
                           }
                           
                           if (context.mounted) {
                             showDialog(
                               context: context,
                               builder: (ctx) => AlertDialog(
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                 title: Text('Changes Saved', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                                 content: Text(
                                   'Since you\'ve already started today\'s routine, your new "$motive" routine will begin tomorrow!\n\nFinish strong today! 💪',
                                   style: GoogleFonts.lato(fontSize: 16),
                                 ),
                                 actions: [
                                   TextButton(
                                     onPressed: () => Navigator.pop(ctx),
                                     child: Text('Got it', style: GoogleFonts.lato(color: const Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                                   )
                                 ],
                               ),
                             );
                           }

                         } else {
                           // Case B: No activity -> Update immediately
                           // We set lastGeneratedDate to past to trigger Home Screen regeneration
                           await FirestoreService().updateUser(user.uid, {
                              'primaryMotive': motive,
                              'baseRoutine': newActivities,
                              'lastGeneratedDate': DateTime(2000, 1, 1).toIso8601String(), // Force regeneration
                           });
                           
                           // Reschedule notifications
                           final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                           if (userDoc.exists && userDoc.data() != null) {
                              final data = userDoc.data() as Map<String, dynamic>;
                              final name = data['displayName'] ?? 'there';
                              final routine = Map<String, dynamic>.from(data['routine'] ?? {});
                              final wakeTime = _parseTime(routine['wakeTime'] ?? "7:00 AM");
                              final bedTime = _parseTime(routine['bedTime'] ?? "10:00 PM");
                              
                              await _rescheduleNotifications(name, motive, wakeTime, bedTime);
                           }
                           
                           if (context.mounted) {
                               showDialog(
                               context: context,
                               builder: (ctx) => AlertDialog(
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                 title: Text('Routine Updated', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                                 content: Text(
                                   'Your routine has been updated to "$motive" for today.\n\nLet\'s get started! 🚀',
                                   style: GoogleFonts.lato(fontSize: 16),
                                 ),
                                 actions: [
                                   TextButton(
                                     onPressed: () => Navigator.pop(ctx),
                                     child: Text('Let\'s Go', style: GoogleFonts.lato(color: const Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                                   )
                                 ],
                               ),
                             );
                           }
                         }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF6C63FF).withOpacity(0.08) 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF6C63FF) 
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(profile?.emoji ?? '🎯', style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.displayName ?? motive,
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (profile?.description != null)
                                  Text(
                                    profile!.description,
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Color(0xFF6C63FF)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _rescheduleNotifications(String name, String motive, TimeOfDay wakeTime, TimeOfDay bedTime) async {
     try {
       await NotificationService().requestPermissions();
       await NotificationService().cancelAll();
       
       // Wake Up
       await NotificationService().scheduleDailyNotification(
         id: 1, 
         title: 'Good Morning!', 
         body: NotificationContent.getMorningMessage(name, motive), 
         hour: wakeTime.hour, 
         minute: wakeTime.minute
       );
       
       // Midday (Wake + 6 hours)
       final midday = wakeTime.hour + 6;
       final middayHour = midday >= 24 ? midday - 24 : midday;
       await NotificationService().scheduleDailyNotification(
         id: 2, 
         title: 'Check In', 
         body: NotificationContent.getAfternoonMessage(name), 
         hour: middayHour, 
         minute: wakeTime.minute
       );
       
       // Evening (Bed - 2 hours)
       final evening = bedTime.hour - 2;
       final eveningHour = evening < 0 ? evening + 24 : evening;
       await NotificationService().scheduleDailyNotification(
         id: 3, 
         title: 'Wind Down', 
         body: NotificationContent.getEveningMessage(name), 
         hour: eveningHour, 
         minute: bedTime.minute
       );
       
       // Bedtime
       await NotificationService().scheduleDailyNotification(
         id: 4, 
         title: 'Sweet Dreams', 
         body: NotificationContent.getBedtimeMessage(name), 
         hour: bedTime.hour, 
         minute: bedTime.minute
       );
       
     } catch (e) {
       print('Error rescheduling notifications: $e');
     }
  }
}

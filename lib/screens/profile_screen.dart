import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/logger.dart';
import '../services/voice_service.dart';
import '../providers/app_providers.dart';
import '../config/motive_config.dart';
import '../config/notification_content.dart';
import '../theme/app_colors.dart';
import 'welcome_screen.dart';
import 'privacy_screen.dart';
import 'about_screen.dart';
import '../widgets/compact_progress_insights.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _voiceEnabled = true;

  @override
  void initState() {
    super.initState();
    VoiceService.getSavedPreference().then((v) => setState(() => _voiceEnabled = v));
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundSubtle,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text('Session expired', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Go to Welcome'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundSubtle,
      body: StreamBuilder<DocumentSnapshot>(
        stream: ref.read(firestoreServiceProvider).getUserStream(user.uid),
        builder: (context, snapshot) {
          String displayName = 'User';
          String email = user.email ?? '';
          String? primaryMotive;
          TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 0);
          TimeOfDay bedTime = const TimeOfDay(hour: 22, minute: 0);
          String dailyCommitment = '10 minutes';
          List<String> supportAreas = [];
          String avatarEmoji = 'U';
          int avatarColor = 0xFF6C63FF;
          
          if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              displayName = data['displayName'] ?? 'User';
              email = user.email ?? '';
              primaryMotive = data['primaryMotive'] as String?;
              dailyCommitment = data['dailyCommitment'] as String? ?? '10 minutes';
              avatarEmoji = data['avatarEmoji'] ?? (displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U');
              avatarColor = data['avatarColor'] ?? 0xFF6C63FF;

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
              _buildSliverAppBar(context, displayName, email, avatarEmoji, avatarColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('My Goal'),
                      _buildMotiveCard(context, primaryMotive, dailyCommitment, supportAreas),
                      const SizedBox(height: 32),

                      _buildSectionHeader('Progress Insights'),
                      const SizedBox(height: 16),
                      CompactProgressInsights(userId: user.uid),
                      const SizedBox(height: 32),
                      
                      _buildSectionHeader('Routine Settings'),
                      const SizedBox(height: 16),
                      _buildSettingTile(
                        context: context,
                        icon: Icons.wb_sunny_rounded,
                        iconColor: Colors.orange,
                        title: 'Wake Up Time',
                        value: _formatTime(wakeTime),
                        onTap: () => _pickTime(context, user.uid, 'wakeUpTime', wakeTime),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingTile(
                        context: context,
                        icon: Icons.bedtime_rounded,
                        iconColor: Colors.indigo,
                        title: 'Bedtime',
                        value: _formatTime(bedTime),
                        onTap: () => _pickTime(context, user.uid, 'bedTime', bedTime),
                      ),
                       const SizedBox(height: 12),
                      _buildCommitmentSection(
                        context,
                        dailyCommitment,
                        primaryMotive,
                        supportAreas,
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader('Account'),
                       const SizedBox(height: 16),
                       _buildActionTile(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        onTap: () => _editProfile(
                          context,
                          user.uid,
                          displayName,
                          email,
                          avatarEmoji,
                          avatarColor,
                        ),
                      ),
                      _buildActionTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Reminders',
                        trailing: Switch(
                           value: true, 
                           onChanged: (val) {}, 
                           activeThumbColor: AppColors.primaryDark,
                        ),
                        onTap: () {},
                      ),
                       _buildActionTile(
                         icon: Icons.record_voice_over_rounded,
                         title: 'Voice Assistant',
                         trailing: Switch(
                           value: _voiceEnabled,
                           onChanged: (val) async {
                             await ref.read(voiceServiceProvider).setEnabled(val);
                             setState(() => _voiceEnabled = val);
                           },
                           activeThumbColor: AppColors.primaryDark,
                         ),
                         onTap: () {},
                       ),
                      _buildActionTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                      ),
                      _buildActionTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About App',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                      ),
                      
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
                            foregroundColor: AppColors.error,
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

  Widget _buildSliverAppBar(BuildContext context, String name, String email, String avatarEmoji, int avatarColor) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
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
                  color: Color(avatarColor),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    avatarEmoji,
                    style: GoogleFonts.lato(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color:
                          Color(avatarColor) == Colors.white
                              ? AppColors.primaryDark
                              : Colors.white,
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
                  color: Colors.white.withValues(alpha: 0.8),
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
        color: AppColors.textSecondary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
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
                    color: AppColors.surfaceMuted,
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to change your focus',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.navBarUnselected,
                ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
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
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.navBarUnselected,
              ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: AppColors.textSecondary, size: 24),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.navBarUnselected,
            ),
      ),
    );
  }

  // --- Actions ---

  Widget _buildCommitmentSection(BuildContext context, String currentCommitment, String? primaryMotive, List<String> supportAreas) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _pickCommitment(context, ref.read(authServiceProvider).currentUser?.uid, currentCommitment, primaryMotive, supportAreas),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.timer_rounded, color: Colors.teal, size: 22),
                  ),
                   const SizedBox(width: 16),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Daily Commitment',
                         style: GoogleFonts.lato(
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
                           color: AppColors.textPrimary,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                          currentCommitment, 
                          style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                 "Based on your selection: ${_getCommitmentDescription(currentCommitment)}",
                 style: GoogleFonts.lato(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
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
      final formatted = _formatTime(picked);
      
      // Check if we should force regenerate today's routine
      bool forceRegenerate = false;
      final now = DateTime.now();
      if (now.hour < 12) {
          forceRegenerate = !(await ref
              .read(routineServiceProvider)
              .hasAnyCompletedActivityToday(uid));
      }

      await ref.read(firestoreServiceProvider).updateUser(uid, {
         'routine.$field': formatted,
         if (forceRegenerate) 'lastGeneratedDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });
      
      // Reschedule notifications with new time
      final userContext = await _getUserNotificationContext(uid);
      if (userContext != null) {
         final name = userContext['name'] as String;
         final motive = userContext['motive'] as String;
         var wakeTime = userContext['wakeTime'] as TimeOfDay;
         var bedTime = userContext['bedTime'] as TimeOfDay;

         if (field == 'wakeUpTime') wakeTime = picked;
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
                  ? const Icon(Icons.check_circle, color: AppColors.primaryDark)
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

       await ref.read(firestoreServiceProvider).updateUser(uid, {
         'dailyCommitment': selected,
         'baseRoutine': newRoutine,
       });

       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commitment updated! Tasks will adjust tomorrow.')));
       }
     }
  }
  
  Future<void> _editProfile(BuildContext context, String? uid, String currentName, String email, String currentEmoji, int currentColor) async {
    if (uid == null) return;
    final controller = TextEditingController(text: currentName);
    String selectedEmoji = currentEmoji;
    int selectedColor = currentColor;

    final List<String> emojiOptions = ['U', '😊', '🐼', '🦊', '🐱', '🐶', '🐯', '🦉', '🦋', '🌟', '🚀', '🎯'];
    final List<int> colorOptions = [0xFF8B6FE8, 0xFF4CAF50, 0xFFFF9800, 0xFFE91E63, 0xFF00BCD4, 0xFF9C27B0, 0xFF795548, 0xFF607D8B];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Profile', style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Avatar Preview
                Center(
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Color(selectedColor)),
                    child: Center(
                      child: Text(selectedEmoji, style: TextStyle(fontSize: 32, color: selectedColor == 0xFFFFFFFF ? Colors.black : Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: email),
                  decoration: InputDecoration(
                    labelText: 'Email (Read Only)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text('Choose Avatar Emoji', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: emojiOptions.map((e) => GestureDetector(
                    onTap: () => setModalState(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e ? AppColors.surfaceMuted : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: selectedEmoji == e ? AppColors.primaryDark : AppColors.border),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
                
                const SizedBox(height: 24),
                Text('Choose Background Color', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                   spacing: 12, runSpacing: 12,
                   children: colorOptions.map((c) => GestureDetector(
                     onTap: () => setModalState(() => selectedColor = c),
                     child: Container(
                       width: 40, height: 40,
                       decoration: BoxDecoration(
                         color: Color(c),
                         shape: BoxShape.circle,
                         border: Border.all(color: selectedColor == c ? Colors.black : Colors.transparent, width: 2),
                       ),
                     ),
                   )).toList(),
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (controller.text.isNotEmpty) {
                        await ref.read(firestoreServiceProvider).updateUser(uid, {
                          'displayName': controller.text.trim(),
                          'avatarEmoji': selectedEmoji,
                          'avatarColor': selectedColor,
                        });
                        
                        // Reschedule notifications just like before
                        final userContext = await _getUserNotificationContext(uid);
                        if (userContext != null) {
                           final motive = userContext['motive'] as String;
                           final wakeTime = userContext['wakeTime'] as TimeOfDay;
                           final bedTime = userContext['bedTime'] as TimeOfDay;

                           await _rescheduleNotifications(controller.text.trim(), motive, wakeTime, bedTime);
                        }
                        
                        if (context.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: Text('Save Profile', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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

  // --- Helpers ---

  Future<Map<String, dynamic>?> _getUserNotificationContext(String uid) async {
    final userDoc = await ref.read(firestoreServiceProvider).getUserOnce(uid);
    if (!userDoc.exists || userDoc.data() == null) return null;

    final data = userDoc.data() as Map<String, dynamic>;
    final routine = Map<String, dynamic>.from(data['routine'] ?? {});

    return <String, dynamic>{
      'name': data['displayName'] ?? 'there',
      'motive': (data['primaryMotive'] as String?) ?? 'Wellness',
      'wakeTime': _parseTime(routine['wakeUpTime'] ?? '7:00 AM'),
      'bedTime': _parseTime(routine['bedTime'] ?? '10:00 PM'),
    };
  }
  
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
                color: AppColors.border,
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
                  color: AppColors.textPrimary,
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
                      final user = ref.read(authServiceProvider).currentUser;
                      if (user != null) {
                         // 1. Generate new activities
                         final newActivities = MotiveConfig.generateRoutine(
                            motive: motive, 
                            commitment: commitment,
                            supportAreas: supportAreas,
                         );
                         
                         // 2. Check if user has completed any tasks today
                         final hasActivityToday = await ref
                             .read(routineServiceProvider)
                             .hasAnyCompletedActivityToday(user.uid);

                         if (context.mounted) Navigator.pop(context);

                         if (hasActivityToday) {
                           // Case A: Has activity -> Update baseRoutine only (Apply Tomorrow)
                            await ref.read(firestoreServiceProvider).updateUser(user.uid, {
                               'primaryMotive': motive,
                               'baseRoutine': newActivities,
                            });
                            
                            // Reschedule notifications
                            final userContext = await _getUserNotificationContext(user.uid);
                            if (userContext != null) {
                               final name = userContext['name'] as String;
                               final wakeTime = userContext['wakeTime'] as TimeOfDay;
                               final bedTime = userContext['bedTime'] as TimeOfDay;

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
                                      child: Text('Got it', style: GoogleFonts.lato(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                                   )
                                 ],
                               ),
                             );
                           }

                         } else {
                           // Case B: No activity -> Update immediately
                           // We set lastGeneratedDate to past to trigger Home Screen regeneration
                           await ref.read(firestoreServiceProvider).updateUser(user.uid, {
                              'primaryMotive': motive,
                              'baseRoutine': newActivities,
                              'lastGeneratedDate': DateTime(2000, 1, 1).toIso8601String(), // Force regeneration
                           });
                            
                           // Reschedule notifications
                           final userContext = await _getUserNotificationContext(user.uid);
                           if (userContext != null) {
                              final name = userContext['name'] as String;
                              final wakeTime = userContext['wakeTime'] as TimeOfDay;
                              final bedTime = userContext['bedTime'] as TimeOfDay;

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
                                      child: Text('Let\'s Go', style: GoogleFonts.lato(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
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
                            ? AppColors.primaryDark.withValues(alpha: 0.08) 
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.primaryDark 
                              : AppColors.border,
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
                            const Icon(Icons.check_circle, color: AppColors.primaryDark),
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
       final notificationService = ref.read(notificationServiceProvider);
       await notificationService.init();
       await notificationService.requestPermissions();
       await notificationService.cancelAll();
       
       // Wake Up
       await notificationService.scheduleDailyNotification(
         id: 1, 
         title: 'Good Morning!', 
         body: NotificationContent.getMorningMessage(name, motive), 
         hour: wakeTime.hour, 
         minute: wakeTime.minute
       );
       
       // Midday (Wake + 6 hours)
       final midday = wakeTime.hour + 6;
       final middayHour = midday >= 24 ? midday - 24 : midday;
       await notificationService.scheduleDailyNotification(
         id: 2, 
         title: 'Check In', 
         body: NotificationContent.getAfternoonMessage(name), 
         hour: middayHour, 
         minute: wakeTime.minute
       );
       
       // Evening (Bed - 2 hours)
       final evening = bedTime.hour - 2;
       final eveningHour = evening < 0 ? evening + 24 : evening;
       await notificationService.scheduleDailyNotification(
         id: 3, 
         title: 'Wind Down', 
         body: NotificationContent.getEveningMessage(name), 
         hour: eveningHour, 
         minute: bedTime.minute
       );
       
       // Bedtime
       await notificationService.scheduleDailyNotification(
         id: 4, 
         title: 'Sweet Dreams', 
         body: NotificationContent.getBedtimeMessage(name), 
         hour: bedTime.hour, 
         minute: bedTime.minute
       );
       
     } catch (e, stackTrace) {
       appLogger.e('Error rescheduling notifications', error: e, stackTrace: stackTrace);
     }
  }
}




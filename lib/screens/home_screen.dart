import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';

import '../features/home/presentation/home_content_view.dart';
import '../theme/app_colors.dart';
import '../widgets/common/safe_image.dart';
import '../widgets/calm/mini_audio_player.dart';
import '../config/tour_keys.dart';
import 'calm_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContentView(),
    const CalmScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  Color _getBackgroundColor() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return AppColors.morningSky;
    } else if (hour >= 12 && hour < 17) {
      return AppColors.afternoonSun.withOpacity(0.5);
    } else if (hour >= 17 && hour < 20) {
      return AppColors.eveningDark;
    } else {
      return AppColors.nightDark;
    }
  }

  String _getBackgroundImage() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'assets/images/background_morning.png';
    } else if (hour >= 12 && hour < 17) {
      return 'assets/images/background_afternoon.png';
    } else if (hour >= 17 && hour < 20) {
      return 'assets/images/background_evening.png';
    } else {
      return 'assets/images/background_night.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(color: _getBackgroundColor()),
        Positioned(
          top: -100,
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeAssetImage(
            _getBackgroundImage(),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Positioned.fill(child: Container(color: Colors.white.withOpacity(0.1))),
        ShowCaseWidget(
          enableAutoScroll: true,
          onFinish: () {
            TourKeys.onTourFinished?.call();
            TourKeys.onTourFinished = null;
          },
          builder: (context) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: false,
              extendBody: false,
              body: Stack(
                children: [
                  IndexedStack(index: _currentIndex, children: _screens),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
                    child: MiniAudioPlayer(primaryColor: const Color(0xFF4DB6AC)),
                  ),
                ],
              ),
              bottomNavigationBar: Showcase(
                key: TourKeys.navBarKey,
                title: 'Navigation',
                description: 'Switch between Home, Calm, Chat, and Profile anytime from here!',
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
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: BottomNavigationBar(
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        setState(() => _currentIndex = index);
                      },
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: AppColors.backgroundLight,
                      selectedItemColor: AppColors.primary,
                      unselectedItemColor: AppColors.navBarUnselected,
                      selectedLabelStyle: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      unselectedLabelStyle: GoogleFonts.lato(fontSize: 12),
                      elevation: 0,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home_rounded),
                          activeIcon: Icon(Icons.home_rounded),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.spa_outlined),
                          activeIcon: Icon(Icons.spa_rounded),
                          label: 'Calm',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.chat_bubble_outline),
                          activeIcon: Icon(Icons.chat_bubble_rounded),
                          label: 'Chat',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person_outline),
                          activeIcon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';
import '../../features/calm/application/offline_data_service.dart';

/// Simple offline status banner
/// Shows when device is offline
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  StreamSubscription<bool>? _offlineSubscription;

  @override
  void initState() {
    super.initState();
    _listenToOfflineStatus();
  }

  void _listenToOfflineStatus() {
    try {
      final offlineService = OfflineDataService();

      // Set initial state
      setState(() {
        _isOffline = offlineService.isOffline;
      });

      // Listen to changes
      _offlineSubscription = offlineService.offlineStatusStream.listen((
        isOffline,
      ) {
        if (mounted) {
          setState(() {
            _isOffline = isOffline;
          });
        }
      });
    } catch (e) {
      // If offline service not initialized, assume online
      debugPrint('Offline banner: service not available: $e');
    }
  }

  @override
  void dispose() {
    _offlineSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade100,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline - Changes will sync when connected',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

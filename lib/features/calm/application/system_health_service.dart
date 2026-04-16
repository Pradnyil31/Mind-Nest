import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'error_recovery_service.dart';
import 'robust_audio_service.dart';
import 'data_integrity_service.dart';
import 'cache_management_service.dart';
import 'privacy_security_service.dart';

/// Service for monitoring system health and providing diagnostics
class SystemHealthService {
  final ErrorRecoveryService _errorRecovery;
  final RobustAudioService? _audioService;
  final DataIntegrityService _dataIntegrity;
  final CacheManagementService _cacheService;
  final PrivacySecurityService _privacyService;

  Timer? _healthCheckTimer;
  final StreamController<SystemHealthReport> _healthReportController =
      StreamController<SystemHealthReport>.broadcast();

  SystemHealthService({
    required ErrorRecoveryService errorRecovery,
    RobustAudioService? audioService,
    required DataIntegrityService dataIntegrity,
    required CacheManagementService cacheService,
    required PrivacySecurityService privacyService,
  }) : _errorRecovery = errorRecovery,
       _audioService = audioService,
       _dataIntegrity = dataIntegrity,
       _cacheService = cacheService,
       _privacyService = privacyService;

  /// Stream of system health reports
  Stream<SystemHealthReport> get healthReports =>
      _healthReportController.stream;

  /// Starts continuous health monitoring
  Future<void> startHealthMonitoring({
    Duration interval = const Duration(minutes: 5),
  }) async {
    try {
      _healthCheckTimer?.cancel();

      // Perform initial health check
      await performHealthCheck();

      // Schedule periodic health checks
      _healthCheckTimer = Timer.periodic(interval, (_) async {
        try {
          await performHealthCheck();
        } catch (e) {
          developer.log(
            'Health check failed: $e',
            name: 'SystemHealthService',
            error: e,
          );
        }
      });

      developer.log(
        'Health monitoring started with ${interval.inMinutes}min interval',
        name: 'SystemHealthService',
      );
    } catch (e) {
      developer.log(
        'Failed to start health monitoring: $e',
        name: 'SystemHealthService',
        error: e,
      );
    }
  }

  /// Stops health monitoring
  void stopHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    developer.log('Health monitoring stopped', name: 'SystemHealthService');
  }

  /// Performs comprehensive system health check
  Future<SystemHealthReport> performHealthCheck() async {
    final report = SystemHealthReport(
      timestamp: DateTime.now(),
      overallHealth: SystemHealth.unknown,
      components: {},
      recommendations: [],
      criticalIssues: [],
    );

    try {
      // Check device resources
      report.components['device'] = await _checkDeviceHealth();

      // Check network connectivity
      report.components['network'] = await _checkNetworkHealth();

      // Check audio system
      if (_audioService != null) {
        report.components['audio'] = await _checkAudioHealth();
      }

      // Check data integrity
      report.components['data'] = await _checkDataHealth();

      // Check cache system
      report.components['cache'] = await _checkCacheHealth();

      // Check privacy/security
      report.components['privacy'] = await _checkPrivacyHealth();

      // Calculate overall health
      report.overallHealth = _calculateOverallHealth(report.components);

      // Generate recommendations
      report.recommendations = _generateRecommendations(report.components);

      // Identify critical issues
      report.criticalIssues = _identifyCriticalIssues(report.components);

      // Emit health report
      _healthReportController.add(report);

      developer.log(
        'Health check completed: ${report.overallHealth}',
        name: 'SystemHealthService',
      );

      return report;
    } catch (e) {
      developer.log(
        'Health check failed: $e',
        name: 'SystemHealthService',
        error: e,
      );

      report.overallHealth = SystemHealth.critical;
      report.criticalIssues.add('Health check system failure: $e');
      return report;
    }
  }

  /// Performs emergency system recovery
  Future<bool> performEmergencyRecovery() async {
    try {
      developer.log(
        'Starting emergency system recovery',
        name: 'SystemHealthService',
      );

      final recoverySteps = <String, Future<bool> Function()>{
        'Clear corrupted cache': () => _cacheService.clearAllCache(),
        'Perform data integrity check': () async {
          final results = await _dataIntegrity.performIntegrityCheck();
          return results.values.every((valid) => valid);
        },
        'Reset privacy settings': () async {
          await _privacyService.initialize();
          return true;
        },
        'Dispose audio resources': () async {
          await _audioService?.dispose();
          return true;
        },
      };

      final results = <String, bool>{};

      for (final entry in recoverySteps.entries) {
        try {
          results[entry.key] = await _errorRecovery.withTimeout(
            entry.value,
            false,
            timeout: const Duration(seconds: 30),
            operationName: entry.key,
          );
        } catch (e) {
          results[entry.key] = false;
          developer.log(
            'Recovery step "${entry.key}" failed: $e',
            name: 'SystemHealthService',
            error: e,
          );
        }
      }

      final successCount = results.values.where((success) => success).length;
      final totalSteps = results.length;

      developer.log(
        'Emergency recovery completed: $successCount/$totalSteps steps successful',
        name: 'SystemHealthService',
      );

      return successCount >= (totalSteps * 0.7); // 70% success rate
    } catch (e) {
      developer.log(
        'Emergency recovery failed: $e',
        name: 'SystemHealthService',
        error: e,
      );
      return false;
    }
  }

  /// Gets current system diagnostics
  Future<Map<String, dynamic>> getSystemDiagnostics() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final connectivity = Connectivity();

      Map<String, dynamic> platformInfo = {};

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        platformInfo = {
          'platform': 'Android',
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        platformInfo = {
          'platform': 'iOS',
          'version': iosInfo.systemVersion,
          'model': iosInfo.model,
          'name': iosInfo.name,
        };
      }

      final connectivityResult = await connectivity.checkConnectivity();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'device': platformInfo,
        'connectivity': connectivityResult.toString(),
        'audio':
            _audioService?.getSystemHealth() ?? {'status': 'not_available'},
        'cache': await _cacheService.getCacheHealth(),
        'data': await _dataIntegrity.getStorageHealth(),
        'privacy': await _privacyService.getComplianceStatus(),
      };
    } catch (e) {
      developer.log(
        'Failed to get system diagnostics: $e',
        name: 'SystemHealthService',
        error: e,
      );
      return {'error': e.toString()};
    }
  }

  /// Disposes the health service
  void dispose() {
    stopHealthMonitoring();
    _healthReportController.close();
  }

  // Private helper methods

  Future<ComponentHealth> _checkDeviceHealth() async {
    try {
      // Check available storage space
      // This is a simplified check - in production you'd check actual storage
      final issues = <String>[];

      // Simulate storage check
      final freeSpaceGB = 2.5; // Simulated value
      if (freeSpaceGB < 1.0) {
        issues.add(
          'Low storage space: ${freeSpaceGB.toStringAsFixed(1)}GB free',
        );
      }

      // Check memory usage (simplified)
      final memoryUsageMB = 150; // Simulated value
      if (memoryUsageMB > 500) {
        issues.add('High memory usage: ${memoryUsageMB}MB');
      }

      return ComponentHealth(
        status: issues.isEmpty ? HealthStatus.healthy : HealthStatus.warning,
        issues: issues,
        metrics: {'freeSpaceGB': freeSpaceGB, 'memoryUsageMB': memoryUsageMB},
      );
    } catch (e) {
      return ComponentHealth(
        status: HealthStatus.error,
        issues: ['Device health check failed: $e'],
        metrics: {},
      );
    }
  }

  Future<ComponentHealth> _checkNetworkHealth() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();

      final issues = <String>[];
      HealthStatus status = HealthStatus.healthy;

      if (result.contains(ConnectivityResult.none)) {
        status = HealthStatus.warning;
        issues.add('No network connectivity');
      }

      return ComponentHealth(
        status: status,
        issues: issues,
        metrics: {
          'connectivity': result.toString(),
          'isOnline': !result.contains(ConnectivityResult.none),
        },
      );
    } catch (e) {
      return ComponentHealth(
        status: HealthStatus.error,
        issues: ['Network health check failed: $e'],
        metrics: {},
      );
    }
  }

  Future<ComponentHealth> _checkAudioHealth() async {
    try {
      final audioHealth = _audioService!.getSystemHealth();
      final issues = <String>[];
      HealthStatus status = HealthStatus.healthy;

      final memoryUsage = audioHealth['memoryUsage'] as int? ?? 0;
      if (memoryUsage > 50 * 1024 * 1024) {
        // 50MB
        status = HealthStatus.warning;
        issues.add(
          'High audio memory usage: ${(memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB',
        );
      }

      final activePlayers = audioHealth['activePlayers'] as int? ?? 0;
      if (activePlayers > 10) {
        status = HealthStatus.warning;
        issues.add('Too many active audio players: $activePlayers');
      }

      return ComponentHealth(
        status: status,
        issues: issues,
        metrics: audioHealth,
      );
    } catch (e) {
      return ComponentHealth(
        status: HealthStatus.error,
        issues: ['Audio health check failed: $e'],
        metrics: {},
      );
    }
  }

  Future<ComponentHealth> _checkDataHealth() async {
    try {
      final storageHealth = await _dataIntegrity.getStorageHealth();
      final issues = <String>[];
      HealthStatus status = HealthStatus.healthy;

      final healthScore = storageHealth['healthScore'] as double? ?? 1.0;
      if (healthScore < 0.9) {
        status = HealthStatus.warning;
        issues.add(
          'Data integrity issues detected: ${(healthScore * 100).toStringAsFixed(1)}% healthy',
        );
      }

      final corruptedData = storageHealth['corruptedData'] as int? ?? 0;
      if (corruptedData > 0) {
        status = HealthStatus.warning;
        issues.add('$corruptedData corrupted data entries found');
      }

      return ComponentHealth(
        status: status,
        issues: issues,
        metrics: storageHealth,
      );
    } catch (e) {
      return ComponentHealth(
        status: HealthStatus.error,
        issues: ['Data health check failed: $e'],
        metrics: {},
      );
    }
  }

  Future<ComponentHealth> _checkCacheHealth() async {
    try {
      final cacheHealth = await _cacheService.getCacheHealth();
      final issues = <String>[];
      HealthStatus status = HealthStatus.healthy;

      final usagePercent = cacheHealth['cacheUsagePercent'] as int? ?? 0;
      if (usagePercent > 90) {
        status = HealthStatus.warning;
        issues.add('Cache usage high: $usagePercent%');
      }

      final queueSize = cacheHealth['syncQueueSize'] as int? ?? 0;
      if (queueSize > 100) {
        status = HealthStatus.warning;
        issues.add('Large sync queue: $queueSize items');
      }

      return ComponentHealth(
        status: status,
        issues: issues,
        metrics: cacheHealth,
      );
    } catch (e) {
      return ComponentHealth(
        status: HealthStatus.error,
        issues: ['Cache health check failed: $e'],
        metrics: {},
      );
    }
  }

  Future<ComponentHealth> _checkPrivacyHealth() async {
    try {
      final complianceStatus = await _privacyService.getComplianceStatus();
      final issues = <String>[];
      HealthStatus status = HealthStatus.healthy;

      if (!(complianceStatus['gdprCompliant'] as bool? ?? false)) {
        status = HealthStatus.warning;
        issues.add('GDPR compliance issues detected');
      }

      if (!(complianceStatus['dataEncrypted'] as bool? ?? false)) {
        status = HealthStatus.error;
        issues.add('Data encryption not properly configured');
      }

      return ComponentHealth(
        status: status,
        issues: issues,
        metrics: complianceStatus,
      );
    } catch (e) {
      return ComponentHealth(
        status: HealthStatus.error,
        issues: ['Privacy health check failed: $e'],
        metrics: {},
      );
    }
  }

  SystemHealth _calculateOverallHealth(
    Map<String, ComponentHealth> components,
  ) {
    if (components.isEmpty) return SystemHealth.unknown;

    final statuses = components.values.map((c) => c.status).toList();

    if (statuses.any((s) => s == HealthStatus.error)) {
      return SystemHealth.critical;
    } else if (statuses.any((s) => s == HealthStatus.warning)) {
      return SystemHealth.degraded;
    } else {
      return SystemHealth.healthy;
    }
  }

  List<String> _generateRecommendations(
    Map<String, ComponentHealth> components,
  ) {
    final recommendations = <String>[];

    for (final entry in components.entries) {
      final component = entry.key;
      final health = entry.value;

      if (health.status == HealthStatus.warning ||
          health.status == HealthStatus.error) {
        switch (component) {
          case 'cache':
            if (health.issues.any((issue) => issue.contains('usage high'))) {
              recommendations.add('Clear cache to free up storage space');
            }
            break;
          case 'data':
            if (health.issues.any((issue) => issue.contains('integrity'))) {
              recommendations.add('Run data integrity repair');
            }
            break;
          case 'audio':
            if (health.issues.any((issue) => issue.contains('memory'))) {
              recommendations.add('Restart audio system to free memory');
            }
            break;
          case 'network':
            if (health.issues.any((issue) => issue.contains('connectivity'))) {
              recommendations.add('Check network connection for sync features');
            }
            break;
        }
      }
    }

    return recommendations;
  }

  List<String> _identifyCriticalIssues(
    Map<String, ComponentHealth> components,
  ) {
    final criticalIssues = <String>[];

    for (final entry in components.entries) {
      final component = entry.key;
      final health = entry.value;

      if (health.status == HealthStatus.error) {
        criticalIssues.add('$component: ${health.issues.join(', ')}');
      }
    }

    return criticalIssues;
  }
}

/// System health report data structure
class SystemHealthReport {
  final DateTime timestamp;
  SystemHealth overallHealth;
  final Map<String, ComponentHealth> components;
  List<String> recommendations;
  List<String> criticalIssues;

  SystemHealthReport({
    required this.timestamp,
    required this.overallHealth,
    required this.components,
    required this.recommendations,
    required this.criticalIssues,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'overallHealth': overallHealth.toString(),
      'components': components.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'recommendations': recommendations,
      'criticalIssues': criticalIssues,
    };
  }
}

/// Individual component health status
class ComponentHealth {
  final HealthStatus status;
  final List<String> issues;
  final Map<String, dynamic> metrics;

  const ComponentHealth({
    required this.status,
    required this.issues,
    required this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {'status': status.toString(), 'issues': issues, 'metrics': metrics};
  }
}

/// Health status enumeration
enum HealthStatus { healthy, warning, error }

/// Overall system health enumeration
enum SystemHealth { healthy, degraded, critical, unknown }

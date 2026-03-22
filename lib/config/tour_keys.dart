import 'package:flutter/material.dart';

class TourKeys {
  static final GlobalKey insightsKey = GlobalKey();
  static final GlobalKey taskCardKey = GlobalKey();
  static final GlobalKey manageRoutineKey = GlobalKey();
  static final GlobalKey favoritesKey = GlobalKey();
  static final GlobalKey badgesKey = GlobalKey();
  static final GlobalKey navBarKey = GlobalKey();

  /// Called by ShowCaseWidget.onFinish to show the motive prompt after tour ends.
  static VoidCallback? onTourFinished;

  static List<GlobalKey> get featureTourKeys => [
        badgesKey,
        favoritesKey,
        taskCardKey,
        manageRoutineKey,
        insightsKey,
        navBarKey,
      ];
}

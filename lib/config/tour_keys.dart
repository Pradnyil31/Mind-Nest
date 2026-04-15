import 'package:flutter/material.dart';

class TourKeys {
  static final GlobalKey headerKey = GlobalKey();
  static final GlobalKey focusCardKey = GlobalKey();
  static final GlobalKey recommendationKey = GlobalKey();
  static final GlobalKey routineSectionKey = GlobalKey();
  static final GlobalKey aiCoachKey = GlobalKey();
  static final GlobalKey quickToolsKey = GlobalKey();
  static final GlobalKey badgesKey = GlobalKey();
  static final GlobalKey navBarKey = GlobalKey();

  /// Called by ShowCaseWidget.onFinish to show the motive prompt after tour ends.
  static VoidCallback? onTourFinished;

  static List<GlobalKey> get featureTourKeys => [
        headerKey,
        focusCardKey,
        recommendationKey,
        routineSectionKey,
        aiCoachKey,
        quickToolsKey,
        badgesKey,
        navBarKey,
      ];
}

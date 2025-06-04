/// Chart Constants - Chart Styling and Configuration
///
/// This file contains constants used for chart styling, dimensions,
/// and configuration across the statistics screen.
library;

import 'package:flutter/material.dart';

/// Default text style for statistics headers and labels
const TextStyle statisticsHeaderStyle = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 16.0,
);

/// Default text style for statistics subtitles and secondary labels
const TextStyle subStyle = TextStyle(
  fontSize: 14.0,
  color: Colors.grey,
);

/// Chart dimensions and layout constants
class ChartDimensions {
  static const double defaultPadding = 10.0;
  static const double smallSpacing = 5.0;
  static const double mediumSpacing = 10.0;
  static const double largeSpacing = 20.0;

  // Mobile chart heights as percentage of screen height
  static const double mobileTrainingsChartHeightRatio = 0.15;
  static const double mobileMuscleChartHeightRatio = 0.25;

  // Desktop chart heights as percentage of screen height
  static const double desktopMuscleChartHeightRatio = 0.65;

  // Heatmap sizing
  static const double heatmapWidthRatio = 0.8;
  static const double heatmapImageWidthRatio = 0.5;
  static const double heatmapMaxWidthRatio = 0.8;
}

/// Chart styling constants
class ChartStyles {
  // Line chart styling
  static const double defaultLineWidth = 2.0;
  static const Color defaultLineColor = Colors.blue;
  static const bool defaultShowDots = true;
  static const bool defaultIsCurved = false;

  // Bar chart styling
  static const double legendIconSize = 14.0;
  static const double legendFontSize = 10.0;
  static const double barWidth = 2.0; // Added missing barWidth constant

  // Chart limits
  static const double trainingsPerWeekMaxY = 7.0;
  static const double trainingsPerWeekMinY = 0.0;

  // Exercise graph styling
  static const double exerciseGraphPadding = 10.0;
  static const double exerciseGraphScoreMargin = 5.0;
  static const int weeklyInterval = 7;
  static const int biWeeklyInterval = 14;
  static const double historyThreshold = 30.0;
}

/// Color schemes for different chart types
class ChartColors {
  static const Color caloriesLineColor = Colors.red;
  static const Color durationLineColor = Colors.blue;
  static const Color exerciseProgressColor = Colors.blue;

  // Activity stat card colors
  static const Color totalSessionsColor = Colors.blue;
  static const Color totalMinutesColor = Colors.green;
  static const Color totalCaloriesColor = Colors.orange;
  static const Color avgDurationColor = Colors.purple;
}

/// Date filtering constants
class DateFilterConstants {
  static const int defaultStatsDaysLimit = 90;
  static const int defaultActivityDaysLimit = 30;
  static const int defaultExerciseGraphDaysLimit = 30;
  static const int cacheExpiryMinutes = 5;
}

/// Text formatting constants
class TextConstants {
  static const String noDataMessage = "No training data available";
  static const String startWorkoutMessage =
      "Start adding workouts to see your statistics";
  static const String errorLoadingMessage = "Error loading data";
  static const String selectExerciseMessage =
      "Select an exercise to view progress";

  // Section titles
  static const String trainingIntervalTitle = "Selected Training Interval";
  static const String trainingsPerWeekTitle = "Number of Trainings per Week";
  static const String muscleUsageTitle = "Muscle usage per Exercise";
  static const String heatmapTitle = "Heatmap: relative to most used muscle";
  static const String exerciseProgressTitle = "Exercise Progress";
  static const String activitiesTitle = "Activities";
  static const String activitiesOverviewTitle = "Activities Overview";
  static const String trendsTitle = "Trends";
  static const String caloriesTrendTitle = "Calories Burned Over Time";
  static const String durationTrendTitle = "Activity Duration Over Time";
  static const String statisticsOverviewTitle = "Statistics Overview";
  static const String statisticsViewsTitle = "Statistics Views";
}

/// Widget constraints
class WidgetConstraints {
  // Date picker constraints
  static const BoxConstraints datePickerConstraints = BoxConstraints(
    minWidth: 250,
    maxWidth: 400,
  );

  static const BoxConstraints datePickerButtonConstraints = BoxConstraints(
    minWidth: 80,
    maxWidth: 120,
  );

  // Exercise dropdown constraints
  static const double exerciseDropdownWidth = 300.0;

  // Activity stat card constraints
  static const EdgeInsets activityCardMargin =
      EdgeInsets.symmetric(horizontal: 5.0);
  static const EdgeInsets activityCardPadding = EdgeInsets.all(16.0);
}

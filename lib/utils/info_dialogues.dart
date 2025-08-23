///Container for the info dialogues used in the app.
///
library;

import 'package:flutter/material.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import 'package:get_it/get_it.dart';

final container = GetIt.I<TempService>();

Widget buildInfoButton(
    String tooltip, BuildContext context, VoidCallback onPressed) {
  return IconButton(
    icon: const Icon(Icons.info_outline),
    tooltip: tooltip,
    onPressed: onPressed,
  );
}

void showInfoDialogCalorieBalance(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Calorie Balance Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Track Your Energy Balance and Metabolic Health',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Understanding Calorie Balance:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem('⚖️', 'Calorie Balance = Intake - Expenditure'),
              buildInfoItem('📈', 'Positive balance = Weight gain potential'),
              buildInfoItem('📉', 'Negative balance = Weight loss potential'),
              buildInfoItem('🎯', 'Zero balance = Weight maintenance'),
              const SizedBox(height: 12),
              const Text(
                'Setup Requirements:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem(
                  '👤', 'Enter your personal data (sex, height, weight, age)'),
              buildInfoItem('🏃', 'Select your daily activity level'),
              buildInfoItem('🔄',
                  'BMR is automatically calculated using scientific formulas'),
              const SizedBox(height: 12),
              const Text(
                'Data Sources:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Intake: From your logged food entries'),
              const Text('• Baseline: BMR × Activity multiplier'),
              const Text(
                  '• Activity: Additional calories from logged activities'),
              const Text('• Total expenditure: Baseline + Activity calories'),
              const SizedBox(height: 12),
              const Text(
                'Activity Levels:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                  '• choose the activity level that best describes your daily routine. Do not take activities into account that you log in the activity module.'),
              const Text('• 1.2 - Only sitting/lying (desk job, no exercise)'),
              const Text('• 1.4 - Mostly sitting (light activity)'),
              const Text('• 1.6 - Mixed sitting/standing/walking'),
              const Text('• 1.8 - Mostly standing/walking'),
              const Text('• 2.0 - Physical work'),
              const Text('• 2.2 - Hard physical work'),
              const SizedBox(height: 12),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem(
                  '💡',
                  'BMR calculations are estimates - individual metabolism varies.\n'
                      'Log both food intake and activities for accurate balance tracking.\n'
                      'Use the settings button to update your personal information.\n'
                      'Consistent tracking over weeks provides better insights than daily fluctuations.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      );
    },
  );
}

void showInfoDialogStatistics(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Statistics Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Desktop Statistics',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              buildInfoItem('📊', 'Overview'),
              buildInfoItem('📈', 'Trainings Per Week'),
              buildInfoItem('🔥', 'Heat Map for Muscle usage'),
              buildInfoItem('📋', 'Per Exercise Progress'),
              buildInfoItem('🏃', 'Activity Statistics'),
              buildInfoItem('🍽️', 'Nutrition and Metabolic balance'),
              const SizedBox(height: 12),
              const Text(
                'Mobile Statistics',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              buildInfoItem('📊', 'Overview'),
              buildInfoItem('📈', 'Trainings Per Week'),
              buildInfoItem('🔥', 'Heat Map for Muscle usage'),
              buildInfoItem('🏃', 'Overview'),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem('💡',
                  'Open this screen on your desktop browser to see additional and more detailed statistics and analytics'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      );
    },
  );
}

void showInfoDialogSettingsSetup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Settings Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Manage Your Application Data',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Data Export:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem('📊',
                  'Export your training data, exercises, workouts, and foods to CSV files'),
              const SizedBox(height: 12),
              const Text(
                'Data Import:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem('📂', 'Import CSV files'),
              buildInfoItem('⚠️',
                  'Importing will replace existing data in that category'),
              const SizedBox(height: 12),
              const Text(
                'Data Management:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                  '• Export individual data types (trainings, exercises, workouts, foods)'),
              const Text('• Import data selectively by category'),
              const Text('• Clear specific data types when needed'),
              const SizedBox(height: 12),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem(
                  '💡',
                  'Regular backups help protect your training progress.\n'
                      'Import operations will clear existing data first.\n'
                      'CSV files can be opened in spreadsheet applications for analysis or shared with others.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      );
    },
  );
}

void showInfoDialogFoodSetup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Food Tracker Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Track Your Nutrition and Food Intake',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Food Logging:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem('🍎', 'Search and select foods from your database'),
              buildInfoItem(
                  '⚖️', 'Enter the weight in grams for accurate tracking'),
              buildInfoItem(
                  '📊', 'View calculated nutrition for your portion size'),
              const SizedBox(height: 12),
              const Text(
                'Managing Foods:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                  '• Create custom foods with your own nutritional data'),
              const Text(
                  '• View nutritional breakdown per 100g and for your portion'),
              const Text('• Delete food logs or custom foods as needed'),
              const SizedBox(height: 12),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem(
                  '💡',
                  'Create a custom food database, start with your most common food items.\n'
                      'Nutritional values are shown per 100g - enter your actual portion weight for accurate tracking.\n'
                      'Use the Stats tab to monitor your daily and overall nutrition intake.\n'
                      'Consistent logging helps you understand your eating patterns and protein intake for muscle gain'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      );
    },
  );
}

void showInfoDialogActivitySetup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Activity Tracker Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Track Your extracurricular Activities',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Activity Logging:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem('🏃',
                  'Select from various activity types (walking, running, cycling, etc.)'),
              buildInfoItem('⏱️',
                  'Enter duration in minutes for accurate calorie calculation'),
              buildInfoItem('🔥',
                  'Calories are automatically calculated based on activity and duration'),
              const SizedBox(height: 12),
              const Text(
                'Managing Activities:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                  '• Choose from pre-loaded activities with standard calorie rates'),
              const Text(
                  '• Create custom activities with your own calorie-per-hour values'),
              const Text(
                  '• View activity history with calories burned and duration'),
              const Text('• Delete logs or activities as needed'),
              const SizedBox(height: 12),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem(
                  '💡',
                  'Calorie burn rates are estimates based on average values - individual results will vary.\n'
                      'Create custom activities for sports or exercises not in the default list.\n'
                      'Track both duration and intensity to get better insights into your activity patterns.\n'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      );
    },
  );
}

void showInfoDialogWorkoutSetup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Workout Setup Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create and Configure Your Perfect Workout',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Workout Configuration:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem('📝', 'Set a unique name for your workout routine'),
              buildInfoItem(
                  '🏋️', 'Select exercises from your exercise library'),
              buildInfoItem('🔢', 'Configure warm-up sets (0-10 sets)'),
              buildInfoItem(
                  '💪', 'Set work sets for each exercise (1-10 sets)'),
              const SizedBox(height: 12),
              const Text(
                'Adding Exercises:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Choose exercises from the dropdown/list'),
              const Text('• Set warm-up and workout set amounts'),
              const Text('• Click the arrow button to add to your workout'),
              const Text('• Remove exercises using the delete button'),
              const SizedBox(height: 12),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem(
                  '💡',
                  'Warm-up sets help prevent injury and prepare your body for heavier loads.\n'
                      'Work sets are your main training volume - adjust based on your goals.\n'
                      'Save your workout as a template to reuse in future training sessions.\n'
                      'You can edit and modify saved workouts anytime.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      );
    },
  );
}

void showInfoDialogExerciseSetup(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Exercise Setup Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create and Configure Your Perfect Exercise',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Exercise Configuration:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem('📝', 'Set a unique name for your exercise'),
              buildInfoItem('🏋️',
                  'Choose equipment type (Free weights, Machine, Cable, Bodyweight)'),
              buildInfoItem('🔢', 'Define repetition range (min-max reps)'),
              buildInfoItem('⚖️', 'Set weight increment steps for progression'),
              buildInfoItem('💪', 'Select which muscle groups are activated'),
              const SizedBox(height: 12),
              const Text(
                'Muscle Group Selection:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Tap muscle groups on the body diagram'),
              const Text(
                  '• Click multiple times to increase intensity (25%, 50%, 75%, 100%)'),
              const Text(
                  '• Set primary muscles to 75-100% and secondary to 25-50%'),
              const Text('• This helps track balanced muscle development'),
              const SizedBox(height: 12),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildInfoItem(
                  '💡',
                  'Rep range and weight increments track your progressive overload journey.\n'
                      'Increase weight when you reach maximum reps. Set ranges so you can barely reach minimum reps after weight increase.\n'
                      'These values are individual - adjust through experience and trial. You can always change them later.'),
              //
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      );
    },
  );
}

void showInfoDialogMain(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('About Gymli'),
        content: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Gymli, the son of Gain, proud member of the fellowship of the Gym.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                buildInfoItem(
                    '🏋️', 'Browse and organize your favorite Exercises'),
                buildInfoItem('📋', 'Follow structured workout routines'),
                buildInfoItem('📊',
                    'Track your progress in your progressive overload journey'),
                buildInfoItem('🏃', 'track your extracurricular activities'),
                buildInfoItem('🍽️', 'Log your meals and track your nutrition'),
                buildInfoItem('🤓', 'Check your statistics'),
                const SizedBox(height: 12),
                const Text(
                  'On this screen:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('The heart of Gymli, where you can:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• See your exercise list and'),
                const Text('• Filter them by your workout routine'),
                const Text('• or by muscle group'),
                const Text('• start your training by selecting an exercise'),
                const Text(
                    '• navigate to the other modules to create exercises, workout, log your nutrition or activities'),
              ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      );
    },
  );
}

// Also make this public
Widget buildInfoItem(String icon, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

import 'package:Gymli/themeColors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Color orange = ThemeColors.themeOrange;
Color blue = ThemeColors.themeBlue;

class StatisticTexts extends StatelessWidget {
  final int numberOfTrainingDays;
  final String trainingDuration;
  final int freeWeightsCount;
  final int machinesCount;
  final int cablesCount;
  final int bodyweightCount;
  final Map<String, dynamic> activityStats;
  final String Function() getCaloriesDisplayValue;
  final int totalWeightLiftedKg; // <-- New parameter

  const StatisticTexts({
    super.key,
    required this.numberOfTrainingDays,
    required this.trainingDuration,
    required this.freeWeightsCount,
    required this.machinesCount,
    required this.cablesCount,
    required this.bodyweightCount,
    required this.activityStats,
    required this.getCaloriesDisplayValue,
    required this.totalWeightLiftedKg, // <-- New parameter
  });

  // Helper for real-world comparison
  Map<String, dynamic> getWeightComparison(int kg) {
    final objects = [
      {
        'name': 'Car',
        'weight': 1500,
        'icon': Icons.directions_car,
      },
      {
        'name': 'Elephant',
        'weight': 6000,
        'icon': Icons.pets,
      },
      {
        'name': 'School Bus',
        'weight': 12000,
        'icon': Icons.directions_bus,
      },
      {
        'name': 'Tyrannosaurus Rex',
        'weight': 20000,
        'icon': Icons.park,
      },
      {
        'name': 'Loaded Cement Mixer',
        'weight': 30000,
        'icon': Icons.construction,
      },
      {
        'name': 'Railway Locomotive',
        'weight': 90000,
        'icon': Icons.train,
      },
      {
        'name': 'Blue Whale',
        'weight': 150000,
        'icon': Icons.water,
      },
      {
        'name': 'Boeing 747',
        'weight': 400000,
        'icon': Icons.flight,
      },
      {
        'name': 'Statue of Liberty',
        'weight': 225000,
        'icon': Icons.emoji_flags,
      },
      {
        'name': 'International Space Station',
        'weight': 420000,
        'icon': Icons.public,
      },
      {
        'name': 'Saturn V Rocket (fully fueled)',
        'weight': 2900000,
        'icon': Icons.rocket,
      },
      {
        'name': 'Great Pyramid of Giza',
        'weight': 6000000,
        'icon': Icons.account_balance,
      },
      {
        'name': 'Eiffel Tower',
        'weight': 10100000,
        'icon': Icons.location_city,
      },
      {
        'name': 'Empire State Building',
        'weight': 365000000,
        'icon': Icons.apartment,
      },
      {
        'name': 'Golden Gate Bridge',
        'weight': 887000000,
        'icon': FontAwesomeIcons.bridge,
      },
      {
        'name': 'Great Wall of China (per km)',
        'weight': 5000000000,
        'icon': Icons.fort,
      },
    ];

    for (final obj in objects.reversed) {
      final weight = obj['weight'] as num;
      if (kg >= weight) {
        final times = (kg / weight).toStringAsFixed(2);
        return {
          'name': obj['name'],
          'icon': obj['icon'],
          'times': times,
        };
      }
    }
    return {
      'name': 'Car',
      'icon': Icons.directions_car,
      'times': (kg / 1500).toStringAsFixed(2),
    };
  }

  @override
  Widget build(BuildContext context) {
    final comparison = getWeightComparison(totalWeightLiftedKg);

    return Column(children: [
      Card(
        color: Colors.white,
        shadowColor: blue,
        //surfaceTintColor: blue,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(comparison['icon'], color: Colors.black, size: 32),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  "Total weight lifted: $totalWeightLiftedKg kg \n That's about ${comparison['times']}x the weight of a ${comparison['name']}",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      Card(
          color: Colors.white,
          shadowColor: orange,
          //surfaceTintColor: orange,
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    "Number of training days: $numberOfTrainingDays",
                    //style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    trainingDuration,
                    //style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fitness_center, color: Colors.black, size: 20),
                      const SizedBox(width: 4),
                      Text("$freeWeightsCount"),
                      const SizedBox(width: 8),
                      Icon(Icons.forklift, color: Colors.black, size: 20),
                      const SizedBox(width: 4),
                      Text("$machinesCount"),
                      const SizedBox(width: 8),
                      Icon(Icons.cable, color: Colors.black, size: 20),
                      const SizedBox(width: 4),
                      Text("$cablesCount"),
                      const SizedBox(width: 8),
                      Icon(Icons.sports_gymnastics,
                          color: Colors.black, size: 20),
                      const SizedBox(width: 4),
                      Text("$bodyweightCount"),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sports, color: Colors.black, size: 20),
                      const SizedBox(width: 4),
                      Text("${activityStats['total_sessions'] ?? 0}"),
                      const SizedBox(width: 8),
                      Icon(Icons.timer, color: Colors.black, size: 20),
                      const SizedBox(width: 4),
                      Text(
                          "${activityStats['total_duration_minutes'] ?? 0} min"),
                      const SizedBox(width: 8),
                      Icon(Icons.local_fire_department,
                          color: Colors.black, size: 20),
                      const SizedBox(width: 4),
                      Text("${getCaloriesDisplayValue()} kcal"),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ))
    ]);
  }
}

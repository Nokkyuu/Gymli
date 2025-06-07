import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../user_service.dart';
import '../../../api_models.dart';
import '../../../responsive_helper.dart';

class FoodStatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<FoodStatsScreen> {
  final UserService userService = UserService();
  Map<String, double> nutritionStats = {};

  @override
  void initState() {
    super.initState();
    _loadNutritionStats();
  }

  void _loadNutritionStats() async {
    try {
      final stats = await userService.getFoodLogStats(
        startDate: DateTime.now().subtract(Duration(days: 30)),
        endDate: DateTime.now(),
      );
      setState(() {
        nutritionStats = stats;
      });
    } catch (e) {
      // Handle error
      print('Error loading nutrition stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nutrition Stats'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's nutrition summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Nutrition',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<Map<String, double>>(
                      future: userService.getFoodLogStats(
                        startDate: DateTime.now()
                            .subtract(Duration(hours: DateTime.now().hour)),
                        endDate: DateTime.now(),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final stats = snapshot.data!;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                  'Calories',
                                  '${stats['total_calories']?.toStringAsFixed(0) ?? '0'}',
                                  'kcal',
                                  Colors.orange),
                              _buildStatCard(
                                  'Protein',
                                  '${stats['total_protein']?.toStringAsFixed(1) ?? '0'}',
                                  'g',
                                  Colors.red),
                              _buildStatCard(
                                  'Carbs',
                                  '${stats['total_carbs']?.toStringAsFixed(1) ?? '0'}',
                                  'g',
                                  Colors.green),
                              _buildStatCard(
                                  'Fat',
                                  '${stats['total_fat']?.toStringAsFixed(1) ?? '0'}',
                                  'g',
                                  Colors.purple),
                            ],
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Overall stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Statistics',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                            'Total Calories',
                            '${nutritionStats['total_calories']?.toStringAsFixed(0) ?? '0'}',
                            'kcal',
                            Colors.orange),
                        _buildStatCard(
                            'Total Protein',
                            '${nutritionStats['total_protein']?.toStringAsFixed(1) ?? '0'}',
                            'g',
                            Colors.red),
                        _buildStatCard(
                            'Total Carbs',
                            '${nutritionStats['total_carbs']?.toStringAsFixed(1) ?? '0'}',
                            'g',
                            Colors.green),
                        _buildStatCard(
                            'Total Fat',
                            '${nutritionStats['total_fat']?.toStringAsFixed(1) ?? '0'}',
                            'g',
                            Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

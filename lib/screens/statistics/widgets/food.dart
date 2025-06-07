import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../user_service.dart';

class FoodStatsScreen extends StatefulWidget {
  final String? startingDate;
  final String? endingDate;
  final bool useDefaultDateFilter;

  const FoodStatsScreen({
    super.key,
    this.startingDate,
    this.endingDate,
    this.useDefaultDateFilter = true,
  });

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<FoodStatsScreen> {
  final UserService userService = UserService();
  Map<String, double> nutritionStats = {};
  List<Map<String, dynamic>> dailyNutritionData = [];

  @override
  void initState() {
    super.initState();
    _loadNutritionStats();
  }

  // Helper method to parse date from string format (same as in statistics screen)
  DateTime _parseDate(String dateString) {
    try {
      final parts = dateString.split('-');
      return DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  // Helper method to get date range based on filter settings
  Map<String, DateTime> _getDateRange() {
    DateTime startDate;
    DateTime endDate;

    if (widget.useDefaultDateFilter) {
      // Use default 3-month range
      endDate = DateTime.now();
      startDate = endDate.subtract(const Duration(days: 90));
    } else {
      // Use selected dates from date picker
      startDate = widget.startingDate != null
          ? _parseDate(widget.startingDate!)
          : DateTime.now().subtract(const Duration(days: 90));
      endDate = widget.endingDate != null
          ? _parseDate(widget.endingDate!)
          : DateTime.now();
    }
    // Alternative approach - add one day to make it exclusive
    endDate = DateTime(endDate.year, endDate.month, endDate.day)
        .add(Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
    return {'start': startDate, 'end': endDate};
  }

  void _loadNutritionStats() async {
    try {
      final dateRange = _getDateRange();
      final stats = await userService.getFoodLogStats(
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );

      // Load daily data for the chart
      final dailyData = await userService.getDailyFoodLogStats(
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );

      setState(() {
        nutritionStats = stats;
        dailyNutritionData = dailyData;
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
            // Nutrition Trend Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Nutrition Trends',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Calories Chart
                    Text(
                      'Daily Calories',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 250,
                      child: _buildCaloriesChart(),
                    ),
                    _buildCaloriesLegend(),
                    const SizedBox(height: 24),
                    // Macros Chart
                    Text(
                      'Daily Macronutrients',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 250,
                      child: _buildMacrosChart(),
                    ),
                    _buildMacrosLegend(),
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
                    Text(
                      widget.useDefaultDateFilter
                          ? 'Overall Statistics (Last 90 Days)'
                          : 'Statistics for Selected Period',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildCaloriesChart() {
    if (dailyNutritionData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Prepare data for calories
    List<FlSpot> caloriesSpots = [];

    for (int i = 0; i < dailyNutritionData.length; i++) {
      final data = dailyNutritionData[i];
      final x = i.toDouble();
      caloriesSpots.add(FlSpot(x, (data['calories'] ?? 0).toDouble()));
    }

    final maxCalories = caloriesSpots.isEmpty
        ? 0.0
        : caloriesSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text('Calories (kcal)',
                style: TextStyle(color: Colors.orange, fontSize: 12)),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.orange, fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: dailyNutritionData.length > 10
                  ? (dailyNutritionData.length / 5).floor().toDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < dailyNutritionData.length) {
                  final date =
                      DateTime.parse(dailyNutritionData[value.toInt()]['date']);
                  return Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (dailyNutritionData.length - 1).toDouble(),
        minY: 0,
        maxY: maxCalories * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: caloriesSpots,
            isCurved: false,
            color: Colors.orange,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots
                  .map((barSpot) {
                    final index = barSpot.x.toInt();
                    if (index >= 0 && index < dailyNutritionData.length) {
                      final data = dailyNutritionData[index];
                      final date = DateTime.parse(data['date']);
                      final calories =
                          data['calories']?.toStringAsFixed(0) ?? '0';

                      return LineTooltipItem(
                        '${DateFormat('dd/MM').format(date)}\nCalories: $calories kcal',
                        TextStyle(color: Colors.orange),
                      );
                    }
                    return null;
                  })
                  .where((item) => item != null)
                  .toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMacrosChart() {
    if (dailyNutritionData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Prepare data for macros
    List<FlSpot> proteinSpots = [];
    List<FlSpot> carbsSpots = [];
    List<FlSpot> fatSpots = [];

    for (int i = 0; i < dailyNutritionData.length; i++) {
      final data = dailyNutritionData[i];
      final x = i.toDouble();

      proteinSpots.add(FlSpot(x, (data['protein'] ?? 0).toDouble()));
      carbsSpots.add(FlSpot(x, (data['carbs'] ?? 0).toDouble()));
      fatSpots.add(FlSpot(x, (data['fat'] ?? 0).toDouble()));
    }

    final maxMacros = [
      if (proteinSpots.isNotEmpty) ...proteinSpots.map((spot) => spot.y),
      if (carbsSpots.isNotEmpty) ...carbsSpots.map((spot) => spot.y),
      if (fatSpots.isNotEmpty) ...fatSpots.map((spot) => spot.y)
    ].isEmpty
        ? 0.0
        : [
            ...proteinSpots.map((spot) => spot.y),
            ...carbsSpots.map((spot) => spot.y),
            ...fatSpots.map((spot) => spot.y)
          ].reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text('Macros (g)',
                style: TextStyle(color: Colors.blue, fontSize: 12)),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.blue, fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: dailyNutritionData.length > 10
                  ? (dailyNutritionData.length / 5).floor().toDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < dailyNutritionData.length) {
                  final date =
                      DateTime.parse(dailyNutritionData[value.toInt()]['date']);
                  return Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (dailyNutritionData.length - 1).toDouble(),
        minY: 0,
        maxY: maxMacros * 1.1,
        lineBarsData: [
          // Protein line
          LineChartBarData(
            spots: proteinSpots,
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Carbs line
          LineChartBarData(
            spots: carbsSpots,
            isCurved: false,
            color: Colors.green,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Fat line
          LineChartBarData(
            spots: fatSpots,
            isCurved: false,
            color: Colors.purple,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots
                  .map((barSpot) {
                    final index = barSpot.x.toInt();
                    if (index >= 0 && index < dailyNutritionData.length) {
                      final data = dailyNutritionData[index];
                      final date = DateTime.parse(data['date']);

                      String label;
                      String value;

                      switch (barSpot.barIndex) {
                        case 0:
                          label = 'Protein';
                          value =
                              '${data['protein']?.toStringAsFixed(1) ?? '0'} g';
                          break;
                        case 1:
                          label = 'Carbs';
                          value =
                              '${data['carbs']?.toStringAsFixed(1) ?? '0'} g';
                          break;
                        case 2:
                          label = 'Fat';
                          value = '${data['fat']?.toStringAsFixed(1) ?? '0'} g';
                          break;
                        default:
                          label = '';
                          value = '';
                      }

                      return LineTooltipItem(
                        '${DateFormat('dd/MM').format(date)}\n$label: $value',
                        TextStyle(color: barSpot.bar.color),
                      );
                    }
                    return null;
                  })
                  .where((item) => item != null)
                  .toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Calories', Colors.orange),
      ],
    );
  }

  Widget _buildMacrosLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Protein', Colors.red),
        _buildLegendItem('Carbs', Colors.green),
        _buildLegendItem('Fat', Colors.purple),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}

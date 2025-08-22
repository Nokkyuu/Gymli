import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import '../../../utils/info_dialogues.dart';
import 'package:get_it/get_it.dart';
import 'package:Gymli/utils/api/api_export.dart';

class CalorieBalanceScreen extends StatefulWidget {
  final String? startingDate;
  final String? endingDate;
  final bool useDefaultDateFilter;

  const CalorieBalanceScreen({
    super.key,
    this.startingDate,
    this.endingDate,
    this.useDefaultDateFilter = true,
  });

  @override
  _CalorieBalanceScreenState createState() => _CalorieBalanceScreenState();
}

class _CalorieBalanceScreenState extends State<CalorieBalanceScreen> {
  final TempService container = GetIt.I<TempService>();

  // User data for metabolic rate calculation
  String? _sex;
  double? _height; // cm
  double? _weight; // kg
  int? _age;
  double _activityMultiplier = 1.4; // Default to "mostly sitting"

  // Chart data
  List<Map<String, dynamic>> _dailyData = [];
  bool _isLoading = true;
  bool _showUserDataForm = false;

  // Form controllers
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // Load saved user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _sex = prefs.getString('calorie_balance_sex');
        _height = prefs.getDouble('calorie_balance_height');
        _weight = prefs.getDouble('calorie_balance_weight');
        _age = prefs.getInt('calorie_balance_age');
        _activityMultiplier =
            prefs.getDouble('calorie_balance_activity_multiplier') ?? 1.4;
      });

      // Update controllers with saved values
      if (_height != null) _heightController.text = _height!.toString();
      if (_weight != null) _weightController.text = _weight!.toString();
      if (_age != null) _ageController.text = _age!.toString();

      // Check if we have all required data
      if (_sex != null && _height != null && _weight != null && _age != null) {
        await _loadCalorieBalanceData();
      } else {
        setState(() {
          _isLoading = false;
          _showUserDataForm = true;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
        _showUserDataForm = true;
      });
    }
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_sex != null) await prefs.setString('calorie_balance_sex', _sex!);
      if (_height != null)
        await prefs.setDouble('calorie_balance_height', _height!);
      if (_weight != null)
        await prefs.setDouble('calorie_balance_weight', _weight!);
      if (_age != null) await prefs.setInt('calorie_balance_age', _age!);
      await prefs.setDouble(
          'calorie_balance_activity_multiplier', _activityMultiplier);
    } catch (e) {
      if (kDebugMode) print('Error saving user data: $e');
    }
  }

  // Calculate baseline daily calorie expenditure using metabolic rate formulas
  double _calculateBaselineCalories() {
    if (_sex == null || _height == null || _weight == null || _age == null) {
      return 0.0;
    }

    double bmr;
    if (_sex == 'Male') {
      // Male: 3.4*weight(kg) + 15.3*height(cm) - 6.8*age - 961
      bmr = 3.4 * _weight! + 15.3 * _height! - 6.8 * _age! - 961;
    } else {
      // Female: 2.4*weight(kg) + 9*height(cm) - 4.7*age - 65
      bmr = 2.4 * _weight! + 9 * _height! - 4.7 * _age! - 65;
    }

    // Apply activity multiplier
    return bmr * _activityMultiplier;
  }

  // Helper method to parse date from string format
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

  // Get activity level description for multiplier
  String _getActivityLevelDescription(double multiplier) {
    switch (multiplier) {
      case 1.2:
        return '1.2 - Only sitting/lying';
      case 1.4:
        return '1.4 - Mostly sitting';
      case 1.6:
        return '1.6 - Equally sitting, standing, walking';
      case 1.8:
        return '1.8 - Mostly standing/walking';
      case 2.0:
        return '2.0 - Physical work';
      case 2.2:
        return '2.2 - Hard physical work';
      default:
        return '1.4 - Mostly sitting';
    }
  }

  // Get all available activity multipliers
  List<double> _getActivityMultipliers() {
    return [1.2, 1.4, 1.6, 1.8, 2.0, 2.2];
  }

  // Get date range based on filter settings
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

    // Make end date inclusive
    endDate = DateTime(endDate.year, endDate.month, endDate.day)
        .add(Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999));

    return {'start': startDate, 'end': endDate};
  }

  // Load and combine calorie intake and expenditure data
  Future<void> _loadCalorieBalanceData() async {
    setState(() => _isLoading = true);

    try {
      final dateRange = _getDateRange();
      final baselineCalories = _calculateBaselineCalories();

      // Load food intake data
      final dailyFoodData = await container.getDailyFoodLogStats(
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );

      // Load activity expenditure data
      final activityLogs = await GetIt.I<ActivityService>().getActivityLogs(
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );

      // Create a map to aggregate daily activity calories
      Map<String, double> dailyActivityCalories = {};

      for (var log in activityLogs) {
        final dateString = log['date'] as String;
        final date = DateTime.parse(dateString);
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final calories = (log['calories_burned'] as num).toDouble();
        dailyActivityCalories[dateKey] =
            (dailyActivityCalories[dateKey] ?? 0.0) + calories;
      }

      // Combine data and fill missing dates
      Map<String, Map<String, double>> combinedData = {};
      DateTime currentDate = dateRange['start']!;

      while (currentDate.isBefore(dateRange['end']!) ||
          currentDate.isAtSameMomentAs(dateRange['end']!)) {
        final dateKey =
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

        // Find food data for this date
        final foodData = dailyFoodData.firstWhere(
          (data) => data['date'] == dateKey,
          orElse: () => {'date': dateKey, 'calories': 0.0},
        );

        final intakeCalories = (foodData['calories'] as num).toDouble();
        final activityCalories = dailyActivityCalories[dateKey] ?? 0.0;
        final totalExpenditureCalories = baselineCalories + activityCalories;

        combinedData[dateKey] = {
          'intake': intakeCalories,
          'expenditure': totalExpenditureCalories,
          'baseline': baselineCalories,
          'activity': activityCalories,
        };

        currentDate = currentDate.add(const Duration(days: 1));
      }

      // Convert to list and sort by date
      final List<Map<String, dynamic>> result = [];
      for (var entry in combinedData.entries) {
        result.add({
          'date': entry.key,
          'intake': entry.value['intake'],
          'expenditure': entry.value['expenditure'],
          'baseline': entry.value['baseline'],
          'activity': entry.value['activity'],
          'balance': entry.value['intake']! - entry.value['expenditure']!,
        });
      }

      result.sort((a, b) => a['date'].compareTo(b['date']));

      setState(() {
        _dailyData = result;
        _isLoading = false;
        _showUserDataForm = false;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading calorie balance data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Validate and save user form data
  Future<void> _submitUserData() async {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final age = int.tryParse(_ageController.text);

    if (_sex == null ||
        height == null ||
        weight == null ||
        age == null ||
        height <= 0 ||
        weight <= 0 ||
        age <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields with valid values'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _height = height;
      _weight = weight;
      _age = age;
    });

    await _saveUserData();
    await _loadCalorieBalanceData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Balance'),
        automaticallyImplyLeading: false,
        actions: [
          buildInfoButton('Calorie Balance Info', context,
              () => showInfoDialogCalorieBalance(context)),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _showUserDataForm = true;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showUserDataForm
              ? _buildUserDataForm()
              : _buildCalorieBalanceView(),
    );
  }

  Widget _buildUserDataForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This information is used to calculate your baseline daily calorie expenditure (BMR).',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Sex selection
              const Text('Sex', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Male'),
                      value: 'Male',
                      groupValue: _sex,
                      onChanged: (value) => setState(() => _sex = value),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Female'),
                      value: 'Female',
                      groupValue: _sex,
                      onChanged: (value) => setState(() => _sex = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Height input
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                  suffixText: 'cm',
                ),
              ),
              const SizedBox(height: 16),

              // Weight input
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
              ),
              const SizedBox(height: 16),

              // Age input
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                  suffixText: 'years',
                ),
              ),
              const SizedBox(height: 16),

              // Activity level dropdown
              const Text('Activity Level',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<double>(
                value: _activityMultiplier,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                items: _getActivityMultipliers().map((double value) {
                  return DropdownMenuItem<double>(
                    value: value,
                    child: Text(_getActivityLevelDescription(value)),
                  );
                }).toList(),
                onChanged: (double? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _activityMultiplier = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitUserData,
                  child: const Text('Save & Calculate'),
                ),
              ),

              // Show current baseline if available
              if (_sex != null &&
                  _height != null &&
                  _weight != null &&
                  _age != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Daily Calorie Expenditure:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_calculateBaselineCalories().toStringAsFixed(0)} kcal/day',
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BMR × ${_activityMultiplier} (${_getActivityLevelDescription(_activityMultiplier).split(' - ')[1]})',
                        style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieBalanceView() {
    if (_dailyData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No data available for the selected period',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _buildSummaryCards(),
          const SizedBox(height: 24),

          // Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Calorie Balance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Green = Intake, Red = Expenditure (Baseline + Activity)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildChart(),
                  ),
                  const SizedBox(height: 16),
                  _buildChartLegend(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Balance breakdown
          _buildBalanceBreakdown(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalIntake =
        _dailyData.fold<double>(0.0, (sum, data) => sum + data['intake']);
    final totalExpenditure =
        _dailyData.fold<double>(0.0, (sum, data) => sum + data['expenditure']);
    final totalBalance = totalIntake - totalExpenditure;
    final avgDaily = totalBalance / _dailyData.length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Intake',
            '${totalIntake.toStringAsFixed(0)} kcal',
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Total Expenditure',
            '${totalExpenditure.toStringAsFixed(0)} kcal',
            Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Avg Daily Balance',
            '${avgDaily >= 0 ? '+' : ''}${avgDaily.toStringAsFixed(0)} kcal',
            avgDaily >= 0 ? Colors.orange : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_dailyData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    List<FlSpot> intakeSpots = [];
    List<FlSpot> expenditureSpots = [];

    for (int i = 0; i < _dailyData.length; i++) {
      final data = _dailyData[i];
      final x = i.toDouble();
      intakeSpots.add(FlSpot(x, data['intake'].toDouble()));
      expenditureSpots.add(FlSpot(x, data['expenditure'].toDouble()));
    }

    final maxValue = [
      ...intakeSpots.map((spot) => spot.y),
      ...expenditureSpots.map((spot) => spot.y),
    ].reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Calories (kcal)',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.black54, fontSize: 10),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _dailyData.length > 10
                  ? (_dailyData.length / 5).floor().toDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _dailyData.length) {
                  final date =
                      DateTime.parse(_dailyData[value.toInt()]['date']);
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
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (_dailyData.length - 1).toDouble(),
        minY: 0,
        maxY: maxValue * 1.1,
        lineBarsData: [
          // Intake line
          LineChartBarData(
            spots: intakeSpots,
            isCurved: false,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
          // Expenditure line
          LineChartBarData(
            spots: expenditureSpots,
            isCurved: false,
            color: Colors.red,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.1),
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
                    if (index >= 0 && index < _dailyData.length) {
                      final data = _dailyData[index];
                      final date = DateTime.parse(data['date']);
                      final isIntake = barSpot.barIndex == 0;

                      return LineTooltipItem(
                        '${DateFormat('dd/MM').format(date)}\n${isIntake ? 'Intake' : 'Expenditure'}: ${barSpot.y.toStringAsFixed(0)} kcal',
                        TextStyle(color: isIntake ? Colors.green : Colors.red),
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

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.green, 'Calorie Intake'),
        const SizedBox(width: 24),
        _buildLegendItem(Colors.red, 'Total Expenditure'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBalanceBreakdown() {
    final baselineCalories = _calculateBaselineCalories();
    final rawBMR =
        _sex != null && _height != null && _weight != null && _age != null
            ? (_sex == 'Male'
                ? 3.4 * _weight! + 15.3 * _height! - 6.8 * _age! - 961
                : 2.4 * _weight! + 9 * _height! - 4.7 * _age! - 65)
            : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expenditure Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBreakdownCard(
                    'Raw BMR',
                    '${rawBMR.toStringAsFixed(0)} kcal/day',
                    'Basic metabolic rate',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBreakdownCard(
                    'Activity-Adjusted BMR',
                    '${baselineCalories.toStringAsFixed(0)} kcal/day',
                    'BMR × ${_activityMultiplier}',
                    Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildBreakdownCard(
                    'Average Activity',
                    '${(_dailyData.fold<double>(0.0, (sum, data) => sum + data['activity']) / _dailyData.length).toStringAsFixed(0)} kcal/day',
                    'From logged activities',
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activity Level',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getActivityLevelDescription(_activityMultiplier)
                              .split(' - ')[1],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Multiplier: ${_activityMultiplier}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Calculation Method:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BMR Formula (${_sex ?? 'Unknown'}):',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.amber[700],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _sex == 'Male'
                        ? '3.4×weight(kg) + 15.3×height(cm) - 6.8×age - 961'
                        : _sex == 'Female'
                            ? '2.4×weight(kg) + 9×height(cm) - 4.7×age - 65'
                            : 'Please select sex to see formula',
                    style: TextStyle(color: Colors.amber[700], fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily Expenditure = BMR × ${_activityMultiplier} (${_getActivityLevelDescription(_activityMultiplier).split(' - ')[1]})',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.amber[700],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(
      String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Food Screen - Nutrition Tracking Interface
///
/// This screen provides comprehensive food tracking and management for
/// nutrition monitoring and calorie tracking.
///
/// Key features:
/// - Food item management with nutritional information
/// - Food consumption logging with portion sizes and nutritional calculations
/// - Food history display with filtering capabilities
/// - Nutrition statistics and progress visualization
/// - Custom food creation and editing
/// - Food data export and management
/// - Visual feedback with charts and nutrition breakdowns
/// - Integration with user authentication and offline storage
///
/// The screen serves as the main interface for tracking food intake
/// and provides insights into nutritional consumption patterns.
library;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/user/user_service.dart';
import '../utils/api/api_models.dart';
import '../utils/themes/responsive_helper.dart';
import '../utils/info_dialogues.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodComponent {
  ApiFood? food;
  double grams = 0;
}

class _FoodScreenState extends State<FoodScreen> with TickerProviderStateMixin {
  final UserService userService = UserService();
  late TabController _tabController;
  List<_FoodComponent> _foodComponents = [_FoodComponent()];
  // Data lists
  List<ApiFood> foods = [];
  List<ApiFoodLog> foodLogs = [];
  Map<String, double> nutritionStats = {};

  // Loading states
  bool _isLoading = true;
  bool _isInitialized = false;

  // Selected food for logging
  String? selectedFoodName;

  // Search functionality
  String _foodSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Form controllers
  final TextEditingController gramsController = TextEditingController();
  final TextEditingController customFoodNameController =
      TextEditingController();
  final TextEditingController customFoodCaloriesController =
      TextEditingController();
  final TextEditingController customFoodProteinController =
      TextEditingController();
  final TextEditingController customFoodCarbsController =
      TextEditingController();
  final TextEditingController customFoodFatController = TextEditingController();
  final TextEditingController customFoodNotesController =
      TextEditingController();

  // Date selection
  DateTime selectedDate = DateTime.now();

  // Chart data
  List<FlSpot> caloriesTrendData = [];
  List<FlSpot> proteinTrendData = [];

  // Filtered foods getter
  List<ApiFood> get filteredFoods {
    if (_foodSearchQuery.isEmpty) return foods;
    return foods
        .where((food) =>
            food.name.toLowerCase().contains(_foodSearchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    gramsController.dispose();
    customFoodNameController.dispose();
    customFoodCaloriesController.dispose();
    customFoodProteinController.dispose();
    customFoodCarbsController.dispose();
    customFoodFatController.dispose();
    customFoodNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data
      final foodsData = await userService.getFoods();
      final logsData = await userService.getFoodLogs();
      final statsData = await userService.getFoodLogStats();

      setState(() {
        foods = foodsData.map((data) => ApiFood.fromJson(data)).toList();
        foodLogs = logsData.map((data) => ApiFoodLog.fromJson(data)).toList();
        nutritionStats = statsData;

        // Set default selected food by name
        if (foods.isNotEmpty && selectedFoodName == null) {
          selectedFoodName = foods.first.name;
        }

        // Verify selected food still exists
        if (selectedFoodName != null) {
          final foodExists = foods.any((f) => f.name == selectedFoodName);
          if (!foodExists && foods.isNotEmpty) {
            selectedFoodName = foods.first.name;
          }
        }

        _updateChartData();
      });
    } catch (e) {
      print('Error loading food data: $e');
      _showErrorSnackBar('Failed to load food data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateChartData() {
    // Sort logs by date for chart data
    final sortedLogs = List<ApiFoodLog>.from(foodLogs);
    sortedLogs.sort((a, b) => a.date.compareTo(b.date));

    // Create chart data points
    caloriesTrendData.clear();
    proteinTrendData.clear();

    for (int i = 0; i < sortedLogs.length; i++) {
      final log = sortedLogs[i];
      final dayIndex = log.date
          .difference(DateTime.now().subtract(const Duration(days: 30)))
          .inDays
          .toDouble();

      if (dayIndex >= 0) {
        final multiplier = log.grams / 100.0;
        final calories = log.kcalPer100g * multiplier;
        final protein = log.proteinPer100g * multiplier;

        caloriesTrendData.add(FlSpot(dayIndex, calories));
        proteinTrendData.add(FlSpot(dayIndex, protein));
      }
    }
  }

  Future<void> _logFood() async {
    if (selectedFoodName == null || gramsController.text.isEmpty) {
      _showErrorSnackBar('Please select a food and enter weight in grams');
      return;
    }

    final grams = double.tryParse(gramsController.text);
    if (grams == null || grams <= 0) {
      _showErrorSnackBar('Please enter a valid weight in grams');
      return;
    }

    // Find the selected food to get nutritional data
    final selectedFood = foods.firstWhere(
      (f) => f.name == selectedFoodName,
      orElse: () => foods.first,
    );

    try {
      await userService.createFoodLog(
        foodName: selectedFoodName!,
        date: selectedDate,
        grams: grams,
        kcalPer100g: selectedFood.kcalPer100g,
        proteinPer100g: selectedFood.proteinPer100g,
        carbsPer100g: selectedFood.carbsPer100g,
        fatPer100g: selectedFood.fatPer100g,
      );

      // Clear form
      gramsController.clear();
      selectedDate = DateTime.now();

      // Reload data
      await _loadData();

      _showSuccessSnackBar('Food logged successfully!');
    } catch (e) {
      print('Error logging food: $e');
      _showErrorSnackBar('Failed to log food');
    }
  }

  Future<void> _createCustomFood() async {
    print('Create custom food button pressed'); // Debug print

    // Check if required fields are empty
    if (customFoodNameController.text.isEmpty ||
        customFoodCaloriesController.text.isEmpty ||
        customFoodProteinController.text.isEmpty ||
        customFoodCarbsController.text.isEmpty ||
        customFoodFatController.text.isEmpty) {
      print('Fields are empty - showing error'); // Debug print
      _showErrorSnackBar('Please fill in all nutritional information');
      return;
    }

    final calories = double.tryParse(customFoodCaloriesController.text);
    final protein = double.tryParse(customFoodProteinController.text);
    final carbs = double.tryParse(customFoodCarbsController.text);
    final fat = double.tryParse(customFoodFatController.text);

    if (calories == null ||
        calories < 0 ||
        protein == null ||
        protein < 0 ||
        carbs == null ||
        carbs < 0 ||
        fat == null ||
        fat < 0) {
      _showErrorSnackBar('Please enter valid nutritional values');
      return;
    }

    try {
      print('Calling userService.createFood...'); // Debug print
      final result = await userService.createFood(
        name: customFoodNameController.text,
        kcalPer100g: calories,
        proteinPer100g: protein,
        carbsPer100g: carbs,
        fatPer100g: fat,
        notes: customFoodNotesController.text.isNotEmpty
            ? customFoodNotesController.text
            : null,
      );

      print('Food created successfully: $result'); // Debug print

      // Clear form
      customFoodNameController.clear();
      customFoodCaloriesController.clear();
      customFoodProteinController.clear();
      customFoodCarbsController.clear();
      customFoodFatController.clear();
      customFoodNotesController.clear();

      print('Reloading data...'); // Debug print
      await _loadData();
      _showSuccessSnackBar('Custom food created successfully!');
      print('Success message shown'); // Debug print
    } catch (e) {
      print('Error creating custom food: $e'); // Debug print
      _showErrorSnackBar('Failed to create custom food: ${e.toString()}');
    }
  }

  Future<void> _deleteFoodLog(ApiFoodLog log) async {
    if (log.id == null) return;

    try {
      await userService.deleteFoodLog(log.id!);
      await _loadData();
      _showSuccessSnackBar('Food log deleted');
    } catch (e) {
      print('Error deleting food log: $e');
      _showErrorSnackBar('Failed to delete food log');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Build tabs dynamically
    final List<Tab> tabs = [
      const Tab(icon: Icon(FontAwesomeIcons.plus), text: 'Log'),
      if (ResponsiveHelper.isMobile(context))
        const Tab(icon: Icon(FontAwesomeIcons.list), text: 'History'),
      //const Tab(icon: Icon(FontAwesomeIcons.chartLine), text: 'Stats'),
      const Tab(icon: Icon(FontAwesomeIcons.gear), text: 'Manage'),
    ];

    // Build tab views dynamically
    final List<Widget> tabViews = [
      _buildLogTab(),
      if (ResponsiveHelper.isMobile(context)) _buildHistoryTab(),
      //_buildStatsTab(),
      _buildManageTab(),
    ];

    // Adjust TabController length if needed
    if (_tabController.length != tabs.length) {
      _tabController.dispose();
      _tabController = TabController(length: tabs.length, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Tracker'),
        actions: [
          buildInfoButton('Food Screen info', context,
              () => showInfoDialogFoodSetup(context)),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabViews,
      ),
    );
  }

  Widget _buildLogTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Log form takes 2/3 of the width
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Log Food',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Food selection dropdown
                        //const Text('Food Item',
                        //    style: TextStyle(fontWeight: FontWeight.w500)),
                        _buildStatsTab(),
                        Autocomplete<ApiFood>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return foods;
                            }
                            return foods.where((ApiFood food) => food.name
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()));
                          },
                          displayStringForOption: (ApiFood food) => food.name,
                          fieldViewBuilder: (BuildContext context,
                              TextEditingController textEditingController,
                              FocusNode focusNode,
                              VoidCallback onFieldSubmitted) {
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                hintText: 'Type to search foods...',
                              ),
                              onFieldSubmitted: (String value) {
                                onFieldSubmitted();
                              },
                            );
                          },
                          optionsViewBuilder: (BuildContext context,
                              AutocompleteOnSelected<ApiFood> onSelected,
                              Iterable<ApiFood> options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      final ApiFood food =
                                          options.elementAt(index);
                                      return InkWell(
                                        onTap: () => onSelected(food),
                                        child: Container(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                food.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                '${food.kcalPer100g.toInt()} kcal/100g',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          onSelected: (ApiFood selectedFood) {
                            setState(() {
                              selectedFoodName = selectedFood.name;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Show nutritional info for selected food
                        if (selectedFoodName != null) ...[
                          _buildNutritionalInfo(),
                          const SizedBox(height: 16),
                        ],

                        // Date and weight input
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                const Text('Date',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now()
                                          .subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        selectedDate = date;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today),
                                        const SizedBox(width: 8),
                                        Text(DateFormat('MMM dd, yyyy')
                                            .format(selectedDate)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Column(
                              children: [
                                const Text('Weight (grams)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: gramsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        // Trigger rebuild to update calculated nutrition
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            if (!ResponsiveHelper.isMobile(context))
                              Column(
                                children: [
                                  Text(""),
                                  ElevatedButton(
                                    onPressed: _logFood,
                                    //icon: const Icon(FontAwesomeIcons.plus),

                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(5.0),
                                      child: Text('Log Food'),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (ResponsiveHelper.isMobile(context))
                          Column(
                            children: [
                              Text(""),
                              ElevatedButton(
                                onPressed: _logFood,
                                //icon: const Icon(FontAwesomeIcons.plus),

                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(5.0),
                                  child: Text('Log Food'),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),

                        // Show calculated nutrition for the portion
                        if (gramsController.text.isNotEmpty &&
                            selectedFoodName != null) ...[
                          _buildCalculatedNutrition(),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(width: 24),
          // History panel takes 1/3 of the width (only on non-mobile)
          if (!ResponsiveHelper.isMobile(context))
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _buildHistoryTab(),
                  ),
                  const Divider(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNutritionalInfo() {
    final selectedFood = foods.firstWhere(
      (f) => f.name == selectedFoodName,
      orElse: () => foods.first,
    );

    return Card(
      //color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Nutritional Info (per 100g)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientChip(
                    'Calories',
                    '${selectedFood.kcalPer100g.toInt()}',
                    'kcal',
                    Colors.orange),
                _buildNutrientChip(
                    'Protein',
                    '${selectedFood.proteinPer100g.toStringAsFixed(1)}',
                    'g',
                    Colors.red),
                _buildNutrientChip(
                    'Carbs',
                    '${selectedFood.carbsPer100g.toStringAsFixed(1)}',
                    'g',
                    Colors.green),
                _buildNutrientChip(
                    'Fat',
                    '${selectedFood.fatPer100g.toStringAsFixed(1)}',
                    'g',
                    Colors.purple),
              ],
            ),
            if (selectedFood.notes != null &&
                selectedFood.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    selectedFood.notes!,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatedNutrition() {
    final grams = double.tryParse(gramsController.text);
    if (grams == null || grams <= 0) return const SizedBox.shrink();

    final selectedFood = foods.firstWhere(
      (f) => f.name == selectedFoodName,
      orElse: () => foods.first,
    );

    final multiplier = grams / 100.0;
    final calories = selectedFood.kcalPer100g * multiplier;
    final protein = selectedFood.proteinPer100g * multiplier;
    final carbs = selectedFood.carbsPer100g * multiplier;
    final fat = selectedFood.fatPer100g * multiplier;

    return Card(
      //color: Colors.green.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculated Nutrition (for ${grams.toStringAsFixed(0)}g)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientChip('Calories', '${calories.toStringAsFixed(0)}',
                    'kcal', Colors.orange),
                _buildNutrientChip('Protein', '${protein.toStringAsFixed(1)}',
                    'g', Colors.red),
                _buildNutrientChip(
                    'Carbs', '${carbs.toStringAsFixed(1)}', 'g', Colors.green),
                _buildNutrientChip(
                    'Fat', '${fat.toStringAsFixed(1)}', 'g', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(
      String label, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            '$value$unit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatsChip(
    String label,
    String value,
    String unit,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //decoration: BoxDecoration(
          //color: color.withOpacity(0.1),
          //borderRadius: BorderRadius.circular(8),
          //border: Border.all(color: color.black(0.3)),
          //),
          child: Text(
            '$value$unit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              //color: color,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    // Sort logs by date (newest first)
    final sortedLogs = List<ApiFoodLog>.from(foodLogs);
    sortedLogs.sort((a, b) => b.date.compareTo(a.date));

    if (sortedLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.utensils, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No food logs yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Start logging your meals in the Log tab',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedLogs.length,
      itemBuilder: (context, index) {
        final log = sortedLogs[index];
        final multiplier = log.grams / 100.0;
        final totalCalories = log.kcalPer100g * multiplier;
        final totalProtein = log.proteinPer100g * multiplier;
        final totalCarbs = log.carbsPer100g * multiplier;
        final totalFat = log.fatPer100g * multiplier;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getFoodColor(log.foodName),
              child: Icon(
                _getFoodIcon(log.foodName),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(log.foodName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('MMM dd, yyyy').format(log.date)),
                Text(
                    '${log.grams.toStringAsFixed(0)}g • ${totalCalories.toStringAsFixed(0)} kcal'),
                Text(
                  'P: ${totalProtein.toStringAsFixed(1)}g • C: ${totalCarbs.toStringAsFixed(1)}g • F: ${totalFat.toStringAsFixed(1)}g',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(log),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Today's nutrition summary
        Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Today:',
                //style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
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
                        _buildStatsChip(
                          'kcal',
                          '${stats['total_calories']?.toStringAsFixed(0) ?? '0'}',
                          '',
                          // Colors.orange
                        ),
                        const SizedBox(width: 8),
                        _buildStatsChip(
                          'Protein',
                          '${stats['total_protein']?.toStringAsFixed(1) ?? '0'}',
                          'g',
                          //Colors.red
                        ),
                        const SizedBox(width: 8),
                        _buildStatsChip(
                          'Carbs',
                          '${stats['total_carbs']?.toStringAsFixed(1) ?? '0'}',
                          'g',
                          //Colors.green
                        ),
                        const SizedBox(width: 8),
                        _buildStatsChip(
                          'Fat',
                          '${stats['total_fat']?.toStringAsFixed(1) ?? '0'}',
                          'g',
                          //Colors.purple
                        ),
                      ],
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ],
          ),
        ),
        //const SizedBox(height: 16),
      ],
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

  void _showDeleteConfirmation(ApiFoodLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Food Log'),
        content:
            Text('Are you sure you want to delete this ${log.foodName} entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFoodLog(log);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getFoodColor(String foodName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[foodName.hashCode % colors.length];
  }

  IconData _getFoodIcon(String foodName) {
    final name = foodName.toLowerCase();

    // Apple / Fruit
    if (name.contains('apple') ||
        name.contains('fruit') ||
        name.contains('obst') ||
        name.contains('apfel') ||
        name.contains('banana') ||
        name.contains('banane') ||
        name.contains('orange') ||
        name.contains('beere') ||
        name.contains('berry') ||
        name.contains('pear') ||
        name.contains('birne')) return FontAwesomeIcons.appleWhole;

    // Bread / Grain
    if (name.contains('bread') ||
        name.contains('grain') ||
        name.contains('brot') ||
        name.contains('brötchen') ||
        name.contains('baguette') ||
        name.contains('toast') ||
        name.contains('weizen') ||
        name.contains('roggen') ||
        name.contains('bun') ||
        name.contains('roll')) return FontAwesomeIcons.breadSlice;

    // Chicken / Meat
    if (name.contains('chicken') ||
        name.contains('meat') ||
        name.contains('huhn') ||
        name.contains('hähnchen') ||
        name.contains('fleisch') ||
        name.contains('rind') ||
        name.contains('beef') ||
        name.contains('pork') ||
        name.contains('schwein') ||
        name.contains('lamm') ||
        name.contains('turkey') ||
        name.contains('haehnchen') ||
        name.contains('pute')) return FontAwesomeIcons.drumstickBite;

    // Fish
    if (name.contains('fish') ||
        name.contains('fisch') ||
        name.contains('lachs') ||
        name.contains('salmon') ||
        name.contains('thunfisch') ||
        name.contains('tuna') ||
        name.contains('forelle') ||
        name.contains('trout') ||
        name.contains('hering') ||
        name.contains('herring')) return FontAwesomeIcons.fish;

    // Cheese / Dairy
    if (name.contains('cheese') ||
        name.contains('dairy') ||
        name.contains('käse') ||
        name.contains('milch') ||
        name.contains('milk') ||
        name.contains('joghurt') ||
        name.contains('yogurt') ||
        name.contains('quark') ||
        name.contains('butter') ||
        name.contains('cream') ||
        name.contains('sahne')) return FontAwesomeIcons.cheese;

    // Egg
    if (name.contains('egg') ||
        name.contains('ei') ||
        name.contains('eier') ||
        name.contains('omelette') ||
        name.contains('omelet')) return FontAwesomeIcons.egg;

    // Rice / Pasta
    if (name.contains('rice') ||
        name.contains('pasta') ||
        name.contains('reis') ||
        name.contains('nudel') ||
        name.contains('spaghetti') ||
        name.contains('penne') ||
        name.contains('macaroni') ||
        name.contains('lasagne') ||
        name.contains('lasagna')) return FontAwesomeIcons.bowlRice;

    // Vegetable / Carrot
    if (name.contains('vegetable') ||
        name.contains('carrot') ||
        name.contains('gemüse') ||
        name.contains('karotte') ||
        name.contains('möhre') ||
        name.contains('salat') ||
        name.contains('lettuce') ||
        name.contains('tomato') ||
        name.contains('tomate') ||
        name.contains('cucumber') ||
        name.contains('gurke') ||
        name.contains('broccoli') ||
        name.contains('brokkoli') ||
        name.contains('spinach') ||
        name.contains('spinat') ||
        name.contains('paprika') ||
        name.contains('pepper')) return FontAwesomeIcons.carrot;

    // Pizza
    if (name.contains('pizza')) return FontAwesomeIcons.pizzaSlice;

    // Burger
    if (name.contains('burger') ||
        name.contains('hamburger') ||
        name.contains('cheeseburger')) return FontAwesomeIcons.burger;

    // drinks
    if (name.contains('ale') ||
        name.contains('lager') ||
        name.contains('bier') ||
        name.contains('beer') ||
        name.contains('cocktail')) return FontAwesomeIcons.beerMugEmpty;

    return FontAwesomeIcons.utensils;
  }

  Widget _buildManageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Neues Food aus vorhandenen erstellen
          Card(
            //surfaceTintColor: Color.fromARGB(217, 33, 149, 243),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Custom Food',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customFoodNameController,
                    decoration: const InputDecoration(
                      labelText: 'Food Name',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Homemade Chicken Salad',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customFoodCaloriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Calories per 100g',
                            border: OutlineInputBorder(),
                            suffixText: 'kcal',
                            hintText: '250',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: customFoodProteinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Protein per 100g',
                            border: OutlineInputBorder(),
                            suffixText: 'g',
                            hintText: '20',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customFoodCarbsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Carbs per 100g',
                            border: OutlineInputBorder(),
                            suffixText: 'g',
                            hintText: '15',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: customFoodFatController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Fat per 100g',
                            border: OutlineInputBorder(),
                            suffixText: 'g',
                            hintText: '10',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customFoodNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Additional information about this food',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('Button onPressed called'); // Debug print
                        _createCustomFood();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Food'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Create custom food card
          Card(
            //surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
            //shadowColor: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Food item from Ingredients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _foodComponents.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Autocomplete<ApiFood>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return foods;
                                }
                                return foods.where((ApiFood food) => food.name
                                    .toLowerCase()
                                    .contains(
                                        textEditingValue.text.toLowerCase()));
                              },
                              displayStringForOption: (ApiFood food) =>
                                  food.name,
                              initialValue: _foodComponents[index].food != null
                                  ? TextEditingValue(
                                      text: _foodComponents[index].food!.name)
                                  : const TextEditingValue(),
                              onSelected: (ApiFood selected) {
                                setState(() {
                                  _foodComponents[index].food = selected;
                                });
                              },
                              fieldViewBuilder: (context, controller, focusNode,
                                  onFieldSubmitted) {
                                // Keep the text in sync with the selected food
                                if (_foodComponents[index].food != null &&
                                    controller.text !=
                                        _foodComponents[index].food!.name) {
                                  controller.text =
                                      _foodComponents[index].food!.name;
                                }
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Type to search foods...',
                                  ),
                                );
                              },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxHeight: 200),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (context, optIndex) {
                                          final ApiFood food =
                                              options.elementAt(optIndex);
                                          return ListTile(
                                            title: Text(food.name),
                                            subtitle: Text(
                                                '${food.kcalPer100g.toInt()} kcal/100g'),
                                            onTap: () => onSelected(food),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              children: [
                                //SizedBox(height: 4),
                                TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    //labelText: 'grams',
                                    suffixText: 'grams',
                                    border: OutlineInputBorder(),
                                    //contentPadding: EdgeInsets.symmetric(
                                    //   vertical: 8, horizontal: 8),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _foodComponents[index].grams =
                                          double.tryParse(val) ?? 0;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _foodComponents.removeAt(index);
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _foodComponents.add(_FoodComponent());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Ingredient'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _foodComponents
                                .where((c) => c.food != null && c.grams > 0)
                                .length >=
                            2
                        ? () async {
                            // Berechnung
                            final totalGrams = _foodComponents.fold<double>(
                                0, (sum, c) => sum + c.grams);
                            if (totalGrams == 0) return;
                            double kcal = 0, protein = 0, carbs = 0, fat = 0;
                            for (final c in _foodComponents) {
                              if (c.food != null && c.grams > 0) {
                                final factor = c.grams / 100.0;
                                kcal += c.food!.kcalPer100g * factor;
                                protein += c.food!.proteinPer100g * factor;
                                carbs += c.food!.carbsPer100g * factor;
                                fat += c.food!.fatPer100g * factor;
                              }
                            }
                            // Runtergerechnet auf 100g
                            final kcal100 = kcal / totalGrams * 100;
                            final protein100 = protein / totalGrams * 100;
                            final carbs100 = carbs / totalGrams * 100;
                            final fat100 = fat / totalGrams * 100;

                            // Dialog für Name
                            String newName = '';
                            String newNote = '';

                            final result = await showDialog(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: const Text('Name the dish'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            autofocus: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Name',
                                            ),
                                            onChanged: (val) => newName = val,
                                          ),
                                          const SizedBox(height: 12),
                                          TextField(
                                            decoration: const InputDecoration(
                                              labelText: 'Note (optional)',
                                            ),
                                            maxLines: 2,
                                            onChanged: (val) => newNote = val,
                                          ),
                                          const SizedBox(height: 16),
                                          // Anzeige der berechneten Werte
                                          Card(
                                            color: Colors.grey[100],
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'Per 100g:',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'kcal: ${kcal100.toStringAsFixed(1)} kcal\n'
                                                    'protein: ${protein100.toStringAsFixed(1)} g\n'
                                                    'carbs: ${carbs100.toStringAsFixed(1)} g\n'
                                                    'fat: ${fat100.toStringAsFixed(1)} g',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                              context, {
                                            'name': newName,
                                            'note': newNote
                                          }),
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                            if (result == null ||
                                (result['name'] as String).trim().isEmpty)
                              return;
                            //final newName = result['name'] as String;
                            //final newNote = result['note'] as String;

                            // Food anlegen
                            await userService.createFood(
                              name: newName.trim(),
                              kcalPer100g: kcal100,
                              proteinPer100g: protein100,
                              carbsPer100g: carbs100,
                              fatPer100g: fat100,
                              notes: newNote.trim().isNotEmpty
                                  ? newNote.trim()
                                  : null,
                            );
                            await _loadData();
                            setState(() {
                              _foodComponents = [_FoodComponent()];
                            });
                            _showSuccessSnackBar('created food item!');
                          }
                        : null,
                    child: const Text('Name the dish and create'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Food list card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Foods',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search foods...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Type to filter foods',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _foodSearchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  if (filteredFoods.isEmpty && _foodSearchQuery.isNotEmpty)
                    const Center(
                      child: Text(
                        'No foods found matching your search',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else if (foods.isEmpty)
                    const Center(
                      child: Text(
                        'No foods loaded yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else if (!ResponsiveHelper.isMobile(context))
                    SizedBox(
                      height: 300, // Fixed height
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: filteredFoods.length,
                        itemBuilder: (context, index) {
                          final food = filteredFoods[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getFoodColor(food.name),
                                child: Icon(
                                  _getFoodIcon(food.name),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(food.name),
                              subtitle: Text(
                                  '${food.kcalPer100g.toInt()} kcal/100g\nP:${food.proteinPer100g.toStringAsFixed(1)}g C:${food.carbsPer100g.toStringAsFixed(1)}g F:${food.fatPer100g.toStringAsFixed(1)}g'),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _showDeleteFoodConfirmation(food),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: filteredFoods.length,
                        itemBuilder: (context, index) {
                          final food = filteredFoods[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getFoodColor(food.name),
                              child: Icon(
                                _getFoodIcon(food.name),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(food.name),
                            subtitle: Text(
                                '${food.kcalPer100g.toInt()} kcal/100g\nP:${food.proteinPer100g.toStringAsFixed(1)}g C:${food.carbsPer100g.toStringAsFixed(1)}g F:${food.fatPer100g.toStringAsFixed(1)}g'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _showDeleteFoodConfirmation(food),
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteFoodConfirmation(ApiFood food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Food'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${food.name}"?'),
            const SizedBox(height: 8),
            const Text(
              'This will also delete all associated food logs.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await userService.deleteFood(food.id!);
                await _loadData();
                _showSuccessSnackBar('Food deleted successfully');
              } catch (e) {
                print('Error deleting food: $e');
                _showErrorSnackBar('Failed to delete food: ${e.toString()}');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

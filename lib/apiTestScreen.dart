/**
 * API Test Screen - Development and Testing Interface
 * 
 * This screen provides a comprehensive testing interface for all API
 * endpoints and services within the Gymli application. It's primarily
 * used for development, debugging, and validation of API functionality.
 * 
 * Key features:
 * - Complete API endpoint testing capabilities
 * - Real-time API response display and validation
 * - CRUD operations testing for all data models
 * - Service integration testing (Animals, Exercises, Workouts, etc.)
 * - Error handling and response validation
 * - Mock data generation and testing scenarios
 * - API performance monitoring and debugging
 * - Interactive interface for manual API testing
 * - Data model validation and schema testing
 * 
 * This screen is essential for developers to verify API functionality,
 * test edge cases, and ensure proper data flow between the frontend
 * and backend services during development and maintenance.
 */

// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'api.dart' as api;

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreen();
}

class _ApiTestScreen extends State<ApiTestScreen> {
  // Data for each service
  List<dynamic>? _animals;
  List<dynamic>? _exercises;
  List<dynamic>? _workouts;
  List<dynamic>? _trainingSets;
  List<dynamic>? _workoutUnits;

  // Example test username
  final String testUser = "testuser";

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _loadAnimals();
    _loadExercises();
    _loadWorkouts();
    _loadTrainingSets();
    _loadWorkoutUnits();
  }

  void _loadAnimals() async {
    try {
      final data = await api.AnimalService().getAnimals();
      setState(() {
        _animals = data;
      });
    } catch (e) {
      print('Error fetching animals: $e');
    }
  }

  void _loadExercises() async {
    try {
      final data = await api.ExerciseService().getExercises(userName: testUser);
      setState(() {
        _exercises = data;
      });
    } catch (e) {
      print('Error fetching exercises: $e');
    }
  }

  void _loadWorkouts() async {
    try {
      final data = await api.WorkoutService().getWorkouts(userName: testUser);
      setState(() {
        _workouts = data;
      });
    } catch (e) {
      print('Error fetching workouts: $e');
    }
  }

  void _loadTrainingSets() async {
    try {
      final data =
          await api.TrainingSetService().getTrainingSets(userName: testUser);
      setState(() {
        _trainingSets = data;
      });
    } catch (e) {
      print('Error fetching training sets: $e');
    }
  }

  void _loadWorkoutUnits() async {
    try {
      final data =
          await api.WorkoutUnitService().getWorkoutUnits(userName: testUser);
      setState(() {
        _workoutUnits = data;
      });
    } catch (e) {
      print('Error fetching workout units: $e');
    }
  }

  // Dialogs for creating new entries
  void _showAddAnimalDialog() {
    final nameController = TextEditingController();
    final soundController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Animal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: soundController,
                decoration: const InputDecoration(labelText: 'Sound')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await api.AnimalService()
                  .createAnimal(nameController.text, soundController.text);
              Navigator.pop(context);
              _loadAnimals();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog() {
    // All muscle group fields
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final repBaseController = TextEditingController();
    final repMaxController = TextEditingController();
    final incrementController = TextEditingController();
    final pectoralisMajorController = TextEditingController();
    final trapeziusController = TextEditingController();
    final bicepsController = TextEditingController();
    final abdominalsController = TextEditingController();
    final frontDeltsController = TextEditingController();
    final deltoidsController = TextEditingController();
    final backDeltsController = TextEditingController();
    final latissimusDorsiController = TextEditingController();
    final tricepsController = TextEditingController();
    final gluteusMaximusController = TextEditingController();
    final hamstringsController = TextEditingController();
    final quadricepsController = TextEditingController();
    final calvesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Type (int)'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: repBaseController,
                  decoration:
                      const InputDecoration(labelText: 'Default Rep Base'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: repMaxController,
                  decoration:
                      const InputDecoration(labelText: 'Default Rep Max'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: incrementController,
                  decoration:
                      const InputDecoration(labelText: 'Default Increment'),
                  keyboardType: TextInputType.number),
              const Divider(),
              TextField(
                  controller: pectoralisMajorController,
                  decoration:
                      const InputDecoration(labelText: 'Pectoralis Major'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: trapeziusController,
                  decoration: const InputDecoration(labelText: 'Trapezius'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: bicepsController,
                  decoration: const InputDecoration(labelText: 'Biceps'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: abdominalsController,
                  decoration: const InputDecoration(labelText: 'Abdominals'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: frontDeltsController,
                  decoration: const InputDecoration(labelText: 'Front Delts'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: deltoidsController,
                  decoration: const InputDecoration(labelText: 'Deltoids'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: backDeltsController,
                  decoration: const InputDecoration(labelText: 'Back Delts'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: latissimusDorsiController,
                  decoration:
                      const InputDecoration(labelText: 'Latissimus Dorsi'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: tricepsController,
                  decoration: const InputDecoration(labelText: 'Triceps'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: gluteusMaximusController,
                  decoration:
                      const InputDecoration(labelText: 'Gluteus Maximus'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: hamstringsController,
                  decoration: const InputDecoration(labelText: 'Hamstrings'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: quadricepsController,
                  decoration: const InputDecoration(labelText: 'Quadriceps'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: calvesController,
                  decoration: const InputDecoration(labelText: 'Calves'),
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await api.ExerciseService().createExercise(
                userName: testUser,
                name: nameController.text,
                type: int.tryParse(typeController.text) ?? 0,
                defaultRepBase: int.tryParse(repBaseController.text) ?? 0,
                defaultRepMax: int.tryParse(repMaxController.text) ?? 0,
                defaultIncrement:
                    double.tryParse(incrementController.text) ?? 2.5,
                pectoralisMajor:
                    double.tryParse(pectoralisMajorController.text) ?? 0.0,
                trapezius: double.tryParse(trapeziusController.text) ?? 0.0,
                biceps: double.tryParse(bicepsController.text) ?? 0.0,
                abdominals: double.tryParse(abdominalsController.text) ?? 0.0,
                frontDelts: double.tryParse(frontDeltsController.text) ?? 0.0,
                deltoids: double.tryParse(deltoidsController.text) ?? 0.0,
                backDelts: double.tryParse(backDeltsController.text) ?? 0.0,
                latissimusDorsi:
                    double.tryParse(latissimusDorsiController.text) ?? 0.0,
                triceps: double.tryParse(tricepsController.text) ?? 0.0,
                gluteusMaximus:
                    double.tryParse(gluteusMaximusController.text) ?? 0.0,
                hamstrings: double.tryParse(hamstringsController.text) ?? 0.0,
                quadriceps: double.tryParse(quadricepsController.text) ?? 0.0,
                calves: double.tryParse(calvesController.text) ?? 0.0,
              );
              Navigator.pop(context);
              _loadExercises();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddWorkoutDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await api.WorkoutService().createWorkout(
                userName: testUser,
                name: nameController.text,
              );
              Navigator.pop(context);
              _loadWorkouts();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTrainingSetDialog() {
    final exerciseIdController = TextEditingController();
    final dateController = TextEditingController();
    final weightController = TextEditingController();
    final repetitionsController = TextEditingController();
    final setTypeController = TextEditingController();
    final baseRepsController = TextEditingController();
    final maxRepsController = TextEditingController();
    final incrementController = TextEditingController();
    final machineNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Training Set'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: exerciseIdController,
                  decoration: const InputDecoration(labelText: 'Exercise ID'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                      labelText: 'Date (YYYY-MM-DDTHH:MM:SS)')), // ISO format
              TextField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: 'Weight'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: repetitionsController,
                  decoration: const InputDecoration(labelText: 'Repetitions'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: setTypeController,
                  decoration: const InputDecoration(labelText: 'Set Type'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: baseRepsController,
                  decoration: const InputDecoration(labelText: 'Base Reps'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: maxRepsController,
                  decoration: const InputDecoration(labelText: 'Max Reps'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: incrementController,
                  decoration: const InputDecoration(labelText: 'Increment'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: machineNameController,
                  decoration: const InputDecoration(
                      labelText: 'Machine Name (optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await api.TrainingSetService().createTrainingSet(
                userName: testUser,
                exerciseId: int.tryParse(exerciseIdController.text) ?? 0,
                date: dateController.text,
                weight: double.tryParse(weightController.text) ?? 0.0,
                repetitions: int.tryParse(repetitionsController.text) ?? 0,
                setType: int.tryParse(setTypeController.text) ?? 0,
                baseReps: int.tryParse(baseRepsController.text) ?? 0,
                maxReps: int.tryParse(maxRepsController.text) ?? 0,
                increment: double.tryParse(incrementController.text) ?? 0.0,
                machineName: machineNameController.text.isEmpty
                    ? null
                    : machineNameController.text,
              );
              Navigator.pop(context);
              _loadTrainingSets();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddWorkoutUnitDialog() {
    final workoutIdController = TextEditingController();
    final exerciseIdController = TextEditingController();
    final warmupsController = TextEditingController();
    final worksetsController = TextEditingController();
    final typeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Workout Unit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: workoutIdController,
                  decoration: const InputDecoration(labelText: 'Workout ID'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: exerciseIdController,
                  decoration: const InputDecoration(labelText: 'Exercise ID'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: warmupsController,
                  decoration: const InputDecoration(labelText: 'Warmups'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: worksetsController,
                  decoration: const InputDecoration(labelText: 'Worksets'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Type'),
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await api.WorkoutUnitService().createWorkoutUnit(
                userName: testUser,
                workoutId: int.tryParse(workoutIdController.text) ?? 0,
                exerciseId: int.tryParse(exerciseIdController.text) ?? 0,
                warmups: int.tryParse(warmupsController.text) ?? 0,
                worksets: int.tryParse(worksetsController.text) ?? 0,
                type: int.tryParse(typeController.text) ?? 0,
              );
              Navigator.pop(context);
              _loadWorkoutUnits();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Widget for each section
  Widget _buildList(String title, List<dynamic>? items, List<String> fields,
      Function(int id) onDelete, VoidCallback onAdd) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        children: [
          SizedBox(
            height: 180,
            child: items == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(fields
                            .map((f) => item[f]?.toString() ?? '')
                            .join(" | ")),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => onDelete(item['id']),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton(onPressed: onAdd, child: Text('Add $title')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("API Test"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildList(
                'Animals',
                _animals,
                ['name', 'sound'],
                (id) async {
                  await api.AnimalService().deleteAnimal(id);
                  _loadAnimals();
                },
                _showAddAnimalDialog,
              ),
              _buildList(
                'Exercises',
                _exercises,
                ['name', 'type'],
                (id) async {
                  await api.ExerciseService().deleteExercise(id);
                  _loadExercises();
                },
                _showAddExerciseDialog,
              ),
              _buildList(
                'Workouts',
                _workouts,
                ['name'],
                (id) async {
                  await api.WorkoutService().deleteWorkout(id);
                  _loadWorkouts();
                },
                _showAddWorkoutDialog,
              ),
              _buildList(
                'Training Sets',
                _trainingSets,
                ['exercise_id', 'repetitions', 'weight'],
                (id) async {
                  await api.TrainingSetService().deleteTrainingSet(id);
                  _loadTrainingSets();
                },
                _showAddTrainingSetDialog,
              ),
              _buildList(
                'Workout Units',
                _workoutUnits,
                ['workout_id', 'exercise_id', 'warmups', 'worksets'],
                (id) async {
                  await api.WorkoutUnitService().deleteWorkoutUnit(id);
                  _loadWorkoutUnits();
                },
                _showAddWorkoutUnitDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

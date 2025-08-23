import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Gymli/utils/workout_data_cache.dart';
import 'package:Gymli/screens/landing/controllers/landing_controller.dart';

final workoutDataCacheProvider = ChangeNotifierProvider<WorkoutDataCache>((ref) {
  final cache = WorkoutDataCache();
  ref.onDispose(cache.dispose);
  return cache;
});

final landingControllerProvider = ChangeNotifierProvider<LandingController>((ref) {
  final cache = ref.watch(workoutDataCacheProvider);
  final controller = LandingController(cache: cache);
  controller.initialize(); // fire and forget
  ref.onDispose(controller.dispose);
  return controller;
});
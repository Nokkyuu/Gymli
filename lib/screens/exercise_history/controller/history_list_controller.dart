import 'package:flutter/material.dart';
import '../../../utils/models/data_models.dart';
import '../../../utils/services/service_export.dart';
import '../../exercise_history_screen.dart';
import 'package:get_it/get_it.dart';
import '../../../utils/workout_data_cache.dart';

class HistoryListController {
  final String exercise;
  final int exerciseId;

  WorkoutDataCache get _cache => GetIt.I<WorkoutDataCache>();


  final ValueNotifier<List<ListEntry>> entries = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  HistoryListController({
    required this.exercise,
    required this.exerciseId,
  });

  Future<void> loadTrainingSets() async {
    isLoading.value = true;
    try {
      // final cache = GetIt.I<WorkoutDataCache>();
      // Cache-first
      final trainingSets = _cache.getCachedTrainingSetsSync(exerciseId);
      // List<TrainingSet> trainingSets;
      // if (fromCache != null && fromCache.isNotEmpty) {
      //   trainingSets = List<TrainingSet>.from(fromCache);
      // } else {
      //   // Fetch from server and seed cache
      //   final data = await GetIt.I<TrainingSetService>()
      //       .getTrainingSetsByExerciseID(exerciseId: exerciseId);
      //   trainingSets = data
      //       .whereType<Map<String, dynamic>>()
      //       .map(TrainingSet.fromJson)
      //       .toList();
      //   cache.setExerciseTrainingSets(exerciseId, trainingSets);
      // }
      // Sort desc by date
      trainingSets.sort((a, b) => b.date.compareTo(a.date));
      // Build grouped entries by date (YYYY-MM-DD)
      final List<ListEntry> newEntries = [];
      String? lastDate;
      for (final set in trainingSets) {
        final dateStr = set.date.toIso8601String().split('T').first;
        if (lastDate != dateStr) {
          newEntries.add(ListEntry.header(dateStr));
          lastDate = dateStr;
        }
        newEntries.add(ListEntry.set(set));
      }
      entries.value = newEntries;
    } catch (e) {
      debugPrint('Error loading training sets: $e');
      entries.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> delete(TrainingSet item) async {
    if (item.id == null) return;
    try {
      // Optimistic delete in cache (+ enqueues server delete if id >= 0)
      final cache = GetIt.I<WorkoutDataCache>();
      cache.deleteTrainingSetOptimistic(
          exerciseId: exerciseId, setId: item.id!);

      // Remove from entries and update headers if needed
      final currentEntries = List<ListEntry>.from(entries.value);
      final setIndex = currentEntries.indexWhere((e) => e.set?.id == item.id);
      if (setIndex == -1) return;

      // Determine if header before this set becomes orphaned
      bool removeHeader = false;
      int headerIndex = -1;
      if (setIndex > 0 && currentEntries[setIndex - 1].isHeader) {
        final bool isLastSetForHeader =
            (setIndex + 1 >= currentEntries.length) ||
                currentEntries[setIndex + 1].isHeader;
        if (isLastSetForHeader) {
          removeHeader = true;
          headerIndex = setIndex - 1;
        }
      }

      currentEntries.removeAt(setIndex);
      if (removeHeader &&
          headerIndex >= 0 &&
          headerIndex < currentEntries.length) {
        currentEntries.removeAt(headerIndex);
      }
      entries.value = currentEntries;
    } catch (e) {
      debugPrint('Error deleting training set: $e');
    }
  }
}

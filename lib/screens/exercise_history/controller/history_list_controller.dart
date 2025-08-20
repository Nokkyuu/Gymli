import 'package:flutter/material.dart';
import 'package:Gymli/utils/services/temp_service.dart';
import '../../../utils/api/api_models.dart';
import '../../exercise/repositories/exercise_repository.dart';
import '../../exercise_history_screen.dart';

class HistoryListController {
  final String exercise;
  final int exerciseId;
  final ExerciseRepository? exerciseRepository;
  final TempService container = TempService();

  final ValueNotifier<List<ListEntry>> entries = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  HistoryListController({
    required this.exercise,
    required this.exerciseId,
    this.exerciseRepository,
  });

  Future<void> loadTrainingSets() async {
    isLoading.value = true;
    try {
      final data = await container.trainingSetService
          .getTrainingSetsByExerciseID(exerciseId: exerciseId);
      final trainingSets =
          data.map((item) => ApiTrainingSet.fromJson(item)).toList();
      final filtered =
          trainingSets.where((item) => item.exerciseId == exerciseId).toList();
      filtered.sort((a, b) => b.date.compareTo(a.date));

      List<ListEntry> newEntries = [];
      String? lastDate;
      for (final set in filtered) {
        final dateStr = set.date.toString().split(" ")[0];
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

  Future<void> delete(ApiTrainingSet item) async {
    if (item.id == null) return;
    try {
      await container.trainingSetService.deleteTrainingSet(item.id!);

      try {
        if (exerciseRepository != null) {
          await exerciseRepository!.refreshCache();
        } else {
          final exerciseRepo = ExerciseRepository();
          await exerciseRepo.refreshCache();
        }
      } catch (e) {
        debugPrint('Warning: Could not refresh exercise repository cache: $e');
      }

      // Remove from entries and update headers if needed
      final currentEntries = List<ListEntry>.from(entries.value);
      int setIndex = currentEntries.indexWhere((e) => e.set?.id == item.id);
      if (setIndex == -1) return;

      bool removeHeader = false;
      int headerIndex = -1;
      if (setIndex > 0 && currentEntries[setIndex - 1].isHeader) {
        bool isLastSetForHeader = (setIndex + 1 >= currentEntries.length) ||
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

# Training Set Score Calculation Migration Guide

This document explains the changes made to eliminate redundant storage of base reps, max reps, and increment values in training sets.

## What Changed

### Before
- Each `ApiTrainingSet` stored `baseReps`, `maxReps`, and `increment` fields
- These values were duplicated from the associated `ApiExercise`
- Retroactive changes to exercise parameters didn't affect historical calculations

### After
- `ApiTrainingSet` no longer stores redundant exercise parameters
- Score calculation always uses current exercise parameters
- Historical calculations automatically update when exercise parameters change

## New Score Calculation System

### 1. Main Score Calculation Function
```dart
// Simple, direct calculation using exercise parameters
double calculateScoreWithExercise(ApiTrainingSet trainingSet, ApiExercise exercise)

// Usage:
double score = calculateScoreWithExercise(trainingSet, exercise);
```

### 2. ScoreCalculationService (Recommended)
```dart
// Create service instance
final scoreService = ScoreCalculationService();

// Cache exercises for efficient lookup
scoreService.cacheExercises(allExercises);

// Calculate score using cached exercise data
double score = scoreService.calculateScoreForSet(trainingSet);

// Batch calculation
List<double> scores = scoreService.calculateScoresForSets(trainingSets);
```

## Migration Steps

### Required Changes

1. **Remove redundant fields from database**:
   - Drop `base_reps`, `max_reps`, `increment` columns from training sets table

2. **Update API endpoints**:
   - Remove these fields from training set creation/update requests
   - Remove them from response payloads

3. **Update existing code**:
   - Replace all `calculateScore(trainingSet)` calls
   - Use `ScoreCalculationService` or `calculateScoreWithExercise`

## Updated Usage Patterns

### For Controllers and Services
```dart
class ExerciseController {
  final ScoreCalculationService _scoreService = ScoreCalculationService();
  
  void initialize(List<ApiExercise> exercises) {
    _scoreService.cacheExercises(exercises);
  }
  
  double calculateScore(ApiTrainingSet trainingSet) {
    return _scoreService.calculateScoreForSet(trainingSet);
  }
}
```

### For Statistics and Analysis
```dart
// All historical analysis now uses current exercise parameters
final scoreService = ScoreCalculationService();
scoreService.cacheExercises(exercises);

for (var trainingSet in historicalSets) {
  double score = scoreService.calculateScoreForSet(trainingSet);
  // Uses current exercise parameters for consistency
}
```

### For Direct Calculations
```dart
// When you have both trainingSet and exercise available
double score = calculateScoreWithExercise(trainingSet, exercise);
```

## Breaking Changes

⚠️ **These changes will break existing code that relied on the old fields:**

1. `trainingSet.baseReps` - **REMOVED**
2. `trainingSet.maxReps` - **REMOVED** 
3. `trainingSet.increment` - **REMOVED**
4. `calculateScore(trainingSet)` - **REMOVED**

## Updated ApiTrainingSet Structure

```dart
class ApiTrainingSet {
  final int? id;
  final String userName;
  final int exerciseId;          // Links to exercise for parameter lookup
  final String exerciseName;
  final DateTime date;
  final double weight;
  final int repetitions;
  final int setType;
  final String? machineName;
  
  // baseReps, maxReps, increment - REMOVED
}
```

## Benefits

1. **Eliminates Data Redundancy**: Values stored only in exercise definitions
2. **Enables Retroactive Updates**: Changing exercise parameters affects all calculations
3. **Improves Data Consistency**: Single source of truth for exercise parameters
4. **Reduces Database Storage**: Smaller training sets table
5. **Simplifies API**: Fewer fields to manage

## Error Handling

Always ensure exercises are cached before calculating scores:

```dart
try {
  final scoreService = ScoreCalculationService();
  scoreService.cacheExercises(exercises);
  double score = scoreService.calculateScoreForSet(trainingSet);
} catch (e) {
  print('Exercise not found for training set: $e');
  // Handle gracefully - maybe show an error or skip calculation
}
```

## Testing Strategy

1. **Unit Tests**: Test score calculations with known exercise parameters
2. **Integration Tests**: Verify that all score calculations work with the service
3. **Migration Tests**: Compare old vs new calculations during transition

```dart
// Test that score calculation works correctly
final exercise = ApiExercise(/* ... */);
final trainingSet = ApiTrainingSet(/* ... */);
final expectedScore = 42.5; // Calculate manually

final actualScore = calculateScoreWithExercise(trainingSet, exercise);
expect(actualScore, equals(expectedScore));
```

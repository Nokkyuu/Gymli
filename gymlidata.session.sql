-- Check if exercise 453 is referenced in training_sets
SELECT COUNT(*) as training_sets_count FROM training_sets WHERE exercise_id = 453;

-- Check if exercise 453 is referenced in workout_units  
SELECT COUNT(*) as workout_units_count FROM workout_units WHERE exercise_id = 453;

-- Get specific records that might be blocking deletion
SELECT 'training_sets' as table_name, id, exercise_id
FROM training_sets 
WHERE exercise_id = 453
UNION ALL
SELECT 'workout_units' as table_name, id, exercise_id
FROM workout_units 
WHERE exercise_id = 453;

-- Check the exercise details
SELECT id, name FROM exercises WHERE id = 453;
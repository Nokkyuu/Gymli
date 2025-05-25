-- Check current database structure and existing data
-- 1. First, let's see what tables exist
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- 2. Let's check the structure of the main tables
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'exercises' 
ORDER BY ordinal_position;

SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'workouts' 
ORDER BY ordinal_position;

SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'workout_units' 
ORDER BY ordinal_position;

SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'training_sets' 
ORDER BY ordinal_position;

-- 3. Check existing data for DefaultUser
SELECT * FROM exercises WHERE user_name = 'DefaultUser';
SELECT * FROM workouts WHERE user_name = 'DefaultUser';
SELECT * FROM workout_units WHERE user_name = 'DefaultUser';
SELECT * FROM training_sets WHERE user_name = 'DefaultUser';

-- 3.5. Add forearms column if it doesn't exist (for updated backend API)
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS forearms DOUBLE PRECISION DEFAULT 0.0;

-- 4. Add 4 exercises for DefaultUser
-- Benchpress (Primary: Pectoralis major, Secondary: Front delts, Triceps)
INSERT INTO exercises (
    user_name, name, type, default_rep_base, default_rep_max, default_increment,
    pectoralis_major, trapezius, biceps, abdominals, front_delts, deltoids, 
    back_delts, latissimus_dorsi, triceps, gluteus_maximus, hamstrings, 
    quadriceps, forearms, calves
) VALUES (
    'DefaultUser', 'Benchpress', 0, 6, 10, 2.5,
    1.0, 0.0, 0.0, 0.1, 0.7, 0.0, 0.0, 0.0, 0.6, 0.0, 0.0, 0.0, 0.2, 0.0
);

-- Deadlift (Primary: Hamstrings, Gluteus maximus, Secondary: Trapezius, Latissimus dorsi)
INSERT INTO exercises (
    user_name, name, type, default_rep_base, default_rep_max, default_increment,
    pectoralis_major, trapezius, biceps, abdominals, front_delts, deltoids, 
    back_delts, latissimus_dorsi, triceps, gluteus_maximus, hamstrings, 
    quadriceps, forearms, calves
) VALUES (
    'DefaultUser', 'Deadlift', 0, 3, 8, 5.0,
    0.0, 0.8, 0.0, 0.3, 0.0, 0.0, 0.0, 0.6, 0.0, 1.0, 1.0, 0.4, 0.5, 0.0
);

-- Pullups (Primary: Latissimus dorsi, Secondary: Biceps, Back delts)
INSERT INTO exercises (
    user_name, name, type, default_rep_base, default_rep_max, default_increment,
    pectoralis_major, trapezius, biceps, abdominals, front_delts, deltoids, 
    back_delts, latissimus_dorsi, triceps, gluteus_maximus, hamstrings, 
    quadriceps, forearms, calves
) VALUES (
    'DefaultUser', 'Pullups', 0, 5, 12, 2.5,
    0.0, 0.3, 0.8, 0.2, 0.0, 0.0, 0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.6, 0.0
);

-- Squats (Primary: Quadriceps, Gluteus maximus, Secondary: Hamstrings, Abdominals)
INSERT INTO exercises (
    user_name, name, type, default_rep_base, default_rep_max, default_increment,
    pectoralis_major, trapezius, biceps, abdominals, front_delts, deltoids, 
    back_delts, latissimus_dorsi, triceps, gluteus_maximus, hamstrings, 
    quadriceps, forearms, calves
) VALUES (
    'DefaultUser', 'Squats', 0, 6, 12, 5.0,
    0.0, 0.0, 0.0, 0.3, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.6, 1.0, 0.0, 0.2
);

-- 5. Create "Full Body" workout
INSERT INTO workouts (user_name, name) VALUES ('DefaultUser', 'Full Body');

-- 6. Add workout units (1 warmup + 3 work sets for each exercise)
-- Get the workout ID and exercise IDs first, then add workout units
-- Note: Replace @workout_id and @exercise_id variables with actual IDs after running the inserts

-- For Benchpress
INSERT INTO workout_units (user_name, workout_id, exercise_id, warmups, worksets, type)
SELECT 'DefaultUser', w.id, e.id, 1, 3, 0
FROM workouts w, exercises e 
WHERE w.user_name = 'DefaultUser' AND w.name = 'Full Body'
AND e.user_name = 'DefaultUser' AND e.name = 'Benchpress';

-- For Deadlift  
INSERT INTO workout_units (user_name, workout_id, exercise_id, warmups, worksets, type)
SELECT 'DefaultUser', w.id, e.id, 1, 3, 0
FROM workouts w, exercises e 
WHERE w.user_name = 'DefaultUser' AND w.name = 'Full Body'
AND e.user_name = 'DefaultUser' AND e.name = 'Deadlift';

-- For Pullups
INSERT INTO workout_units (user_name, workout_id, exercise_id, warmups, worksets, type)
SELECT 'DefaultUser', w.id, e.id, 1, 3, 0
FROM workouts w, exercises e 
WHERE w.user_name = 'DefaultUser' AND w.name = 'Full Body'
AND e.user_name = 'DefaultUser' AND e.name = 'Pullups';

-- For Squats
INSERT INTO workout_units (user_name, workout_id, exercise_id, warmups, worksets, type)
SELECT 'DefaultUser', w.id, e.id, 1, 3, 0
FROM workouts w, exercises e 
WHERE w.user_name = 'DefaultUser' AND w.name = 'Full Body'
AND e.user_name = 'DefaultUser' AND e.name = 'Squats';

-- 7. Verify the data was inserted correctly
SELECT * FROM exercises WHERE user_name = 'DefaultUser';
SELECT * FROM workouts WHERE user_name = 'DefaultUser';
SELECT wu.*, e.name as exercise_name, w.name as workout_name 
FROM workout_units wu
JOIN exercises e ON wu.exercise_id = e.id
JOIN workouts w ON wu.workout_id = w.id
WHERE wu.user_name = 'DefaultUser';

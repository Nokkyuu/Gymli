import util
import sqlite3
from datetime import datetime, timezone

class Database():
  db_file = "database.sqlite"
  def __init__(self):
      self.connection = sqlite3.connect(self.db_file)

  def add_exercise(self, exercise_name):
    quit("GUOHOE")
    self.execute(f'INSERT INTO "Exercises" (Name) VALUES ("{exercise_name}")')
    self.connection.commit()
    return self.get("SELECT MAX(id) from 'Exercises'")

  def get_exercises(self):
    return [x[0] for x in self.get(f"SELECT Name from 'Exercises'")]

  def get_training_types(self):
    return [x[0] for x in self.get(f"SELECT Name from 'SetTypeNames'")]

  def get_exercise_id(self, exercise):
    exercise_id = self.get(f"SELECT id from 'Exercises' WHERE name == '{exercise}'")
    if len(exercise_id) == 0: exercise_id = self.add_exercise(exercise)
    return exercise_id[0][0]
    

  def add_workout(self, exercise, weight, repetitions, setType = 1, datestring = str(datetime.now(timezone.utc)), repbase=10, repmax=15, increment=5):
    exercise_id = self.get_exercise_id(exercise)
    self.execute(f'INSERT INTO "Sets" (Exercise, Date, Weight, Repetitions, SetType, BaseRepetitions, MaxRepetitions, Increment) VALUES ({exercise_id}, "{datestring}", {weight}, {repetitions}, {setType}, {repbase}, {repmax}, {increment})')
    self.connection.commit()

  def get_training_weeks(self, exercise):
    exercise_id = self.get_exercise_id(exercise)
    weeks = [int(i[0]) for i in self.get(f"SELECT strftime('%W', date) from 'Sets' WHERE Exercise == {exercise_id} ORDER BY date")]
    return weeks


  def get_training_days(self, exercise, formatted=False):
    exercise_id = self.get_exercise_id(exercise)
    days = [x[0].split(" ")[0] for x in self.get(f"SELECT date from 'Sets' WHERE Exercise == {exercise_id} ORDER BY date")]
    days = list(dict.fromkeys(days))
    return [datetime.strptime(s, "%Y-%m-%d") for s in days] if formatted else days
  
  def get_trainings(self, exercise, day, meta=True):
    exercise_id = self.get_exercise_id(exercise)
    format = "id, Date, Weight, Repetitions, SetType" if meta else "Weight, Repetitions"
    condition = "" if meta else " AND SetType == 1"
    statement = f"SELECT {format} FROM 'Sets' where Exercise == {exercise_id} AND date(date) == '{day}' {condition}"
    return self.get(statement)
  
  def get_training_meta(self, exercise, day):
    exercise_id = self.get_exercise_id(exercise)
    statement = f"SELECT BaseRepetitions, MaxRepetitions, Increment FROM 'Sets' where Exercise == {exercise_id} AND date(date) == '{day}' and SetType == 1"
    return self.get(statement)
  
  def get_training_meta_zero(self, exercise):
    exercise_id = self.get_exercise_id(exercise)
    statement = f"SELECT DefaultRepBase, DefaultRepMax, DefaultIncrement FROM 'Exercises' where ID == {exercise_id}"
    return self.get(statement)
  
  
  def delete_training(self, exercise_id):
    self.execute(f"DELETE FROM 'Sets' where id == {exercise_id}")
    self.connection.commit()

  def execute(self, query):
    cmd = self.connection.cursor()
    cmd.execute(query)
    return cmd 
  
  def get(self, query):
    return self.execute(query).fetchall()


# Exercises   1 Deadlifts, 2 Squats, 3 Benchpress
def add_test_workouts(database):
  test_workouts = [["Deadlifts", '2024-04-24 09:30:00+00:00', 50, 10],["Deadlifts", '2024-04-24 09:33:00+00:00', 50, 10],["Deadlifts", '2024-04-24 09:36:00+00:00', 50, 10],["Deadlifts", '2024-04-22 09:30:00+00:00', 45, 13],["Deadlifts", '2024-04-22 09:33:00+00:00', 45, 13],["Deadlifts", '2024-04-22 09:36:00+00:00', 45, 12],["Deadlifts", '2024-04-20 09:30:00+00:00', 45, 12],["Deadlifts", '2024-04-20 09:33:00+00:00', 45, 12],["Deadlifts", '2024-04-20 09:36:00+00:00', 45, 12],["Squats", '2024-04-24 09:30:00+00:00', 45, 13],["Squats", '2024-04-24 09:33:00+00:00', 45, 13],["Squats", '2024-04-24 09:36:00+00:00', 45, 13],["Squats", '2024-04-22 09:30:00+00:00', 45, 12],["Squats", '2024-04-22 09:33:00+00:00', 45, 12],["Squats", '2024-04-22 09:36:00+00:00', 45, 12],["Squats", '2024-04-20 09:30:00+00:00', 40, 14],["Squats", '2024-04-20 09:33:00+00:00', 40, 14],["Squats", '2024-04-20 09:36:00+00:00', 40, 14],["Benchpress", '2024-04-24 09:30:00+00:00', 40, 11], ["Benchpress", '2024-04-24 09:33:00+00:00', 40, 11], ["Benchpress", '2024-04-24 09:36:00+00:00', 40, 10], ["Benchpress", '2024-04-22 09:30:00+00:00', 35, 12], ["Benchpress", '2024-04-22 09:33:00+00:00', 35, 12], ["Benchpress", '2024-04-22 09:36:00+00:00', 35, 12], ["Benchpress", '2024-04-20 09:30:00+00:00', 35, 11], ["Benchpress", '2024-04-20 09:33:00+00:00', 35, 11], ["Benchpress", '2024-04-20 09:36:00+00:00', 35, 11]]
  # for exerc, date, weight, reps in test_workouts:
  #   database.add_workout(exerc, weight, reps, False, date)

if __name__ == "__main__":
  util.to_local_dir(__file__)
  db = Database()
  exercise = "Benchpress"
  # database.get_training_weeks("Benchpress")
  # database.get_exercises()
  stmt = f"SELECT Type, MuscleGroups, DefaultRepBase, DefaultRepMax, DefaultIncrement from 'Exercises' WHERE Name = 'Benchpress'"
  data = db.get(stmt)
  print(data)

  quit()

  workouts = [["Benchpress", '2024-05-01 09:30:00+00:00', 30, 10, 0],
              ["Benchpress", '2024-05-01 09:34:00+00:00', 60, 13, 1],
              ["Benchpress", '2024-05-01 09:37:00+00:00', 60, 12, 1],
              ["Benchpress", '2024-05-01 09:41:00+00:00', 55, 12, 1],
              ["Benchpress", '2024-05-01 09:41:00+00:00', 55, 10, 2],
              ]
  # for exerc, date, weight, reps, type in workouts:
  #   database.add_workout(exerc, weight, reps, type, date)


  # database.add_workout("Squat", 100.0, 20, 0, "2024-05-09 20:40:00")
  quit()
  dat = database.get("SELECT Name FROM 'Exercises'")
  dat = database.get("SELECT * FROM 'Workouts' where Exercise == 1 AND date(date) == '2024-04-24'")
  dat = database.get_training_days("Squats")
  dat = database.get_trainings("Squats", "2024-04-20")
import os, database, datetime
import numpy as np

def to_local_dir(filehandle):  # needs __file__ from caller
    """ change to local workspace for runtime stuff """
    os.chdir(os.path.dirname(os.path.realpath(filehandle)))


class Logic():
    _instance = None
    exercise = None
    setTypes = None

    # singleton
    def __init__(self):
        raise RuntimeError('Call instance() instead')
    @classmethod
    def instance(cls):
        to_local_dir(__file__)
        if cls._instance is None:
            print('Creating new instance')
            cls._instance = cls.__new__(cls)
            cls._instance.db = database.Database()
            cls._instance.setTypes = cls._instance.db.get_training_types()
        return cls._instance
    

    def calculate_score(self, sets, meta):
        index = np.argmax(sets[:, 0])
        repbase, repmax, increment = meta[index]
        return sets[index][0] + ((sets[index][1] - repbase) / (repmax-repbase)) * increment
   
    def calculate_week_score(self):
        days = self.db.get_training_days(self.exercise)
        all_sets = [self.db.get_trainings(self.exercise, day, meta=False) for day in days]
        all_metas = [self.db.get_training_meta(self.exercise, day) for day in days]
        days = self.db.get_training_days(self.exercise, formatted=True)
        week_sets = [[] for i in range(52)]
        week_metas = [[] for i in range(52)]
        calendarweeks = [x.isocalendar()[1] for x in days] # get available kws from dates
        for week, sets, metas in zip(calendarweeks, all_sets, all_metas):
            if len(sets) > 0:
                week_sets[week].append(sets[0])
                week_metas[week].append(metas[0])
        xs, ys = [], []
        for week in calendarweeks:
            sets = week_sets[week]
            metas = week_metas[week]
            if len(sets) > 0:
                score = self.calculate_score(np.array(sets), np.array(metas))
                xs.append(week); ys.append(score)
        xy = np.array([xs, ys]).T
        _, indices = np.unique(xy[:, 0], return_index=True)
        return xy[indices, :].T

    def get_weights(self):
        days = self.db.get_training_days(self.exercise)
        sets = [self.db.get_trainings(self.exercise, day, meta=False) for day in days]
        xs, ys = [], []
        for index, (day, day_sets) in enumerate(zip(days, sets)):
            if len(day_sets) > 0:
                xs.append(datetime.datetime.strptime(day, "%Y-%m-%d"))
                day_sets = np.array(day_sets)
                ys.append(np.max(day_sets[:, 0]))
        return xs, ys

    def get_rep_diff(self):
        days = self.db.get_training_days(self.exercise)
        sets = [self.db.get_trainings(self.exercise, day, meta=False) for day in days]
        metas = [self.db.get_training_meta(self.exercise, day) for day in days]
        print(metas)
        xs, ys = [], []
        for index, (day, day_sets, meta) in enumerate(zip(days, sets, metas)):
            if len(day_sets) > 0:
                day_sets = np.array(day_sets)
                which = np.argmax(day_sets[:, 1])
                best_set = day_sets[:, 1][which]
                meta = meta[which]
                xs.append(datetime.datetime.strptime(day, "%Y-%m-%d"))
                repbase, repmax, increment = meta
                print(repbase, repmax, increment, best_set)
                diff = ((best_set - repbase) / (repmax-repbase)) * increment
                ys.append(diff)
        return xs, ys

    def add_workout(self, exercise, weight, repetitions, setType, datestring, repbase=10, repmax=15, increment=5):
        self.db.add_workout(exercise, weight, repetitions, setType, datestring, repbase, repmax, increment)


if __name__ == "__main__":
    to_local_dir(__file__)
    db = database.Database()
    days = db.get_training_days("Benchpress")

    logic = Logic("Benchpress")
    logic.calculate_week_data()
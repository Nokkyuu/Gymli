from kivymd.app import MDApp as App
from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.lang import Builder
from kivy.uix.button import Button
from kivymd.uix.label import MDLabel
from kivymd.uix.button import MDFillRoundFlatButton as mdButton
from kivymd.uix.button import MDRaisedButton as mdButton2
from kivymd.uix.button import MDIconButton
from kivymd.uix.button import MDFloatingActionButton as FAB
from kivymd.uix.card import MDCard
from kivymd.uix.gridlayout import MDGridLayout as GridLayout
from kivymd.uix.boxlayout import MDBoxLayout as BoxLayout
from kivymd.uix.scrollview import MDScrollView as ScrollView
from kivy.core.window import Window
from kivy.properties import ObjectProperty
from kivy.clock import Clock    
from kivy.uix.widget import Widget 
from kivy.uix.boxlayout import BoxLayout
from datetime import datetime as DT
from datetime import date as DA
from datetime import timedelta as timedelta
from kivymd.uix.menu import MDDropdownMenu
from kivy.metrics import dp
import util, database, datetime
from kivymd.uix.list import OneLineIconListItem
from kivy.properties import StringProperty
from kivymd.uix.backdrop import backdrop
from kivymd.uix.button import MDFlatButton
from kivymd.uix.dialog import MDDialog
from kivymd.uix.segmentedbutton import MDSegmentedButton, MDSegmentedButtonItem
from kivy.utils import platform 
util.to_local_dir(__file__)
db = database.Database()
ExerciseType = 1
ExerciseName = "Benchpress"
exerciseTypeIds = ["Free", "Machine", "Cable", "Body"]
muscleIds = ["", "Pecs", "Traps", "Biceps", "Abs", "Delts", "Lats", "Triceps", "Glutes", "Hams", "Quads", "Forearms","Calves"]
alpha = 0

class UI_exesetup(Screen):
    repBase = 10
    repMax = 15
    increment = 5.0
    exerciseName = "Benchpress"
    exerciseType = 1
    muscleGroups = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    ButtonAlpha = 0 #

    def __init__(self, **kwargs):
        super(UI_exesetup, self).__init__(**kwargs)

    def PageSwitch(self):
        Page = self.ids.Page
        CloseIcon = self.ids.PageIcon
        OpenIcon = self.ids.MusclePageButton
        if Page.page == 0:
            Page.page = 1
            CloseIcon.icon = "arrow-expand-right"
            OpenIcon = ""
        else:
            Page.page = 0
            CloseIcon.icon = ""
            OpenIcon = "arm-flex"


    def init(self, dt=0):
        global exerciseTypeIds
        global alpha
        global muscleIds
        exerciseNames = [x[0] for x in db.get("SELECT Name from 'ExerciseTypeNames'")]
        muscleGroups = [0] + [x[0] for x in db.get("SELECT Name from 'MuscleGroups'")]
        ex_type, muscles, base, repmax, increment = db.get(f"SELECT Type, MuscleGroups, DefaultRepBase, DefaultRepMax, DefaultIncrement from 'Exercises' WHERE Name == '{ExerciseName}'")[0]
        self.ids.ExerciseName.text = ExerciseName
        self.ids.RepMin.value = base
        self.ids.RepRange.value = repmax
        self.ids.Increment.value = increment
        for m in muscleIds: # setting all muscles to 0
            alpha = 0
            self.MusclePart(m, InputAlpha=True)
        for tupl in muscles.split(";"):
             vals = tupl.split(",")
             index, value = int(vals[0]), float(vals[1])
             Muscle = muscleIds[index]
             alpha = value
             self.MusclePart(Muscle, InputAlpha=True)
        self.ids.ExerciseType.mark_item(self.ids[f'{exerciseTypeIds[ex_type-1]}'])
    def on_pre_enter(self):
        self.ExerciseTypeChoice(ExerciseType)
        if ExerciseName == "":
            return
        Clock.schedule_once(self.init, 0)

    def ExerciseTypeChoice(self, ExType):
        global ExerciseType        
        ExerciseType = ExType


    def SetRepRange(self): 
        nr = int(self.ids.RepRange.value)
        self.repMax = nr
        self.ids.RepRangeLabel.text = f"Repetition Range: {nr}"
        return nr

    def SetRepMin(self):
        nr = int(self.ids.RepMin.value)
        self.repBase = nr
        self.ids.RepMinLabel.text = f"Repetition Minimum: {nr}"
        return nr

    def SetInc(self):
        nr = float(self.ids.Increment.value)
        self.increment = nr
        self.ids.IncrementLabel.text = f"Weight Increment: {nr:.1f} kg"
        return nr

    def MusclePart(self, Musclepart, InputAlpha=False):
        global muscleIds 
        global alpha
        if InputAlpha == False:
            try:
                FrontMuscles = self.ids[f'{Musclepart}F']
            except:
                pass
            else:
                alpha = FrontMuscles.color[3]
                alpha = alpha - 0.5 if alpha > 0.0 else 1.0
                FrontMuscles.color = (1,1,1, alpha)

            try:
                BackMuscles = self.ids[f'{Musclepart}B']
            except:
                pass
            else:
                alpha = BackMuscles.color[3]
                alpha = alpha - 0.5 if alpha > 0.0 else 1.0
                BackMuscles.color = (1,1,1, alpha)
            
        else:
            try:
                self.ids[f'{Musclepart}F'].color = (1,1,1,alpha)
            except:
                pass

            try:
                self.ids[f'{Musclepart}B'].color = (1,1,1,alpha)
            except:
                pass

    def write(self):
        self.dialog.dismiss
        self.exerciseName = self.ids.ExerciseName.text
        exercise_id = db.get(f"SELECT id from 'Exercises' WHERE name == '{self.exerciseName}'")
        muscleString = ";".join([f"{index},{val}" for index, val in enumerate(self.muscleGroups) if val > 0.0])
        if len(exercise_id) == 0: # neue anlegen
            db.execute(f'INSERT INTO "Exercises" (Name, Type, MuscleGroups, DefaultRepBase, DefaultRepMax, DefaultIncrement) VALUES ("{self.exerciseName}", {self.exerciseType}, "{muscleString}", {self.repBase}, {self.repMax}, {self.increment})')
        else:
            db.execute(f"UPDATE 'Exercises' SET Type = {self.exerciseType}, MuscleGroups = '{muscleString}', DefaultRepBase = {self.repBase}, DefaultRepMax = {self.repMax}, DefaultIncrement = {self.increment} WHERE ID = {exercise_id[0][0]}")
        db.connection.commit()

    def Confirm(self):
        Name = self.ids.ExerciseName.text
        RepRange = self.SetRepRange()
        RepMin = self.SetRepMin()
        Increment = self.SetInc()
        AbortButton = MDFlatButton(text="Abort")
        self.ids["Abort"] = AbortButton
        SaveButton = MDFlatButton(text="Save")
        self.ids["Save"] = SaveButton
        self.dialog = MDDialog(
            title="Confirm Exercise",
            text=f"Safe {Name} with {RepMin} to {RepMin+RepRange} repetitions and {Increment} KG increments?",
            buttons=[AbortButton, SaveButton]
        )
        self.ids.Abort.on_release = self.dialog.dismiss
        self.ids.Save.on_release = self.write
        self.dialog.open()
        

        pass
        



Builder.load_file("kv/UI_exesetup.kv")


if __name__ == '__main__':
    if platform not in ["android", "ios"]:
        Window.size = (320,640)
    class FitnessTracker(App):
        def build(self):
            return AppScreenManager()

    class AppScreenManager(ScreenManager):
        def __init__(self, **kwargs):
            super(AppScreenManager, self).__init__(**kwargs)

    FitnessTracker().run()

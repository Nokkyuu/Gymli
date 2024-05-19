from kivymd.app import MDApp as App
from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.lang import Builder
from kivy.uix.button import Button
from kivy.uix.gridlayout import GridLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.boxlayout import BoxLayout
from kivy.core.window import Window
from kivy.properties import ObjectProperty
from kivy.clock import Clock  
from kivy.uix.widget import Widget
from kivy.utils import platform 


import util, database, datetime
util.to_local_dir(__file__)
db = database.Database()

class UI_landing(Screen):
    logic = util.Logic.instance()

    view = ObjectProperty(None)
    #Window.size = (400, 600)
    def __init__(self, **kwargs):
        super(UI_landing, self).__init__(**kwargs)
        Clock.schedule_once(self.create_scrollview)

    def goTo(self, button):
        exercise = button._id
        self.logic.exercise = exercise
        self.manager.current = "UI_exercise"


    def create_scrollview(self, dt):
        exercises = db.get_exercises()
        layout = GridLayout(cols=1, spacing=10, size_hint_y=None)
        layout.bind(minimum_height=self.setter("height"))
        for exercise in exercises:
            max_weight, max_reps = (0, 0)
            training_days = db.get_training_days(exercise)[::-1]
            if len(training_days) > 0:
                training_dates = [datetime.datetime.strptime(s, "%Y-%m-%d") for s in training_days]
                training_day = [d for _, d in sorted(zip(training_dates, training_days))][-1] # hack
                last_training = db.get_trainings(exercise, training_day)
                #_, _, weight, reps, _ = last_training[[_s[-1] for _s in last_training].index(1)]
                for training in last_training:
                    weight, reps = training[2], training[3] # Assuming weight is at index 2 and reps at index 3
                    if weight > max_weight:
                        max_weight = weight
                        max_reps = reps

            base = f"{exercise}   [color=#ff0]{max_weight} kg[/color]   [color=#0ff]{max_reps} Reps[/color]"
            button = Button(text=base, size=(20, 100), size_hint=(1, None), background_color=(0, 1, 1), color=(0, 0, 0, 1), markup=True)
            button._id = exercise
            button.bind(on_release = self.goTo)
            layout.add_widget(button)
        layout.add_widget(Button(text="Neue Übung", size=(20, 100), size_hint=(1, None),
                                     background_color=(1, 1, 1), color=(0, 0, 0, 1), markup=True))
        #scrollview = ScrollView(size_hint=(1, None), size=(Window.width, Window.height))
        #scrollview.add_widget(layout)
        self.view.add_widget(layout)
    


Builder.load_file("kv/UI_landing.kv")

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
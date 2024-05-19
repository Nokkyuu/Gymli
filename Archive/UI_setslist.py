from kivymd.app import MDApp as App
from kivy.uix.screenmanager import Screen
from kivy.lang import Builder
from kivy.uix.label import Label
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
from kivy.utils import platform 


import util, database, datetime
util.to_local_dir(__file__)
db = database.Database()
exercise = "Benchpress"


class SetEntry(BoxLayout):
    pass

class SetDay(BoxLayout):
    pass

class UI_setslist(Screen):
    view = ObjectProperty(None)
    logic = util.Logic.instance()

    def __init__(self, **kwargs):
        super(UI_setslist, self).__init__(**kwargs)
        Clock.schedule_once(self.create_scrollview)

    def on_pre_enter(self):
        global exercise
        exercise = self.logic.exercise
        self.ids.ExerciseName.text = self.logic.exercise
        self.ids.ExerciseNameShadow.text = self.logic.exercise
        

    def on_enter(self):
        Clock.schedule_once(self.create_scrollview)

    def on_pre_leave(self):
        self.manager.get_screen("UI_exercise").update()
        return

    def delId(self, btn):
        lay = self.ids[f"e{btn._id}"]
        db.delete_training(btn._id)
        self.ids["base"].remove_widget(lay)


    def create_scrollview(self, dt): #TODO: this will need improvement very soon
        global exercise
        
        training_days = db.get_training_days(exercise)[::]
        training_dates = [datetime.datetime.strptime(s, "%Y-%m-%d") for s in training_days]
        training_days = [d for _, d in sorted(zip(training_dates, training_days), reverse=True)] # hack
        layout = BoxLayout(orientation="vertical", spacing=15, size_hint_y=None)
        #layout.add_widget(BoxLayout(size_hint=(1,self.height/4)))
        self.ids["base"] = layout   
        layout.bind(minimum_height=layout.setter("height"))
        layout.add_widget(MDCard(size_hint_y=None, size=(1,Window.height/4), radius=0, md_bg_color=(0.01,0.5,0.99,1))) #create space on the top
        for training_day in training_days:
            base = f"{training_day}"
            DayHeader = SetDay()
            DayHeader.ids.SetDay.text = (" " + base)
            layout.add_widget(DayHeader)
            trainings = db.get_trainings(exercise, training_day)
            timestart = trainings[0][1].split(" ")[1].split("+")[0]
            SetTypesList = self.logic.setTypes
            for training in trainings:
                id, date, weight, reps, type = training
                time = date.split(" ")[1].split("+")[0]
                timedif = str(DT.strptime(time, "%H:%M:%S") - DT.strptime(timestart, "%H:%M:%S"))[2:]
                laylay = SetEntry()
                if SetTypesList[type] == "Work": #setting Icon and color for Settypes
                    laylay.ids.SetTypIcon.icon = "weight-lifter"
                    laylay.ids.SetTypIcon.color = (0.05, 0.35, 0.5, 1)
                elif SetTypesList[type] == "Warm":
                    laylay.ids.SetTypIcon.icon = "heat-wave"
                    laylay.ids.SetTypIcon.color = (1, 0.8, 0.8, 1)
                else:
                    laylay.ids.SetTypIcon.icon = "arrow-down-right"
                    laylay.ids.SetTypIcon.color = (0.6, 0.8, 0.55, 1)
                
                laylay.ids.Weight.text =  f"{weight}"
                laylay.ids.Reps.text =  f"{reps}"
                if time == timestart:
                    laylay.ids.Time.text = f"{time}"
                else:
                    laylay.ids.Time.text = f"{time}\n(+ {timedif})"
                laylay.ids.OptionsButton._id = id
                laylay.ids.OptionsButton.bind(on_press=self.delId)
                layout.add_widget(laylay)
                self.ids[f'e{id}'] = laylay 
                timestart = time #to get the next time difference

        #self.view.clear_widgets()
        self.ids.view.clear_widgets()
        self.view.add_widget(layout)


Builder.load_file("kv/UI_setslist.kv")


class FitnessTracker(App):
    def build(self):
        #self.theme_cls.primary_palette = "BlueGray"
        return UI_setslist()


if __name__ == '__main__':
    if platform not in ["android", "ios"]:
        Window.size = (320,640)
    FitnessTracker().run()
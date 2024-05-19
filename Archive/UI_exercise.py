from kivy.lang import Builder
from kivy.uix.screenmanager import Screen
from kivymd.app import MDApp as App
from kivy.core.window import Window
from kivy.clock import Clock
from kivy.graphics import *
import matplotlib.pyplot as plt
from kivy_garden.matplotlib.backend_kivyagg import FigureCanvasKivyAgg 
import datetime, util, database
import numpy as np
from kivy.utils import platform 

# this should be coming out of the database


ax, ax2 = None, None


def initialize_plot():  # this should be somewhere else, rite?
    global ax, ax2
    fig, ax = plt.subplots(1)
    ax2 = ax.twiny()
    for _ax in [ax, ax2]:
        [_ax.spines[d].set_color('white') for d in ["top", "right", "left", "bottom"]]
        _ax.tick_params(axis='y', which='both',length=0)
        _ax.tick_params(axis='x', which='both',length=4, color="gray")
    ax2.get_xaxis().set_visible(False)

class ExercisePlot(FigureCanvasKivyAgg):
    def __init__(self, **kwargs):
        super().__init__(plt.gcf(), **kwargs)

class UI_exercise(Screen):
    logic = util.Logic.instance()
    SetsData = []  # consits of a tuple with (Datetime, Type, Weight, Reps)

    def on_pre_enter(self):
        self.ids.ExerciseName.text = self.logic.exercise
        self.ids.ExerciseNameShadow.text = self.logic.exercise
        #TODO: better interface
        daylist = self.logic.db.get_training_days(self.logic.exercise)[::-1]
        # if len(daylist) > 0:
        #     training_day = daylist[0]
        #     meta = self.logic.db.get_training_meta(self.logic.exercise, training_day)[0]#
        ##FIXME: is it necessary to get the rep and increment data from the sets instead of from the exercise itself? because it creates issues.
        #     self.repBase, self.repMax, self.increment = meta
        # else:
        meta = self.logic.db.get_training_meta_zero(self.logic.exercise)
        self.repBase, self.repMax, self.increment = meta[0]
            

        Clock.schedule_once(self.update)
        self.manager.get_screen("UI_setslist").ids.ExerciseName.text = self.ids.ExerciseName.text

    def update(self, dt=0):
        ax.clear(); ax2.clear()
        xs, ys = self.logic.get_weights()
        xd, yd = self.logic.get_rep_diff()
        kws, weights = self.logic.calculate_week_score()
        ax2.scatter(xs, ys, s=20, facecolors='white', edgecolors='black', zorder=100, marker="^")#, marker="s")
        for x, y, _yd in zip(xs, ys, yd):
            ax2.plot([x, x], [y, y+_yd], "-", color="green" if _yd >0 else "red", linewidth=3.0, alpha=0.3)

        # from scipy import interpolate#TODO:Scipy replacement?
        # if len(kws) > 0:
        #     polykind = "cubic" if len(kws) > 2 else "linear"
        #     kwfunciton = interpolate.interp1d(kws, weights, kind=polykind)
        #     kwxs = np.linspace(kws[0], kws[-1], num=40)
        #     kwys =  kwfunciton(kwxs)
        #     ax.plot(kwxs, kwys, linestyle="-", zorder=200, color="orange", linewidth=0.9)#0.8)
        #     ax.set_ylim([int(min(np.nanmin(kwys), np.nanmin(ys))-2), int(max(np.nanmax(kwys), np.nanmax(ys))+2)])
        #     ax.set_ylim([int(min(np.nanmin(kwys), np.nanmin(ys))-2), int(max(np.nanmax(kwys), np.nanmax(ys))+2)])

        ax.grid(axis='y', linestyle=":")
        from matplotlib.ticker import MaxNLocator
        ax.xaxis.set_major_locator(MaxNLocator(integer=True))
        ax.tick_params(axis='x', labelsize=8)
        ax.tick_params(axis='y', labelsize=8)
        plt.draw()

    def SwitchSetTyp(self, TypeIndex):
        self.SetTypeIndex = TypeIndex  # cycle through
        colors = [(1, 0.8, 0.8, 1),(0.01,0.5,0.99,1),(0.6, 0.8, 0.55, 1)]
        self.ids.SetType.selected_color = colors[TypeIndex]
        #self.ids.SetTypLabel.text = self.SetTypesList[self.SetTypeIndex]
    
    def SubmitSet(self, *args):
        Weight, Reps = int(self.ids.WeightInputLabel.text), int(self.ids.RepsInputLabel.text)
        self.SetsData.append((*datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S').split(" "), self.SetTypeIndex, Weight, Reps))
        self.ids.PrevSetsTimeLabel.text = "".join([f"{ti}\n" for _, ti, t, w, r in self.SetsData[-4:]])
        self.ids.PrevSetsTypLabel.text = "".join([f"{self.SetTypesList[t]} Set:\n" for _, ti, t, w, r in self.SetsData[-4:]])
        self.ids.PrevSetsWeightLabel.text = "".join([f"{w} KG\n" for _, ti, t, w, r in self.SetsData[-4:]])
        self.ids.PrevSetsRepsLabel.text = "".join([f"{r} Reps\n" for _, ti, t, w, r in self.SetsData[-4:]])
        self.logic.add_workout(self.ids.ExerciseName.text, Weight, Reps, self.SetTypeIndex, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'), self.repBase, self.repMax, self.increment)
        #self.ids.DateTimeInput.text = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.update()

    def init(self, delta):
        #self.ids.DateTimeInput.text = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        #self.ids.SetTypLabel.text = "Warm"
        self.SetTypesList = self.logic.setTypes
        self.SetTypeIndex = 0
        
        

    #switch back to 400 600 after testing
    def __init__(self, **kwargs):
        super(UI_exercise, self).__init__(**kwargs)
        Clock.schedule_once(self.init, 0)

Builder.load_file("kv/UI_exercise.kv")



if __name__ == '__main__':
    class ActiveEx(App):
        def build(self):
            return UI_exercise()

    initialize_plot()
    
    if platform not in ["android", "ios"]:
        Window.size = (320,640)   
    ActiveEx().run()
from kivymd.app import MDApp as App
from kivy.uix.screenmanager import ScreenManager
from kivy.lang import Builder
from kivy.uix.screenmanager import SlideTransition
from kivy.core.text import LabelBase, DEFAULT_FONT
#from kivymd.font_definitions import theme_font_styles
from kivy.utils import platform
from kivy.core.window import Window
import UI_exercise, UI_landing, UI_setslist, UI_exesetup


UI_exercise.initialize_plot()

class WindowManager(ScreenManager):
    pass


class Main(App):
    def build(self):
        if platform not in ["android", "ios"]:
            Window.size = (320,640)
        LabelBase.register(DEFAULT_FONT, "fonts/aptos-font/aptos.ttf", fn_italic="fonts/aptos-font/aptos-italic.ttf", fn_bold="fonts/aptos-font/aptos-bold.ttf")
        kv = Builder.load_file("kv/Main.kv")
        WindowManager.transition = SlideTransition(direction="left")
        return kv

if __name__ == '__main__':
    
    Main().run()


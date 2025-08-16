## Program Stucture Overview
- /
    - main.dart 
        - main entry point, app initialization
- widgets/
    - landing_choice_screen.dart
        - Login Screen, Authentication of Demo Mode choice
    - main_app_widget.dart
        - primary scaffold that glues the navigation drawer, app bar and landing screen after login together
    - navigation_drawer.dart 
        - drawer for app navigation, imports all the screens from /screens/ and handles app navigation
- config/ 
    - api_config.dart
        - configuration file for the API (Using API Key)
- utils/
    - globals.dart
        - container for some global variables, and primary score calculation
    - info_dialogues.dart
        - container for info_dialogues for the respective screens
    - themes/
        - responsive_helper.dart
            - helper class for checking envoirment (desktop, mobile, web)
        - themes.dart
            - container for themes and colors
    - api/
        - api_models.dart
            - handles api models
        - api.dart
            - handles api calls
    - [services/](utils/services/)
        - Contains logic for app initialization, universally used services and domain services
- [screens/](screens/)
    - contains the respective screen files and subfolders

    
    


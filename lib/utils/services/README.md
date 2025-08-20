## Universal Services Overview

### Core Services

- app_initializer.dart
    - handles the app initialization
- auth0_service.dart
    - handles auth0 login and credential state initialization, needs the service container
- temp_service.dart
    - container file for the primary services and domain services.
- auth_service.dart
    - handles auth state mangement
- data_service.dart
    - handles the seperation between in memory data and api calls, used primarily for the demo mode
- theme_service.dart
    - service to handle / change theme data


### Domain Services

- activity_service.dart
    - handles activity data
- calendar_service.dart
    - handles calendar data
- exercise_service.dart
    - handles exercise data
- food_service.dart
    - handles food and nutrition data
- training_set_service.dart
    - handles training sets data
- workout_service.dart
    - handles workout data


### Service Architecture

1. **Domain Services** handle business logic for specific features
2. **Core Services** provide foundational functionality (auth, data, etc.)
3. **Service Container** orchestrates all services and provides unified access
4. **App Initializer** manages the startup sequence


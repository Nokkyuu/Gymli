import 'package:flutter/material.dart';
import 'package:yafa_app/landingScreen.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yafa_app/DataModels.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yafa_app/exerciseSetupScreen.dart';
import 'package:yafa_app/workoutSetupScreen.dart';

bool state = false;

Future<int> populateExercises() async {
  final box = await Hive.openBox<Exercise>('Exercises');
  final box2 = await Hive.openBox<TrainingSet>('TrainingSets');
  if (box.isEmpty) {
    box.clear();
    box.add(Exercise(
        name: "Benchpress",
        type: 0,
        muscleGroups: ["Pectoralis major", "Front Deltoids", "Triceps"],
        defaultRepBase: 8,
        defaultRepMax: 12,
        defaultIncrement: 5.0));
    box.add(Exercise(
        name: "Squat (Machine)",
        type: 1,
        muscleGroups: ["Quadriceps", "Gluteus maximus"],
        defaultRepBase: 15,
        defaultRepMax: 18,
        defaultIncrement: 5.9));
    box.add(Exercise(
        name: "Squat",
        type: 0,
        muscleGroups: ["Quadriceps", "Abdominals", "Gluteus maximus"],
        defaultRepBase: 15,
        defaultRepMax: 18,
        defaultIncrement: 5.9));
    box.add(Exercise(
        name: "Deadlift",
        type: 0,
        muscleGroups: [
          "Latissimus dorsi",
          "Trapezius",
          "Gluteus maximus",
          "Quadriceps",
          "Hamstrings"
        ],
        defaultRepBase: 15,
        defaultRepMax: 18,
        defaultIncrement: 5.0));
    box.add(Exercise(
        name: "Triceps Cable",
        type: 0,
        muscleGroups: ["Triceps"],
        defaultRepBase: 15,
        defaultRepMax: 20,
        defaultIncrement: 5.0));
    box.add(Exercise(
        name: "Side Delts",
        type: 0,
        muscleGroups: ["Side Deltoids"],
        defaultRepBase: 15,
        defaultRepMax: 20,
        defaultIncrement: 5.0));
    box.add(Exercise(
        name: "Face Pulls",
        type: 0,
        muscleGroups: ["Rear Deltoids", "Trapezius", "Side Deltoids"],
        defaultRepBase: 15,
        defaultRepMax: 20,
        defaultIncrement: 5.0));
    box.add(Exercise(
        name: "Face Pulls (Cable)",
        type: 2,
        muscleGroups: ["Rear Deltoids", "Trapezius", "Side Deltoids"],
        defaultRepBase: 15,
        defaultRepMax: 20,
        defaultIncrement: 5.0));
    return 1;
  }
  return 0;
}

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(TrainingSetAdapter());

  // await populate();

Brightness mode =  Brightness.light;
Color themecolor = Colors.blue;


  runApp(FutureBuilder(
    future: populateExercises(),
    builder: (_, snap) {
      if (snap.hasData) {
        //here you can use the MyService singleton and its members
        return MaterialApp(
          
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themecolor,
              brightness: mode,
            ),
            textTheme: TextTheme(
              displayLarge: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
              ),
              titleLarge: GoogleFonts.oswald(
                fontSize: 30,
                fontStyle: FontStyle.italic,
              ),
              bodyMedium: GoogleFonts.merriweather(),
              displaySmall: GoogleFonts.pacifico(),
            ),
          ),
          title: 'Navigation Basics',
          home: Scaffold(
          appBar: AppBar(
          leading: Builder(
            
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
          actions: <Widget>[
            IconButton(
            icon: Icon(Icons.light),
            onPressed: (() => mode = Brightness.dark)),//FIXME: doesnt work yet, but why
          ],
          title: const Text("Fitness Tracker"),
          centerTitle: true,),
          body: LandingScreen(),
          drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),

            ListTile(
              title: const Text('Exercise Setup'),
              onTap: () {
                //Navigator.push(context, MaterialPageRoute(builder: (context) => const ExerciseSetupScreen()));
                //FIXME: no context, but why
              },
            ),
            ListTile(
              title: const Text('Workout Setup'),
              onTap: () {
               // Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutSetupScreen()));
               //FIXME: no context, but why, i think we need to transfer all of this into a statefull widget for this to work
              },
            ),
          ],
        ),
      ),),
          
        );
      }
      return CircularProgressIndicator();
    },
  ));

}

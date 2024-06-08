// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:Gymli/DataModels.dart';




class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreen();
}

class _GroupScreen extends State<GroupScreen> {
  bool isChecked = false;
  List<String> allExercises = [];
  List<bool> checkedStatus = [];
  List<Group> groups = [];
  Group? selectedGroup;

  final TextEditingController exerciseController = TextEditingController();

  void add_group() async {
    List<String> exercises = [];
    for (int i = 0; i < allExercises.length; ++i) {
      if (checkedStatus[i]) { exercises.add(allExercises[i]); }
    }
    Group newGroup = Group(name: exerciseController.text, exercises: exercises);
    final box = await Hive.openBox<Group>('Groups');
    setState(() {
      if (groups.where((item) => item.name == exerciseController.text).toList().isEmpty) {
        box.add(newGroup);
        groups.add(newGroup);
      } else {
        var index = groups.indexOf(selectedGroup!);
        box.putAt(index, newGroup);
        groups[index] = newGroup;
      }
    });
  }

  void delete_group() async {
    if (selectedGroup == null) { return; }
    final box = await Hive.openBox<Group>('Groups');
    box.delete(selectedGroup!.key);
    setState(() {
      exerciseController.text = "";
      updateDisplay(null);
      groups.remove(selectedGroup);
    });
  }

  void updateDisplay(Group? group) {
    setState(() {
      checkedStatus = List.filled(allExercises.length, false);
      if (group != null) {
        for (var e in group.exercises) {
          checkedStatus[allExercises.indexOf(e)] = true;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    var exercises = Hive.box<Exercise>('Exercises').values.toList();
    for (var e in exercises) {
      allExercises.add(e.name);
    }
    groups = Hive.box<Group>('Groups').values.toList();
    checkedStatus = List.filled(allExercises.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () { Navigator.pop(context); },
          child: const Icon( Icons.arrow_back_ios ),
        ),
        title: const Text("Group Setup"),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center,
            children:[
              const Spacer(flex: 3),
              DropdownMenu<Group>(
                width: MediaQuery.of(context).size.width * 0.7,
                //initialSelection: ExerciseList.Benchpress,
                controller: exerciseController,
                menuHeight: 500, 
                inputDecorationTheme: InputDecorationTheme(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: BoxConstraints.tight(
                    const Size.fromHeight(40)),
                    border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                requestFocusOnTap: true,
                label: const Text('Select Group'),
                onSelected: (selected) { setState(() { selectedGroup = selected; updateDisplay(selected!); }); },
                dropdownMenuEntries: groups
                    .map<DropdownMenuEntry<Group>>(
                        (Group group) {
                  return DropdownMenuEntry<Group>(
                    value: group,
                    label: group.name,
                  );
                }).toList(),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => { add_group() }),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => { delete_group() }),
              const Spacer(),

            ]),
            const SizedBox(height: 40),
            
            Wrap(alignment: WrapAlignment.center,
            children: (() {
                List<Widget> widgets = [];
                for (int i = 0; i < allExercises.length; ++i) {
                  widgets.add(
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceAround,
                    children: [
                      Checkbox(
                        checkColor: Colors.white,
                        value: checkedStatus[i],
                        onChanged: (bool? value) { setState(() { checkedStatus[i] = value!; }); }
                      ),
                      Text(allExercises[i]),
                    ])
                );
                }
                return widgets;
              })(),
            ),
            const SizedBox(height: 20),
            const Spacer(),
          ]),
    );
  }
}

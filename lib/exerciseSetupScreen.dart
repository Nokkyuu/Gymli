import 'package:flutter/material.dart';
enum ExerciseDevice { free, machine, cable, body }


class ExerciseSetupScreen extends StatefulWidget {
  const ExerciseSetupScreen({super.key});
  
  @override
  State<ExerciseSetupScreen> createState() => _ExerciseSetupScreenState();
}

class _ExerciseSetupScreenState extends State<ExerciseSetupScreen> {
  ExerciseDevice chosenDevice = ExerciseDevice.free;
  double boxSpace = 10;
  double minRep = 1;
  double repRange = 1;
  double weightInc = 1;

  @override
  Widget build(BuildContext context) {
    const title = 'New Exercise';
    
    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          leading: InkWell( onTap: () {Navigator.pop(context); },
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.black54,
          ),),
          title: const Text(title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              SegmentedButton<ExerciseDevice>(
                segments: const <ButtonSegment<ExerciseDevice>>[
                  ButtonSegment<ExerciseDevice>(
                      value: ExerciseDevice.free,
                      label: Text('Free'),
                      icon: Icon(Icons.sports_tennis)
                      ),
                  ButtonSegment<ExerciseDevice>(
                      value: ExerciseDevice.machine,
                      label: Text('Machine'),
                      icon: Icon(Icons.agriculture_outlined)
                      ),
                  ButtonSegment<ExerciseDevice>(
                      value: ExerciseDevice.cable,
                      label: Text('Cable'),
                      icon: Icon(Icons.cable)
                      ),
                  ButtonSegment<ExerciseDevice>(
                      value: ExerciseDevice.body,
                      label: Text('Body'),
                      icon: Icon(Icons.sports_martial_arts)
                      ),
                  
                ],
                selected: <ExerciseDevice>{chosenDevice},
                onSelectionChanged: (Set<ExerciseDevice> newSelection){
                  setState(() {
                    chosenDevice = newSelection.first;
                  });
                }
              ),
              SizedBox(height: boxSpace),
              HeadCard(headline: "Minimum Repetitions"),
              Slider(
                value: minRep,
                min: 1,
                max: 20,
                divisions: 20,
                label: minRep.round().toString(),
                onChanged: (double value) {
                  setState(() {
                  minRep = value;
                  });
                },
              ),
              SizedBox(height: boxSpace),
              HeadCard(headline: "Repetition Range"),
              Slider(
                value: repRange,
                min: 1,
                max: 20,
                divisions: 20,
                label: repRange.round().toString(),
                onChanged: (double value) {
                  setState(() {
                  repRange = value;
                  });
                },
              ),
              SizedBox(height: boxSpace),
              HeadCard(headline: "Weight Increments"),
              Slider(
                value: weightInc,
                min: 1,
                max: 10,
                divisions: 20,
                label: weightInc.round().toString(),
                onChanged: (double value) {
                  setState(() {
                  weightInc = value;
                  });
                },
              ),
              SizedBox(height: boxSpace),
              IconButton(
                icon: const Icon(Icons.check),
                iconSize: 50,
                tooltip: 'Confirm',
                onPressed: () {
                  setState(() {
                  
                  });
                },
              ),
          
          ],
              
          ),
        )
      )
    );       
  }
}

class HeadCard extends StatelessWidget {
  const HeadCard({
    super.key,
    required this.headline,
  });
  final String headline;

  @override
  Widget build(BuildContext context) {
    
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(headline, 
        style: style,
        ),
      ),
    );
  }
}
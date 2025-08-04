import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/muscle_selection_controller.dart';

class MuscleSelectionBottomSheetWidget extends StatelessWidget {
  const MuscleSelectionBottomSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MuscleSelectionController>(
      builder: (context, controller, child) {
        return SizedBox.expand(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ElevatedButton(
                  child: const Text('Close'),
                  onPressed: () => Navigator.pop(context),
                ),
                LayoutBuilder(builder: (context, constraints) {
                  return Stack(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth / 2,
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Transform.scale(
                              scaleX: -1,
                              child: Stack(children: [
                                Image(
                                  width: constraints.maxWidth / 3,
                                  fit: BoxFit.fill,
                                  image: const AssetImage(
                                      'images/muscles/Front_bg.png'),
                                ),
                                for (var i in controller.frontImages)
                                  Image(
                                    fit: BoxFit.fill,
                                    width: constraints.maxWidth / 3,
                                    image: AssetImage(i[0]),
                                    opacity: AlwaysStoppedAnimation(
                                        controller.getMuscleIntensity(i[1])),
                                  ),
                                for (var i in controller.frontButtons)
                                  FractionallySizedBox(
                                      alignment: Alignment.bottomRight,
                                      heightFactor: i[0],
                                      widthFactor: i[1],
                                      child: Stack(
                                        alignment:
                                            AlignmentDirectional.bottomEnd,
                                        children: [
                                          TextButton(
                                              onPressed: () {
                                                controller.toggleMuscle(i[2]);
                                              },
                                              child: Transform.scale(
                                                  scaleX: -1,
                                                  child: Text(
                                                    "${controller.getMusclePercentage(i[2])}%",
                                                    maxLines: 1,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge,
                                                    overflow:
                                                        TextOverflow.visible,
                                                  )))
                                        ],
                                      )),
                              ])),
                        ),
                        SizedBox(
                            width: constraints.maxWidth / 2,
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: Stack(children: [
                              Image(
                                  fit: BoxFit.fill,
                                  width: constraints.maxWidth / 3,
                                  image: const AssetImage(
                                      'images/muscles/Back_bg.png')),
                              for (var i in controller.backImages)
                                Image(
                                  fit: BoxFit.fill,
                                  width: constraints.maxWidth / 3,
                                  image: AssetImage(i[0]),
                                  opacity: AlwaysStoppedAnimation(
                                      controller.getMuscleIntensity(i[1])),
                                ),
                              for (var i in controller.backButtons)
                                FractionallySizedBox(
                                    alignment: Alignment.bottomRight,
                                    heightFactor: i[0],
                                    widthFactor: i[1],
                                    child: Stack(
                                      alignment: AlignmentDirectional.bottomEnd,
                                      children: [
                                        TextButton(
                                            onPressed: () {
                                              controller.toggleMuscle(i[2]);
                                            },
                                            child: Text(
                                              "${controller.getMusclePercentage(i[2])}%",
                                              maxLines: 1,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge,
                                              overflow: TextOverflow.visible,
                                            ))
                                      ],
                                    )),
                            ]))
                      ],
                    ),
                  ]);
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

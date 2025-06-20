import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:numberpicker/numberpicker.dart';
import '../controllers/exercise_controller.dart';

/// Widget for exercise input controls (weight, reps, submit)
class ExerciseControlsWidget extends StatefulWidget {
  final ExerciseController controller;
  final bool isDesktop;
  final VoidCallback? onSubmit;

  const ExerciseControlsWidget({
    super.key,
    required this.controller,
    this.isDesktop = false,
    this.onSubmit,
  });

  @override
  State<ExerciseControlsWidget> createState() => _ExerciseControlsWidgetState();
}

class _ExerciseControlsWidgetState extends State<ExerciseControlsWidget> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late FixedExtentScrollController _repsWheelController;
  //late TextEditingController _dateInputController;

  // Focus tracking to prevent overwriting during user input
  late FocusNode _weightFocusNode;
  late FocusNode _repsFocusNode;
  bool _isUserEditingWeight = false;
  bool _isUserEditingReps = false;

  final List<int> _values = List<int>.generate(30, (i) => i + 1);
  static const double itemHeight = 35.0;
  static const double itemWidth = 50.0;
  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _repsController = TextEditingController();

    // Initialize focus nodes
    _weightFocusNode = FocusNode();
    _repsFocusNode = FocusNode();

    // Add focus listeners to track user editing
    _weightFocusNode.addListener(() {
      _isUserEditingWeight = _weightFocusNode.hasFocus;
    });
    _repsFocusNode.addListener(() {
      _isUserEditingReps = _repsFocusNode.hasFocus;
    });

    // Initialize with safe default value (index 9 = 10 reps)
    _repsWheelController = FixedExtentScrollController(initialItem: 9);

    // _dateInputController = TextEditingController(
    //   text: DateTime.now().toIso8601String(),
    // );

    // Listen to controller changes
    widget.controller.addListener(_updateControllersFromState);

    // Defer the initial update to next frame to ensure controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllersFromState();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateControllersFromState);
    _weightController.dispose();
    _repsController.dispose();
    _repsWheelController.dispose();
    // _dateInputController.dispose();
    _weightFocusNode.dispose();
    _repsFocusNode.dispose();
    super.dispose();
  }

  void _updateControllersFromState() {
    if (!mounted) return;

    // Only update weight if user is not actively editing it
    if (!_isUserEditingWeight) {
      final weight = widget.controller.weightAsDouble;
      final currentWeight = _weightController.text;
      final newWeight = weight.toString();
      if (currentWeight != newWeight) {
        _weightController.text = newWeight;
      }
    }

    // Only update reps if user is not actively editing it
    if (!_isUserEditingReps) {
      final reps = widget.controller.repetitions.toString();
      if (_repsController.text != reps) {
        _repsController.text = reps;
      }
    }

    // Update reps wheel controller safely
    try {
      final repsIndex =
          (widget.controller.repetitions - 1).clamp(0, _values.length - 1);

      // Only update if the controller has clients (is attached to a widget)
      // and if the current selection is different
      if (_repsWheelController.hasClients) {
        final currentIndex = _repsWheelController.selectedItem;
        if (currentIndex != repsIndex) {
          // Use animateToItem for smooth updates
          if (_repsWheelController.positions.isNotEmpty) {
            _repsWheelController.animateToItem(
              repsIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            // If positions are empty, defer the update
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _repsWheelController.hasClients) {
                _repsWheelController.jumpToItem(repsIndex);
              }
            });
          }
        }
      } else {
        // If no clients, defer the update to next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _repsWheelController.hasClients) {
            _repsWheelController.jumpToItem(repsIndex);
          }
        });
      }
    } catch (e) {
      // Handle case where scroll controller isn't ready yet
      debugPrint('Warning: Reps wheel controller not ready: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isDesktop ? _buildDesktopControls() : _buildMobileControls();
  }

  Widget _buildMobileControls() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildTypeSelector(),
          const SizedBox(height: 10),
          _buildWeightRepsPickers(),
          const SizedBox(height: 20),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildDesktopControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildDesktopTypeSelector(),
          const SizedBox(width: 40),
          _buildDesktopWeightRepsInputs(),
          const SizedBox(width: 40),
          _buildDesktopSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return SegmentedButton<ExerciseType>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment<ExerciseType>(
              value: ExerciseType.warmup,
              label: widget.controller.warmText,
              icon: const Icon(Icons.local_fire_department),
            ),
            ButtonSegment<ExerciseType>(
              value: ExerciseType.work,
              label: widget.controller.workText,
              icon: const FaIcon(FontAwesomeIcons.handFist),
            ),
          ],
          selected: widget.controller.selectedType,
          onSelectionChanged: (newSelection) {
            widget.controller.updateSelectedType(newSelection);
          },
        );
      },
    );
  }

  Widget _buildDesktopTypeSelector() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption(ExerciseType.warmup, widget.controller.warmText,
                Icons.local_fire_department),
            const SizedBox(height: 8),
            _buildRadioOption(ExerciseType.work, widget.controller.workText,
                FontAwesomeIcons.handFist),
          ],
        );
      },
    );
  }

  Widget _buildRadioOption(ExerciseType type, Text label, dynamic icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<ExerciseType>(
          value: type,
          groupValue: widget.controller.selectedType.first,
          onChanged: (ExerciseType? value) {
            if (value != null) {
              widget.controller.updateSelectedType({value});
            }
          },
        ),
        GestureDetector(
          onTap: () => widget.controller.updateSelectedType({type}),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                child: icon is IconData ? Icon(icon) : FaIcon(icon),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 60, child: label),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildWeightRepsPickers() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 10),
              NumberPicker(
                value: widget.controller.weightKg,
                minValue: -70,
                maxValue: 250,
                haptics: true,
                itemHeight: itemHeight,
                itemWidth: itemWidth,
                onChanged: (value) => widget.controller
                    .updateWeight(value, widget.controller.weightDg),
              ),
              const Text(","),
              NumberPicker(
                value: widget.controller.weightDg,
                minValue: 0,
                maxValue: 75,
                step: 25,
                haptics: true,
                itemHeight: itemHeight,
                itemWidth: itemWidth,
                onChanged: (value) => widget.controller
                    .updateWeight(widget.controller.weightKg, value),
              ),
              const Text("kg"),
              const SizedBox(width: 10),
              SizedBox(
                height: 100,
                width: 80,
                child: ListWheelScrollView.useDelegate(
                  controller: _repsWheelController,
                  itemExtent: 40,
                  physics: const FixedExtentScrollPhysics(),
                  useMagnifier: true,
                  magnification: 1.4,
                  onSelectedItemChanged: (index) {
                    if (index >= 0 && index < _values.length) {
                      widget.controller.updateRepetitions(_values[index]);
                      HapticFeedback.selectionClick();
                    }
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index >= _values.length) return null;
                      final value = _values[index];
                      final color =
                          widget.controller.colorMap.containsKey(value)
                              ? widget.controller.colorMap[value]
                              : Colors.black;
                      return Center(
                        child: Text(
                          value.toString(),
                          style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      );
                    },
                    childCount: _values.length,
                  ),
                ),
              ),
              const Text("Reps."),
              const SizedBox(width: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopWeightRepsInputs() {
    return Column(
      children: [
        SizedBox(
          width: 120,
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            controller: _weightController,
            focusNode: _weightFocusNode,
            onChanged: (value) {
              final weight = double.tryParse(value) ?? 0.0;
              final kg = weight.toInt();
              final dg = ((weight - kg) * 100).round();
              widget.controller.updateWeight(kg, dg);
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 120,
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Reps',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            controller: _repsController,
            focusNode: _repsFocusNode,
            onChanged: (value) {
              final reps = int.tryParse(value) ?? 10;
              widget.controller.updateRepetitions(reps.clamp(1, 30));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      label: const Text('Submit'),
      icon: const Icon(Icons.send),
      onPressed: widget.controller.isLoading ? null : _handleSubmit,
    );
  }

  Widget _buildDesktopSubmitButton() {
    return SizedBox(
      height: 60,
      child: FilledButton.icon(
        label: const Text('Submit'),
        icon: const Icon(Icons.send),
        onPressed: widget.controller.isLoading ? null : _handleSubmit,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (widget.controller.currentExercise == null) return;
    final currentTimestamp = DateTime.now().toIso8601String();

    final success = await widget.controller.addTrainingSet(
      widget.controller.currentExercise!.name,
      widget.controller.weightAsDouble,
      widget.controller.repetitions,
      widget.controller.selectedType.first.index,
      currentTimestamp,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Training set saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      widget.onSubmit?.call();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.controller.errorMessage ?? 'Failed to save training set'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

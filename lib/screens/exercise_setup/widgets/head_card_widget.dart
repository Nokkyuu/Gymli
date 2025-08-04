import 'package:flutter/material.dart';

class HeadCardWidget extends StatelessWidget {
  final String headline;

  const HeadCardWidget({
    super.key,
    required this.headline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium!.copyWith();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          headline,
          style: style,
        ),
      ),
    );
  }
}

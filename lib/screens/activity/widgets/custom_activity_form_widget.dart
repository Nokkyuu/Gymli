/// Custom Activity Form Widget - Form for creating custom activities
library;

import 'package:flutter/material.dart';

class CustomActivityFormWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController caloriesController;
  final VoidCallback onSubmit;

  const CustomActivityFormWidget({
    super.key,
    required this.nameController,
    required this.caloriesController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Custom Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Activity Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Rock Climbing',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories per Hour',
                border: OutlineInputBorder(),
                suffixText: 'kcal/hr',
                hintText: 'e.g., 400',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.add),
                label: const Text('Create Activity'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

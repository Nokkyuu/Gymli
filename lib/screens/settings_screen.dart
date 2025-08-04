/// Refactored Settings Screen - Clean modular architecture
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings/controllers/settings_controller.dart';
import 'settings/widgets/settings_header_widget.dart';
import 'settings/widgets/data_counter_widget.dart';
import 'settings/widgets/sections/export_section_widget.dart';
import 'settings/widgets/sections/import_section_widget.dart';
import 'settings/widgets/sections/wipe_section_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsController(),
      child: const _SettingsScreenView(),
    );
  }
}

class _SettingsScreenView extends StatelessWidget {
  const _SettingsScreenView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<SettingsController>(
        builder: (context, controller, child) {
          return Stack(
            children: [
              // Main content
              const SingleChildScrollView(
                child: Column(
                  children: [
                    // App header with logo and branding
                    SettingsHeaderWidget(),

                    // Divider after header
                    Divider(),

                    // Data overview
                    DataCounterWidget(),

                    // Export section
                    ExportSectionWidget(),

                    // Import section
                    ImportSectionWidget(),

                    // Wipe section
                    WipeSectionWidget(),

                    // Bottom padding
                    SizedBox(height: 32),
                  ],
                ),
              ),

              // Operation blocker when operations are in progress
              if (controller.isAnyOperationInProgress)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Card(
                      margin: EdgeInsets.all(32),
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Operation in progress...',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please wait',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

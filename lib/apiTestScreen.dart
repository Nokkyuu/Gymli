// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'api.dart' as api;

class apiTestScreen extends StatefulWidget {
  const apiTestScreen({super.key});

  @override
  State<apiTestScreen> createState() => _apiTestScreen();
}

class _apiTestScreen extends State<apiTestScreen> {
  List<dynamic>? _animals;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  void _loadAnimals() async {
    try {
      final data = await api.AnimalService().getAnimals();
      setState(() {
        _animals = data;
      });
    } catch (e) {
      print('Error fetching animals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios,
            ),
          ),
          title: const Text("API Test"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Animals',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _animals == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _animals!.length,
                        itemBuilder: (context, index) {
                          final animal = _animals![index];
                          return ListTile(
                            title: Text(animal['name']),
                            subtitle: Text(animal['sound']),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await api.AnimalService()
                                    .deleteAnimal(animal['id']);
                                _loadAnimals(); // Refresh list
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final nameController = TextEditingController();
                      final soundController = TextEditingController();
                      return AlertDialog(
                        title: const Text('Add Animal'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              decoration:
                                  const InputDecoration(labelText: 'Name'),
                            ),
                            TextField(
                              controller: soundController,
                              decoration:
                                  const InputDecoration(labelText: 'Sound'),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await api.AnimalService().createAnimal(
                                nameController.text,
                                soundController.text,
                              );
                              Navigator.pop(context);
                              _loadAnimals(); // Refresh list
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Add Animal'),
              ),
            ],
          ),
        ));
  }
}

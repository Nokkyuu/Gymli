import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl =
    'https://gymliapi-gyg0ardqh5dadaba.germanywestcentral-01.azurewebsites.net';

class AnimalService {
  Future<List<dynamic>> getAnimals() async {
    final response = await http.get(Uri.parse('$baseUrl/animals'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load animals');
    }
  }

  Future<void> createAnimal(String name, String sound) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animals'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'sound': sound}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create animal');
    }
  }

  Future<void> deleteAnimal(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/animals/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete animal');
    }
  }
}

class FoodItem {
  final int? id;
  //final String userName;
  final String name;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String? notes;

  FoodItem({
    this.id,
    //required this.userName,
    required this.name,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.notes,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      // userName: json['user_name'] ?? '',
      name: json['name'] ?? '',
      kcalPer100g: (json['kcal_per_100g'] ?? 0.0).toDouble(),
      proteinPer100g: (json['protein_per_100g'] ?? 0.0).toDouble(),
      carbsPer100g: (json['carbs_per_100g'] ?? 0.0).toDouble(),
      fatPer100g: (json['fat_per_100g'] ?? 0.0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // 'user_name': userName,
      'name': name,
      'kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
      'notes': notes,
    };
  }

  List<String> toCSVString() {
    return [
      name,
      kcalPer100g.toString(),
      proteinPer100g.toString(),
      carbsPer100g.toString(),
      fatPer100g.toString(),
      notes ?? '',
    ];
  }
}

class FoodLog {
  final int? id;
  //final String userName;
  final String foodName;
  final DateTime date;
  final double grams;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  FoodLog({
    this.id,
    //required this.userName,
    required this.foodName,
    required this.date,
    required this.grams,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      id: json['id'],
      // userName: json['user_name'] ?? '',
      foodName: json['food_name'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      grams: (json['grams'] ?? 0.0).toDouble(),
      kcalPer100g: (json['kcal_per_100g'] ?? 0.0).toDouble(),
      proteinPer100g: (json['protein_per_100g'] ?? 0.0).toDouble(),
      carbsPer100g: (json['carbs_per_100g'] ?? 0.0).toDouble(),
      fatPer100g: (json['fat_per_100g'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      //'user_name': userName,
      'food_name': foodName,
      'date': date.toIso8601String(),
      'grams': grams,
      'kcal_per_100g': kcalPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
    };
  }
}

import 'dart:async';
import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class Exercise extends HiveObject {
  Exercise ({
    required this.id,
    required this.name,
    required this.type,
    required this.muscleGroups,
    required this.defaultRepBase,
    required this.defaultRepMax,
    required this.defaultIncrement
  });

  @HiveField(0)
  int id = 0;
  @HiveField(1)
  String name = "";
  @HiveField(2)
  int type = 0;
  @HiveField(3)
  String muscleGroups = "";
  @HiveField(4)
  int defaultRepBase = 10;
  @HiveField(5)
  int defaultRepMax = 15;
  @HiveField(6)
  double defaultIncrement = 1.0;

  // Exercise.fromJson(Map<String, dynamic> json) {
  //   if (json != null) {
  //     id = json['id'];
  //     name = json['name'];
  //     type = json['type'];
  //     muscleGroups = json['muscleGroups'];
  //     defaultRepBase = json['defaultRepBase'];
  //     defaultRepMax = json['defaultRepMax'];
  //     defaultIncrement = json['defaultIncrement'];
  //   } else {
  //     print('in else profile from json');
  //   }
  // }

  // Map<String, dynamic> toJson() {
  //   final Map<String, dynamic> data = new Map<String, dynamic>();
  //   data['name'] = this.name;
  //   data['language'] = this.lang;
  //   data['emailId'] = this.emailId;
  //   data['mobileNumber'] = this.mobileNumber;
  //   data['district'] = this.district;
  //   data['state'] = this.state;
  //   data['city'] = this.city;
  //   data['pinCode'] = this.pinCode;
  //   data['profilePic'] = this.profilePic;
  //   return data;
  // }
}


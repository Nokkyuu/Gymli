// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DataModels.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 1;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exercise(
      name: fields[0] as String,
      type: fields[1] as int,
      muscleGroups: fields[2] as String,
      defaultRepBase: fields[3] as int,
      defaultRepMax: fields[4] as int,
      defaultIncrement: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.muscleGroups)
      ..writeByte(3)
      ..write(obj.defaultRepBase)
      ..writeByte(4)
      ..write(obj.defaultRepMax)
      ..writeByte(5)
      ..write(obj.defaultIncrement);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

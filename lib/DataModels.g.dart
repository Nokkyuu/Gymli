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
      id: fields[0] as int,
      name: fields[1] as String,
      type: fields[2] as int,
      muscleGroups: fields[3] as String,
      defaultRepBase: fields[4] as int,
      defaultRepMax: fields[5] as int,
      defaultIncrement: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.muscleGroups)
      ..writeByte(4)
      ..write(obj.defaultRepBase)
      ..writeByte(5)
      ..write(obj.defaultRepMax)
      ..writeByte(6)
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

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
      muscleGroups: (fields[2] as List).cast<String>(),
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

class TrainingSetAdapter extends TypeAdapter<TrainingSet> {
  @override
  final int typeId = 2;

  @override
  TrainingSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingSet(
      id: fields[0] as int,
      exercise: fields[1] as String,
      date: fields[2] as DateTime,
      weight: fields[3] as double,
      repetitions: fields[4] as int,
      setType: fields[5] as int,
      baseReps: fields[6] as int,
      maxReps: fields[7] as int,
      increment: fields[8] as double,
      machineName: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingSet obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exercise)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.repetitions)
      ..writeByte(5)
      ..write(obj.setType)
      ..writeByte(6)
      ..write(obj.baseReps)
      ..writeByte(7)
      ..write(obj.maxReps)
      ..writeByte(8)
      ..write(obj.increment)
      ..writeByte(9)
      ..write(obj.machineName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

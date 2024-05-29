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
      muscleIntensities: (fields[6] as List).cast<double>(),
      defaultRepBase: fields[3] as int,
      defaultRepMax: fields[4] as int,
      defaultIncrement: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.defaultIncrement)
      ..writeByte(6)
      ..write(obj.muscleIntensities);
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
      exercise: fields[0] as String,
      date: fields[1] as DateTime,
      weight: fields[2] as double,
      repetitions: fields[3] as int,
      setType: fields[4] as int,
      baseReps: fields[5] as int,
      maxReps: fields[6] as int,
      increment: fields[7] as double,
      machineName: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingSet obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.exercise)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.repetitions)
      ..writeByte(4)
      ..write(obj.setType)
      ..writeByte(5)
      ..write(obj.baseReps)
      ..writeByte(6)
      ..write(obj.maxReps)
      ..writeByte(7)
      ..write(obj.increment)
      ..writeByte(8)
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

class WorkoutUnitAdapter extends TypeAdapter<WorkoutUnit> {
  @override
  final int typeId = 3;

  @override
  WorkoutUnit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutUnit(
      exercise: fields[0] as String,
      warmups: fields[1] as int,
      worksets: fields[2] as int,
      dropsets: fields[3] as int,
      type: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutUnit obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.exercise)
      ..writeByte(1)
      ..write(obj.warmups)
      ..writeByte(2)
      ..write(obj.worksets)
      ..writeByte(3)
      ..write(obj.dropsets)
      ..writeByte(4)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  final int typeId = 4;

  @override
  Workout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Workout(
      exercise: fields[0] as String,
      units: (fields[1] as List).cast<WorkoutUnit>(),
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.exercise)
      ..writeByte(1)
      ..write(obj.units);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

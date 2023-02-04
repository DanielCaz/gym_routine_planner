import 'package:gym_routine_planner/models/routine_exercise.dart';

class RoutineDay {
  final String? id;
  String name;
  final int dayIndex;
  final List<RoutineExercise> exercises;

  RoutineDay({
    this.id,
    required this.name,
    required this.dayIndex,
    required this.exercises,
  });
}

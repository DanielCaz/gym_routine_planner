import 'package:gym_routine_planner/models/routine_excercise.dart';

class RoutineDay {
  final String? id;
  String name;
  final int dayIndex;
  final List<RoutineExcercise> excercises;

  RoutineDay({
    this.id,
    required this.name,
    required this.dayIndex,
    required this.excercises,
  });
}

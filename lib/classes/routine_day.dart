import 'package:gym_routine_planner/classes/routine_excersize.dart';

class RoutineDay {
  final String? id;
  final String day;
  String name;
  final int dayIndex;
  final List<RoutineExcersize> excersizes;

  RoutineDay({
    this.id,
    required this.name,
    required this.day,
    required this.dayIndex,
    required this.excersizes,
  });
}

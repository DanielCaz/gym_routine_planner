import 'package:gym_routine_planner/classes/routine_excersize.dart';

class RoutineDay {
  final String? id;
  final String day;
  final int dayIndex;
  final List<RoutineExcersize> excersizes;

  RoutineDay({
    this.id,
    required this.day,
    required this.dayIndex,
    required this.excersizes,
  });
}

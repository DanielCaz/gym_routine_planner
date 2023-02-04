import 'package:gym_routine_planner/localization/global_strings.dart';
import 'package:gym_routine_planner/models/routine_exercise.dart';
import 'package:flutter/material.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    this.onEdit,
  });

  final RoutineExercise exercise;
  final void Function()? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        elevation: 2,
        child: ListTile(
          title: Text(exercise.name),
          subtitle: Text(exercise.minutes == null
              ? '${exercise.sets} sets x ${exercise.reps} reps${exercise.machine?.isNotEmpty ?? false ? '\n${Languages.of(context)!.on} ${exercise.machine}' : ''}'
              : '${exercise.minutes} ${Languages.of(context)!.minutes}${exercise.machine?.isNotEmpty ?? false ? '\n${Languages.of(context)!.on} ${exercise.machine}' : ''}'),
          isThreeLine: exercise.machine?.isNotEmpty ?? false,
          trailing: onEdit != null
              ? IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                )
              : null,
        ),
      ),
    );
  }
}

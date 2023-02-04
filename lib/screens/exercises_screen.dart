import 'package:gym_routine_planner/localization/global_strings.dart';
import 'package:gym_routine_planner/models/routine_exercise.dart';
import 'package:gym_routine_planner/widgets/dissmissible_bg.dart';
import 'package:gym_routine_planner/widgets/exercise_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<RoutineExercise> _exercises = [];

  bool _isLoading = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _exerciseNameController = TextEditingController();
  final TextEditingController _exerciseMinutesController =
      TextEditingController();
  final TextEditingController _exerciseSetsController = TextEditingController();
  final TextEditingController _exerciseRepsController = TextEditingController();
  final TextEditingController _exerciseMachineController =
      TextEditingController();

  void initData() async {
    final exercises = await _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .collection('exercises')
        .get();

    for (final exercise in exercises.docs) {
      _exercises.add(
        RoutineExercise(
          id: exercise.id,
          name: exercise['name'],
          machine: exercise['machine'],
          sets: exercise['sets'],
          reps: exercise['reps'],
          minutes: exercise['minutes'],
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void removeUserExercise(RoutineExercise exercise) async {
    setState(() {
      _isLoading = true;
    });
    await _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .collection('exercises')
        .doc(exercise.id)
        .delete();

    final routines = await _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .collection('routines')
        .get();

    for (final routine in routines.docs) {
      final exercises = routine['exercises'];
      exercises.removeWhere((e) => e['id'] == exercise.id);
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('routines')
          .doc(routine.id)
          .update({
        'exercises': exercises,
      });
    }

    setState(() {
      _exercises.remove(exercise);
      _isLoading = false;
    });
  }

  void updateRoutineExercise(RoutineExercise exercise) async {
    setState(() {
      _isLoading = true;
    });
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('exercises')
        .doc(exercise.id)
        .update({
      'name': exercise.name,
      'machine': exercise.machine,
      'sets': exercise.sets,
      'reps': exercise.reps,
      'minutes': exercise.minutes,
    });

    final routines = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('routines')
        .get();

    for (final routine in routines.docs) {
      final exercises = routine['exercises'];
      final index = exercises.indexWhere((e) => e['id'] == exercise.id, -1);
      if (index == -1) continue;

      exercises[index] = {
        'id': exercise.id,
        'name': exercise.name,
        'machine': exercise.machine,
        'sets': exercise.sets,
        'reps': exercise.reps,
        'minutes': exercise.minutes,
      };
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('routines')
          .doc(routine.id)
          .update({
        'exercises': exercises,
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void addRoutineExercise(RoutineExercise exercise) async {
    setState(() {
      _isLoading = true;
    });
    final doc = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('exercises')
        .add({
      'name': exercise.name,
      'machine': exercise.machine,
      'sets': exercise.sets,
      'reps': exercise.reps,
      'minutes': exercise.minutes,
    });

    setState(() {
      _exercises.add(
        RoutineExercise(
          id: doc.id,
          name: exercise.name,
          machine: exercise.machine,
          sets: exercise.sets,
          reps: exercise.reps,
          minutes: exercise.minutes,
        ),
      );
      _isLoading = false;
    });
  }

  void showEditRoutineExerciseDialog(RoutineExercise routineExercise) {
    _exerciseNameController.text = routineExercise.name;
    _exerciseMinutesController.text = routineExercise.minutes?.toString() ?? '';
    _exerciseSetsController.text = routineExercise.sets?.toString() ?? '';
    _exerciseRepsController.text = routineExercise.reps?.toString() ?? '';
    _exerciseMachineController.text = routineExercise.machine ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Languages.of(context)?.editExercise ?? 'Edit Exercise'),
          content: buildExerciseRoutineDialog(),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(Languages.of(context)?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  routineExercise.name = _exerciseNameController.text;
                  routineExercise.minutes =
                      _exerciseMinutesController.text.isEmpty
                          ? null
                          : int.parse(_exerciseMinutesController.text);
                  routineExercise.sets = _exerciseSetsController.text.isEmpty
                      ? null
                      : int.parse(_exerciseSetsController.text);
                  routineExercise.reps = _exerciseRepsController.text.isEmpty
                      ? null
                      : int.parse(_exerciseRepsController.text);
                  routineExercise.machine = _exerciseMachineController.text;

                  updateRoutineExercise(routineExercise);
                  Navigator.of(context).pop();
                }
              },
              child: Text(Languages.of(context)?.save ?? 'Save'),
            ),
          ],
        );
      },
    );
  }

  void showAddRoutineExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Languages.of(context)?.addExercise ?? 'Add Exercise'),
          content: buildExerciseRoutineDialog(),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(Languages.of(context)?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  addRoutineExercise(
                    RoutineExercise(
                      name: _exerciseNameController.text,
                      minutes: _exerciseMinutesController.text.isEmpty
                          ? null
                          : int.parse(_exerciseMinutesController.text),
                      sets: _exerciseSetsController.text.isEmpty
                          ? null
                          : int.parse(_exerciseSetsController.text),
                      reps: _exerciseRepsController.text.isEmpty
                          ? null
                          : int.parse(_exerciseRepsController.text),
                      machine: _exerciseMachineController.text,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text(Languages.of(context)?.save ?? 'Save'),
            ),
          ],
        );
      },
    );
  }

  Form buildExerciseRoutineDialog() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _exerciseNameController,
              decoration: InputDecoration(
                labelText: Languages.of(context)?.nameField ?? 'Name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return Languages.of(context)?.nameErrorMessage ??
                      'Please enter a name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _exerciseMinutesController,
              decoration: InputDecoration(
                labelText: Languages.of(context)?.minutesField ?? 'Minutes',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (_exerciseSetsController.text.isNotEmpty ||
                      _exerciseRepsController.text.isNotEmpty) {
                    return Languages.of(context)?.minutesErrorMessage ??
                        'Please enter either minutes or sets and reps';
                  }
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _exerciseSetsController,
              decoration: InputDecoration(
                labelText: Languages.of(context)?.setsField ?? 'Sets',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (_exerciseMinutesController.text.isNotEmpty) {
                    return Languages.of(context)?.setsErrorMessageMins ??
                        'Please enter either minutes or sets and reps';
                  }
                } else {
                  if (_exerciseRepsController.text.isNotEmpty) {
                    return Languages.of(context)?.setsErrorMessageReps ??
                        'Please enter either minutes or sets and reps';
                  }
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _exerciseRepsController,
              decoration: InputDecoration(
                labelText: Languages.of(context)?.repsField ?? 'Reps',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (_exerciseMinutesController.text.isNotEmpty) {
                    return Languages.of(context)?.repsErrorMessageMins ??
                        'Please enter either minutes or sets and reps';
                  }
                } else {
                  if (_exerciseSetsController.text.isNotEmpty) {
                    return Languages.of(context)?.repsErrorMessageSets ??
                        'Please enter either minutes or sets and reps';
                  }
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _exerciseMachineController,
              decoration: InputDecoration(
                labelText: Languages.of(context)?.machineField ?? 'Machine',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _exerciseMinutesController.dispose();
    _exerciseSetsController.dispose();
    _exerciseRepsController.dispose();
    _exerciseMachineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Languages.of(context)?.exercises ?? 'Exercises'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    removeUserExercise(exercise);
                  },
                  background: const DissmissBackground(),
                  child: ExerciseCard(
                    exercise: exercise,
                    onEdit: () {
                      showEditRoutineExerciseDialog(exercise);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddRoutineExerciseDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

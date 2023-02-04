import 'package:gym_routine_planner/Localization/locale_constant.dart';
import 'package:gym_routine_planner/Localization/global_strings.dart';
import 'package:gym_routine_planner/screens/exercises_screen.dart';
import 'package:gym_routine_planner/models/routine_exercise.dart';
import 'package:gym_routine_planner/widgets/dissmissible_bg.dart';
import 'package:gym_routine_planner/widgets/exercise_card.dart';
import 'package:gym_routine_planner/screens/login_screen.dart';
import 'package:gym_routine_planner/models/language_data.dart';
import 'package:gym_routine_planner/models/routine_day.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _appBarTitle = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<RoutineDay> _routineDays = [];
  final List<RoutineExercise> _viewingExercises = [];
  int _viewingDayIndex = 0;
  final List<RoutineExercise> _userExercises = [];

  bool _loading = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _routineDayNameController =
      TextEditingController();

  RoutineExercise? _selectedExercise;

  signOut() {
    _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void initData() async {
    try {
      setState(() {
        _loading = true;
      });

      _routineDays.clear();
      _viewingExercises.clear();
      _userExercises.clear();

      final exercisesQuerySnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('exercises')
          .get();

      for (final doc in exercisesQuerySnapshot.docs) {
        final data = doc.data();

        _userExercises.add(RoutineExercise(
          id: doc.id,
          name: data['name'],
          minutes: data['minutes'],
          sets: data['sets'],
          reps: data['reps'],
          machine: data['machine'],
        ));
      }

      final daysQuerySnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('routines')
          .orderBy('dayIndex')
          .get();

      if (daysQuerySnapshot.docs.isEmpty) {
        if (!mounted) return;
        for (var i = 0; i <= 8; i++) {
          RoutineDay routineDay = RoutineDay(
            name: Languages.of(context)!.routine,
            dayIndex: i,
            exercises: [],
          );

          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('routines')
              .add({
            'name': routineDay.name,
            'dayIndex': routineDay.dayIndex,
            'exercises': [],
          });

          _routineDays.add(routineDay);
        }
      } else {
        for (final doc in daysQuerySnapshot.docs) {
          final data = doc.data();

          _routineDays.add(RoutineDay(
            id: doc.id,
            name: data['name'],
            dayIndex: data['dayIndex'],
            exercises:
                (data['exercises'] as List<dynamic>).map<RoutineExercise>(
              (exercise) {
                return RoutineExercise(
                  name: exercise['name'],
                  minutes: exercise['minutes'],
                  sets: exercise['sets'],
                  reps: exercise['reps'],
                  machine: exercise['machine'],
                );
              },
            ).toList(),
          ));
        }
      }

      final DateTime now = DateTime.now();
      final int weekday = now.weekday;

      if (!mounted) return;

      switch (weekday) {
        case 1:
          _appBarTitle = Languages.of(context)!.monday;
          break;
        case 2:
          _appBarTitle = Languages.of(context)!.tuesday;
          break;
        case 3:
          _appBarTitle = Languages.of(context)!.wednesday;
          break;
        case 4:
          _appBarTitle = Languages.of(context)!.thursday;
          break;
        case 5:
          _appBarTitle = Languages.of(context)!.friday;
          break;
        case 6:
          _appBarTitle = Languages.of(context)!.saturday;
          break;
        case 7:
          _appBarTitle = Languages.of(context)!.sunday;
          break;
      }

      _viewingDayIndex = weekday - 1;
      _viewingExercises.addAll(_routineDays[_viewingDayIndex].exercises);

      setState(() {
        _loading = false;
      });
    } catch (e) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    }
  }

  void addRoutineExercise(RoutineExercise routineExercise) async {
    setState(() {
      _loading = true;
    });
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('routines')
        .doc(_routineDays[_viewingDayIndex].id)
        .update({
      'exercises': FieldValue.arrayUnion([
        {
          'id': routineExercise.id,
          'name': routineExercise.name,
          'minutes': routineExercise.minutes,
          'sets': routineExercise.sets,
          'reps': routineExercise.reps,
          'machine': routineExercise.machine,
        }
      ])
    });

    setState(() {
      _viewingExercises.add(routineExercise);
      _loading = false;
    });
  }

  void removeRoutineExercise(RoutineExercise routineExercise) async {
    setState(() {
      _loading = true;
    });
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('routines')
        .doc(_routineDays[_viewingDayIndex].id)
        .update({
      'exercises': FieldValue.arrayRemove([
        {
          'name': routineExercise.name,
          'minutes': routineExercise.minutes,
          'sets': routineExercise.sets,
          'reps': routineExercise.reps,
          'machine': routineExercise.machine,
        }
      ])
    });

    setState(() {
      _viewingExercises.remove(routineExercise);
      _loading = false;
    });
  }

  void showAddRoutineExerciseDialog() {
    _selectedExercise = _userExercises.isNotEmpty ? _userExercises[0] : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Languages.of(context)!.addExercise),
          content: Form(
            key: _formKey,
            child: DropdownButtonFormField<RoutineExercise>(
              value: _selectedExercise,
              items: _userExercises.map(
                (exercise) {
                  return DropdownMenuItem<RoutineExercise>(
                    value: exercise,
                    child: Text(exercise.name),
                  );
                },
              ).toList(),
              validator: (value) {
                if (value == null) {
                  return Languages.of(context)!.pleaseSelectExercise;
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _selectedExercise = value;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(Languages.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  addRoutineExercise(_selectedExercise!);
                  Navigator.of(context).pop();
                }
              },
              child: Text(Languages.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  void updateRoutineDayName(String newName) async {
    setState(() {
      _loading = true;
    });
    _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('routines')
        .doc(_routineDays[_viewingDayIndex].id)
        .update({'name': newName});
    setState(() {
      _routineDays[_viewingDayIndex].name = newName;
      _loading = false;
    });
  }

  void showEditRoutineDayNameDialog() {
    _routineDayNameController.text = _routineDays[_viewingDayIndex].name;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Languages.of(context)!.editRoutineName),
          content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _routineDayNameController,
                decoration: InputDecoration(
                  labelText: Languages.of(context)!.nameField,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Languages.of(context)!.nameErrorMessage;
                  }
                  return null;
                },
              )),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(Languages.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  updateRoutineDayName(_routineDayNameController.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text(Languages.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  void showChangeLanguageDialog() async {
    if (!mounted) return;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(Languages.of(context)!.changeLanguage),
            content: DropdownButton<LanguageData>(
              iconSize: 30,
              hint: Text(Languages.of(context)!.changeLanguage),
              onChanged: (language) {
                changeLanguage(context, language!.languageCode);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              items: LanguageData.languageList()
                  .map<DropdownMenuItem<LanguageData>>(
                    (e) => DropdownMenuItem<LanguageData>(
                      value: e,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Text(
                            e.flag,
                            style: const TextStyle(fontSize: 30),
                          ),
                          Text(e.name)
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(Languages.of(context)!.cancel),
              ),
            ],
          );
        });
  }

  void updateViewingExercises(List<RoutineExercise> exercises) {
    _viewingExercises.clear();
    _viewingExercises.addAll(exercises);
  }

  ListTile buildDrawerListTile(BuildContext context, String title, int index) {
    return ListTile(
      title: Text(title),
      onTap: () {
        setState(() {
          _viewingDayIndex = index;
          updateViewingExercises(_routineDays[_viewingDayIndex].exercises);
          _appBarTitle = title;
        });
        Navigator.of(context).pop();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  void dispose() {
    _routineDayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: [
          PopupMenuButton(itemBuilder: (context) {
            return [
              PopupMenuItem(
                child: TextButton(
                  onPressed: () {
                    showEditRoutineDayNameDialog();
                  },
                  child: Text(Languages.of(context)!.editRoutineName),
                ),
              ),
              PopupMenuItem(
                child: TextButton(
                  child: Text(Languages.of(context)!.changeLanguage),
                  onPressed: () {
                    showChangeLanguageDialog();
                  },
                ),
              ),
              PopupMenuItem(
                child: TextButton(
                  child: Text(Languages.of(context)!.refresh),
                  onPressed: () {
                    initData();
                  },
                ),
              ),
              PopupMenuItem(
                child: TextButton(
                  onPressed: () {
                    signOut();
                  },
                  child: Text(Languages.of(context)!.logout),
                ),
              ),
            ];
          }),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    _routineDays[_viewingDayIndex].name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _viewingExercises.isNotEmpty
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: _viewingExercises.length,
                          itemBuilder: (context, index) {
                            final exercise = _viewingExercises[index];
                            return Dismissible(
                              key: UniqueKey(),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                removeRoutineExercise(exercise);
                              },
                              background: const DissmissBackground(),
                              child: ExerciseCard(
                                exercise: exercise,
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(Languages.of(context)!.noExercisesText),
                      )
              ],
            ),
      floatingActionButton: !_loading
          ? FloatingActionButton(
              onPressed: () {
                showAddRoutineExerciseDialog();
              },
              child: const Icon(Icons.add),
            )
          : null,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                Languages.of(context)!.routines,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            buildDrawerListTile(context, Languages.of(context)!.monday, 0),
            buildDrawerListTile(context, Languages.of(context)!.tuesday, 1),
            buildDrawerListTile(context, Languages.of(context)!.wednesday, 2),
            buildDrawerListTile(context, Languages.of(context)!.thursday, 3),
            buildDrawerListTile(context, Languages.of(context)!.friday, 4),
            buildDrawerListTile(context, Languages.of(context)!.saturday, 5),
            buildDrawerListTile(context, Languages.of(context)!.sunday, 6),
            const Divider(),
            ListTile(
              title: Text(Languages.of(context)!.exercises),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ExercisesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

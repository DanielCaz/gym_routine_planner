import 'package:gym_routine_planner/Localization/locale_constant.dart';
import 'package:gym_routine_planner/Localization/global_strings.dart';
import 'package:gym_routine_planner/models/routine_excercise.dart';
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
  String appBarTitle = '';

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<RoutineDay> routineDays = [];
  int viewingDayIndex = 0;
  List<RoutineExcercise> viewingexcercises = [];

  bool loading = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _excerciseNameController =
      TextEditingController();
  final TextEditingController _excerciseMinutesController =
      TextEditingController();
  final TextEditingController _excerciseSetsController =
      TextEditingController();
  final TextEditingController _excerciseRepsController =
      TextEditingController();
  final TextEditingController _excerciseMachineController =
      TextEditingController();
  final TextEditingController _routineDayNameController =
      TextEditingController();

  signOut() {
    auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  getRoutineDays() async {
    try {
      final routineDaysRef = firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .collection('routines');

      final querySnapshot = await routineDaysRef.orderBy('day').get();

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        final List<RoutineDay> routineDays = [
          RoutineDay(
              name: Languages.of(context)!.routine,
              dayIndex: 0,
              excercises: []),
          RoutineDay(
              name: Languages.of(context)!.routine,
              dayIndex: 1,
              excercises: []),
          RoutineDay(
              name: Languages.of(context)!.routine,
              dayIndex: 2,
              excercises: []),
          RoutineDay(
              name: Languages.of(context)!.routine,
              dayIndex: 3,
              excercises: []),
          RoutineDay(
              name: Languages.of(context)!.routine,
              dayIndex: 4,
              excercises: []),
          RoutineDay(
              name: Languages.of(context)!.routine,
              dayIndex: 5,
              excercises: []),
          RoutineDay(
              name: Languages.of(context)!.routine,
              dayIndex: 6,
              excercises: []),
        ];

        for (final routineDay in routineDays) {
          await routineDaysRef.add({
            'name': routineDay.name,
            'dayIndex': routineDay.dayIndex,
            'excercises': routineDay.excercises,
          });
        }

        setState(() {
          this.routineDays = routineDays;
          viewingexcercises = routineDays[0].excercises;
          appBarTitle = Languages.of(context)!.monday;
          loading = false;
        });
      } else {
        final List<RoutineDay> routineDays = [];
        for (final doc in querySnapshot.docs) {
          final data = doc.data();

          routineDays.add(RoutineDay(
            id: doc.id,
            name: data['name'],
            dayIndex: data['dayIndex'],
            excercises:
                (data['excercises'] as List<dynamic>).map<RoutineExcercise>(
              (excercise) {
                return RoutineExcercise(
                  name: excercise['name'],
                  minutes: excercise['minutes'],
                  sets: excercise['sets'],
                  reps: excercise['reps'],
                  machine: excercise['machine'],
                );
              },
            ).toList(),
          ));
        }

        routineDays.sort((a, b) => a.dayIndex - b.dayIndex);

        setState(() {
          this.routineDays = routineDays;
          viewingexcercises = routineDays[0].excercises;
          appBarTitle = Languages.of(context)!.monday;
          loading = false;
        });
      }
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

  addRoutineExcercise(RoutineExcercise routineExcercise) async {
    setState(() {
      loading = true;
    });
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('routines')
        .doc(routineDays[viewingDayIndex].id)
        .update({
      'excercises': FieldValue.arrayUnion([
        {
          'name': routineExcercise.name,
          'minutes': routineExcercise.minutes,
          'sets': routineExcercise.sets,
          'reps': routineExcercise.reps,
          'machine': routineExcercise.machine,
        }
      ])
    });

    setState(() {
      viewingexcercises.add(routineExcercise);
      loading = false;
    });
  }

  removeRoutineExcercise(RoutineExcercise routineExcercise) async {
    setState(() {
      loading = true;
    });
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('routines')
        .doc(routineDays[viewingDayIndex].id)
        .update({
      'excercises': FieldValue.arrayRemove([
        {
          'name': routineExcercise.name,
          'minutes': routineExcercise.minutes,
          'sets': routineExcercise.sets,
          'reps': routineExcercise.reps,
          'machine': routineExcercise.machine,
        }
      ])
    });

    setState(() {
      viewingexcercises.remove(routineExcercise);
      loading = false;
    });
  }

  updateRoutineExcercise() async {
    setState(() {
      loading = true;
    });
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('routines')
        .doc(routineDays[viewingDayIndex].id)
        .update({
      'excercises': viewingexcercises.map((excercise) {
        return {
          'name': excercise.name,
          'minutes': excercise.minutes,
          'sets': excercise.sets,
          'reps': excercise.reps,
          'machine': excercise.machine,
        };
      }).toList(),
    });
    setState(() {
      loading = false;
    });
  }

  showAddRoutineExcerciseDialog() {
    _excerciseNameController.clear();
    _excerciseMinutesController.clear();
    _excerciseSetsController.clear();
    _excerciseRepsController.clear();
    _excerciseMachineController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Languages.of(context)!.addExcercise),
          content: buildexcerciseRoutineDialog(),
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
                  addRoutineExcercise(RoutineExcercise(
                    name: _excerciseNameController.text,
                    minutes: _excerciseMinutesController.text.isEmpty
                        ? null
                        : int.parse(_excerciseMinutesController.text),
                    sets: _excerciseSetsController.text.isEmpty
                        ? null
                        : int.parse(_excerciseSetsController.text),
                    reps: _excerciseRepsController.text.isEmpty
                        ? null
                        : int.parse(_excerciseRepsController.text),
                    machine: _excerciseMachineController.text,
                  ));
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

  showEditRoutineExcerciseDialog(RoutineExcercise routineExcercise) {
    _excerciseNameController.text = routineExcercise.name;
    _excerciseMinutesController.text =
        routineExcercise.minutes?.toString() ?? '';
    _excerciseSetsController.text = routineExcercise.sets?.toString() ?? '';
    _excerciseRepsController.text = routineExcercise.reps?.toString() ?? '';
    _excerciseMachineController.text = routineExcercise.machine ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Languages.of(context)!.editExcercise),
          content: buildexcerciseRoutineDialog(),
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
                  routineExcercise.name = _excerciseNameController.text;
                  routineExcercise.minutes =
                      _excerciseMinutesController.text.isEmpty
                          ? null
                          : int.parse(_excerciseMinutesController.text);
                  routineExcercise.sets = _excerciseSetsController.text.isEmpty
                      ? null
                      : int.parse(_excerciseSetsController.text);
                  routineExcercise.reps = _excerciseRepsController.text.isEmpty
                      ? null
                      : int.parse(_excerciseRepsController.text);
                  routineExcercise.machine = _excerciseMachineController.text;

                  updateRoutineExcercise();
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

  Form buildexcerciseRoutineDialog() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _excerciseNameController,
              decoration: InputDecoration(
                labelText: Languages.of(context)!.nameField,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return Languages.of(context)!.nameErrorMessage;
                }
                return null;
              },
            ),
            TextFormField(
              controller: _excerciseMinutesController,
              decoration: InputDecoration(
                labelText: Languages.of(context)!.minutesField,
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (_excerciseSetsController.text.isNotEmpty ||
                      _excerciseRepsController.text.isNotEmpty) {
                    return Languages.of(context)!.minutesErrorMessage;
                  }
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _excerciseSetsController,
              decoration: InputDecoration(
                labelText: Languages.of(context)!.setsField,
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (_excerciseMinutesController.text.isNotEmpty) {
                    return Languages.of(context)!.setsErrorMessageMins;
                  }
                } else {
                  if (_excerciseRepsController.text.isNotEmpty) {
                    return Languages.of(context)!.setsErrorMessageReps;
                  }
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _excerciseRepsController,
              decoration: InputDecoration(
                labelText: Languages.of(context)!.repsField,
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (_excerciseMinutesController.text.isNotEmpty) {
                    return Languages.of(context)!.repsErrorMessageMins;
                  }
                } else {
                  if (_excerciseSetsController.text.isNotEmpty) {
                    return Languages.of(context)!.repsErrorMessageSets;
                  }
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _excerciseMachineController,
              decoration: InputDecoration(
                labelText: Languages.of(context)!.machineField,
              ),
            ),
          ],
        ),
      ),
    );
  }

  updateRoutineDayName(String newName) async {
    setState(() {
      loading = true;
    });
    firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('routines')
        .doc(routineDays[viewingDayIndex].id)
        .update({'name': newName});
    setState(() {
      routineDays[viewingDayIndex].name = newName;
      loading = false;
    });
  }

  showEditRoutineDayNameDialog() {
    _routineDayNameController.text = routineDays[viewingDayIndex].name;

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

  showChangeLanguageDialog() async {
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

  @override
  void initState() {
    super.initState();
    getRoutineDays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
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
      body: !loading
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    routineDays[viewingDayIndex].name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                viewingexcercises.isNotEmpty
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: viewingexcercises.length,
                          itemBuilder: (context, index) {
                            final excercise = viewingexcercises[index];
                            return Dismissible(
                              key: UniqueKey(),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                removeRoutineExcercise(excercise);
                              },
                              background: Container(
                                color: Colors.red,
                                child: const Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 16.0),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 4.0),
                                child: Card(
                                  elevation: 2,
                                  child: ListTile(
                                    title: Text(excercise.name),
                                    subtitle: Text(excercise.minutes == null
                                        ? '${excercise.sets} sets x ${excercise.reps} reps${excercise.machine?.isNotEmpty ?? false ? '\n${Languages.of(context)!.on} ${excercise.machine}' : ''}'
                                        : '${excercise.minutes} ${Languages.of(context)!.minutes}${excercise.machine?.isNotEmpty ?? false ? '\n${Languages.of(context)!.on} ${excercise.machine}' : ''}'),
                                    trailing: IconButton(
                                      onPressed: () {
                                        showEditRoutineExcerciseDialog(
                                          excercise,
                                        );
                                      },
                                      icon: const Icon(Icons.edit),
                                    ),
                                    isThreeLine:
                                        excercise.machine?.isNotEmpty ?? false,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(Languages.of(context)!.noExcercisesText),
                      )
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
      floatingActionButton: !loading
          ? FloatingActionButton(
              onPressed: () {
                showAddRoutineExcerciseDialog();
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
          ListTile(
            title: Text(Languages.of(context)!.monday),
            onTap: () {
              setState(() {
                viewingDayIndex = 0;
                viewingexcercises = routineDays[viewingDayIndex].excercises;
                appBarTitle = Languages.of(context)!.monday;
              });
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: Text(Languages.of(context)!.tuesday),
            onTap: () {
              setState(() {
                viewingDayIndex = 1;
                viewingexcercises = routineDays[viewingDayIndex].excercises;
                appBarTitle = Languages.of(context)!.tuesday;
              });
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: Text(Languages.of(context)!.wednesday),
            onTap: () {
              setState(() {
                viewingDayIndex = 2;
                viewingexcercises = routineDays[viewingDayIndex].excercises;
                appBarTitle = Languages.of(context)!.wednesday;
              });
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: Text(Languages.of(context)!.thursday),
            onTap: () {
              setState(() {
                viewingDayIndex = 3;
                viewingexcercises = routineDays[viewingDayIndex].excercises;
                appBarTitle = Languages.of(context)!.thursday;
              });
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: Text(Languages.of(context)!.friday),
            onTap: () {
              setState(() {
                viewingDayIndex = 4;
                viewingexcercises = routineDays[viewingDayIndex].excercises;
                appBarTitle = Languages.of(context)!.friday;
              });
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: Text(Languages.of(context)!.saturday),
            onTap: () {
              setState(() {
                viewingDayIndex = 5;
                viewingexcercises = routineDays[viewingDayIndex].excercises;
                appBarTitle = Languages.of(context)!.saturday;
              });
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: Text(Languages.of(context)!.sunday),
            onTap: () {
              setState(() {
                viewingDayIndex = 6;
                viewingexcercises = routineDays[viewingDayIndex].excercises;
                appBarTitle = Languages.of(context)!.sunday;
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      )),
    );
  }
}

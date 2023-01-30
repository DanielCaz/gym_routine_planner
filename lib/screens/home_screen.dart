import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_routine_planner/classes/routine_day.dart';
import 'package:gym_routine_planner/classes/routine_excersize.dart';
import 'package:gym_routine_planner/screens/login_screen.dart';
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
  List<RoutineExcersize> viewingExcersizes = [];

  bool loading = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _excersizeNameController =
      TextEditingController();
  final TextEditingController _excersizeMinutesController =
      TextEditingController();
  final TextEditingController _excersizeSetsController =
      TextEditingController();
  final TextEditingController _excersizeRepsController =
      TextEditingController();
  final TextEditingController _excersizeMachineController =
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
    final routineDaysRef = firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('routines');

    final querySnapshot = await routineDaysRef.orderBy('day').get();

    if (querySnapshot.docs.isEmpty) {
      final List<RoutineDay> routineDays = [
        RoutineDay(day: 'Lunes', name: 'Rutina', dayIndex: 0, excersizes: []),
        RoutineDay(day: 'Martes', name: 'Rutina', dayIndex: 1, excersizes: []),
        RoutineDay(
            day: 'Miercoles', name: 'Rutina', dayIndex: 2, excersizes: []),
        RoutineDay(day: 'Jueves', name: 'Rutina', dayIndex: 3, excersizes: []),
        RoutineDay(day: 'Viernes', name: 'Rutina', dayIndex: 4, excersizes: []),
        RoutineDay(day: 'Sabado', name: 'Rutina', dayIndex: 5, excersizes: []),
        RoutineDay(day: 'Domingo', name: 'Rutina', dayIndex: 6, excersizes: []),
      ];

      for (final routineDay in routineDays) {
        await routineDaysRef.add({
          'day': routineDay.day,
          'name': routineDay.name,
          'dayIndex': routineDay.dayIndex,
          'excersizes': routineDay.excersizes,
        });
      }

      setState(() {
        this.routineDays = routineDays;
        viewingExcersizes = routineDays[0].excersizes;
        appBarTitle = routineDays[0].name;
        loading = false;
      });
    } else {
      final List<RoutineDay> routineDays = [];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        routineDays.add(RoutineDay(
          id: doc.id,
          day: data['day'],
          name: data['name'],
          dayIndex: data['dayIndex'],
          excersizes: (data['excersizes'] as List<dynamic>)
              .map((excersize) => RoutineExcersize(
                    name: excersize['name'],
                    minutes: excersize['minutes'],
                    sets: excersize['sets'],
                    reps: excersize['reps'],
                    machine: excersize['machine'],
                  ))
              .toList(),
        ));
      }

      routineDays.sort((a, b) => a.dayIndex - b.dayIndex);

      setState(() {
        this.routineDays = routineDays;
        viewingExcersizes = routineDays[0].excersizes;
        appBarTitle = routineDays[0].name;
        loading = false;
      });
    }
  }

  addRoutineExcersize(RoutineExcersize routineExcersize) async {
    setState(() {
      loading = true;
    });
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('routines')
        .doc(routineDays[viewingDayIndex].id)
        .update({
      'excersizes': FieldValue.arrayUnion([
        {
          'name': routineExcersize.name,
          'minutes': routineExcersize.minutes,
          'sets': routineExcersize.sets,
          'reps': routineExcersize.reps,
          'machine': routineExcersize.machine,
        }
      ])
    });

    setState(() {
      viewingExcersizes.add(routineExcersize);
      loading = false;
    });
  }

  removeRoutineExcersize(RoutineExcersize routineExcersize) async {
    setState(() {
      loading = true;
    });
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('routines')
        .doc(routineDays[viewingDayIndex].id)
        .update({
      'excersizes': FieldValue.arrayRemove([
        {
          'name': routineExcersize.name,
          'minutes': routineExcersize.minutes,
          'sets': routineExcersize.sets,
          'reps': routineExcersize.reps,
          'machine': routineExcersize.machine,
        }
      ])
    });

    setState(() {
      viewingExcersizes.remove(routineExcersize);
      loading = false;
    });
  }

  updateRoutineExcersize() async {
    setState(() {
      loading = true;
    });
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('routines')
        .doc(routineDays[viewingDayIndex].id)
        .update({
      'excersizes': viewingExcersizes.map((excersize) {
        return {
          'name': excersize.name,
          'minutes': excersize.minutes,
          'sets': excersize.sets,
          'reps': excersize.reps,
          'machine': excersize.machine,
        };
      }).toList(),
    });
    setState(() {
      loading = false;
    });
  }

  showAddRoutineExcersizeDialog() {
    _excersizeNameController.clear();
    _excersizeMinutesController.clear();
    _excersizeSetsController.clear();
    _excersizeRepsController.clear();
    _excersizeMachineController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar ejercicio'),
          content: buildExcersizeRoutineDialog(),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  addRoutineExcersize(RoutineExcersize(
                    name: _excersizeNameController.text,
                    minutes: _excersizeMinutesController.text.isEmpty
                        ? null
                        : int.parse(_excersizeMinutesController.text),
                    sets: _excersizeSetsController.text.isEmpty
                        ? null
                        : int.parse(_excersizeSetsController.text),
                    reps: _excersizeRepsController.text.isEmpty
                        ? null
                        : int.parse(_excersizeRepsController.text),
                    machine: _excersizeMachineController.text,
                  ));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  showEditRoutineExcersizeDialog(RoutineExcersize routineExcersize) {
    _excersizeNameController.text = routineExcersize.name;
    _excersizeMinutesController.text =
        routineExcersize.minutes?.toString() ?? '';
    _excersizeSetsController.text = routineExcersize.sets?.toString() ?? '';
    _excersizeRepsController.text = routineExcersize.reps?.toString() ?? '';
    _excersizeMachineController.text = routineExcersize.machine ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar ejercicio'),
          content: buildExcersizeRoutineDialog(),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  routineExcersize.name = _excersizeNameController.text;
                  routineExcersize.minutes =
                      _excersizeMinutesController.text.isEmpty
                          ? null
                          : int.parse(_excersizeMinutesController.text);
                  routineExcersize.sets = _excersizeSetsController.text.isEmpty
                      ? null
                      : int.parse(_excersizeSetsController.text);
                  routineExcersize.reps = _excersizeRepsController.text.isEmpty
                      ? null
                      : int.parse(_excersizeRepsController.text);
                  routineExcersize.machine = _excersizeMachineController.text;

                  updateRoutineExcersize();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Editar'),
            ),
          ],
        );
      },
    );
  }

  Form buildExcersizeRoutineDialog() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _excersizeNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre*',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un nombre';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _excersizeMinutesController,
              decoration: const InputDecoration(
                labelText: 'Minutos',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (_excersizeSetsController.text.isNotEmpty ||
                      _excersizeRepsController.text.isNotEmpty) {
                    return 'No puede ingresar minutos y sets/reps a la vez';
                  }
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _excersizeSetsController,
              decoration: const InputDecoration(
                labelText: 'Sets',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (_excersizeMinutesController.text.isNotEmpty) {
                    return 'No puede ingresar minutos y sets/reps a la vez';
                  }
                } else {
                  if (_excersizeRepsController.text.isNotEmpty) {
                    return 'Le falta ingresar sets para sus reps';
                  }
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _excersizeRepsController,
              decoration: const InputDecoration(
                labelText: 'Reps',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (_excersizeMinutesController.text.isNotEmpty) {
                    return 'No puede ingresar minutos y sets/reps a la vez';
                  }
                } else {
                  if (_excersizeSetsController.text.isNotEmpty) {
                    return 'Le falta ingresar reps para sus sets';
                  }
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _excersizeMachineController,
              decoration: const InputDecoration(
                labelText: 'Máquina',
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
          title: const Text('Editar nombre de la rutina'),
          content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _routineDayNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              )),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  updateRoutineDayName(_routineDayNameController.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Editar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    try {
      getRoutineDays();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    }
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
                    signOut();
                  },
                  child: const Text('Cerrar sesión'),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        routineDays[viewingDayIndex].name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showEditRoutineDayNameDialog();
                        },
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                ),
                viewingExcersizes.isNotEmpty
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: viewingExcersizes.length,
                          itemBuilder: (context, index) {
                            final excersize = viewingExcersizes[index];
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                elevation: 2,
                                child: ListTile(
                                  title: Text(excersize.name),
                                  subtitle: Text(excersize.minutes == null
                                      ? '${excersize.sets} sets x ${excersize.reps} reps${excersize.machine?.isNotEmpty ?? false ? '\nEn ${excersize.machine}' : ''}'
                                      : '${excersize.minutes} minutos${excersize.machine?.isNotEmpty ?? false ? '\nEn ${excersize.machine}' : ''}'),
                                  trailing: IconButton(
                                    onPressed: () {
                                      removeRoutineExcersize(excersize);
                                    },
                                    icon: const Icon(Icons.delete),
                                  ),
                                  onLongPress: () {
                                    showEditRoutineExcersizeDialog(excersize);
                                  },
                                  isThreeLine:
                                      excersize.machine?.isNotEmpty ?? false,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Text('No hay ejercicios en este día'),
                      )
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
      floatingActionButton: !loading
          ? FloatingActionButton(
              onPressed: () {
                showAddRoutineExcersizeDialog();
              },
              child: const Icon(Icons.add),
            )
          : null,
      drawer: Drawer(
          child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Rutinas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...routineDays.map((routineDay) {
            return ListTile(
              title: Text(routineDay.day),
              onTap: () {
                setState(() {
                  viewingDayIndex = routineDay.dayIndex;
                  viewingExcersizes = routineDay.excersizes;
                  appBarTitle = routineDay.day;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ],
      )),
    );
  }
}

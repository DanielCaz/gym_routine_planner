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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<RoutineDay> routineDays = [];
  int viewingDayIndex = 0;
  List<RoutineExcersize> viewingExcersizes = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _excersizeNameController =
      TextEditingController();
  final TextEditingController _excersizeMinutesController =
      TextEditingController();
  final TextEditingController _excersizeSetsController =
      TextEditingController();
  final TextEditingController _excersizeRepsController =
      TextEditingController();

  signOut() {
    _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  getRoutineDays() async {
    final routineDaysRef = _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('routines');

    final querySnapshot = await routineDaysRef.orderBy('day').get();

    if (querySnapshot.docs.isEmpty) {
      final List<RoutineDay> routineDays = [
        RoutineDay(day: 'Lunes', dayIndex: 0, excersizes: []),
        RoutineDay(day: 'Martes', dayIndex: 1, excersizes: []),
        RoutineDay(day: 'Miercoles', dayIndex: 2, excersizes: []),
        RoutineDay(day: 'Jueves', dayIndex: 3, excersizes: []),
        RoutineDay(day: 'Viernes', dayIndex: 4, excersizes: []),
        RoutineDay(day: 'Sabado', dayIndex: 5, excersizes: []),
        RoutineDay(day: 'Domingo', dayIndex: 6, excersizes: []),
      ];

      for (final routineDay in routineDays) {
        await routineDaysRef.add({
          'day': routineDay.day,
          'dayIndex': routineDay.dayIndex,
          'excersizes': routineDay.excersizes,
        });
      }

      setState(() {
        this.routineDays = routineDays;
        viewingExcersizes = routineDays[0].excersizes;
      });
    } else {
      final List<RoutineDay> routineDays = [];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        routineDays.add(RoutineDay(
          id: doc.id,
          day: data['day'],
          dayIndex: data['dayIndex'],
          excersizes: (data['excersizes'] as List<dynamic>)
              .map((excersize) => RoutineExcersize(
                    name: excersize['name'],
                    minutes: excersize['minutes'],
                    sets: excersize['sets'],
                    reps: excersize['reps'],
                  ))
              .toList(),
        ));
      }

      routineDays.sort((a, b) => a.dayIndex - b.dayIndex);

      setState(() {
        this.routineDays = routineDays;
        viewingExcersizes = routineDays[0].excersizes;
      });
    }
  }

  addRoutineExcersize(RoutineExcersize routineExcersize) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('routines')
        .doc(routineDays[viewingDayIndex].id)
        .update({
      'excersizes': FieldValue.arrayUnion([
        {
          'name': routineExcersize.name,
          'minutes': routineExcersize.minutes,
          'sets': routineExcersize.sets,
          'reps': routineExcersize.reps,
        }
      ])
    });

    setState(() {
      viewingExcersizes.add(routineExcersize);
    });
  }

  removeRoutineExcersize(RoutineExcersize routineExcersize) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('routines')
        .doc(routineDays[viewingDayIndex].id)
        .update({
      'excersizes': FieldValue.arrayRemove([
        {
          'name': routineExcersize.name,
          'minutes': routineExcersize.minutes,
          'sets': routineExcersize.sets,
          'reps': routineExcersize.reps,
        }
      ])
    });

    setState(() {
      viewingExcersizes.remove(routineExcersize);
    });
  }

  updateRoutineExcersize() async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('routines')
        .doc(routineDays[viewingDayIndex].id)
        .update({
      'excersizes': viewingExcersizes.map((excersize) {
        return {
          'name': excersize.name,
          'minutes': excersize.minutes,
          'sets': excersize.sets,
          'reps': excersize.reps,
        };
      }).toList(),
    });
  }

  showAddRoutineExcersizeDialog() {
    _excersizeNameController.clear();
    _excersizeMinutesController.clear();
    _excersizeSetsController.clear();
    _excersizeRepsController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar ejercicio'),
          content: Form(
            key: _formKey,
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
                ),
                TextFormField(
                  controller: _excersizeSetsController,
                  decoration: const InputDecoration(
                    labelText: 'Sets',
                  ),
                ),
                TextFormField(
                  controller: _excersizeRepsController,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                  ),
                ),
              ],
            ),
          ),
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar ejercicio'),
          content: Form(
            key: _formKey,
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
                ),
                TextFormField(
                  controller: _excersizeSetsController,
                  decoration: const InputDecoration(
                    labelText: 'Sets',
                  ),
                ),
                TextFormField(
                  controller: _excersizeRepsController,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                  ),
                ),
              ],
            ),
          ),
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

                  updateRoutineExcersize();
                  setState(() {});
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
        title: const Text('Rutina'),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: routineDays.isNotEmpty
                ? DropdownButton(
                    items: routineDays.map((routineDay) {
                      return DropdownMenuItem(
                        value: routineDay.id,
                        child: Text(routineDay.day),
                      );
                    }).toList(),
                    value: routineDays[viewingDayIndex].id,
                    onChanged: (value) {
                      final index = routineDays.indexWhere((element) {
                        return element.id == value;
                      });

                      setState(() {
                        viewingDayIndex = index;
                        viewingExcersizes = routineDays[index].excersizes;
                      });
                    },
                  )
                : const Text('No hay días en la rutina'),
          ),
          const Divider(
            thickness: 1,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: viewingExcersizes.length,
              itemBuilder: (context, index) {
                final excersize = viewingExcersizes[index];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(excersize.name),
                    subtitle: Text(excersize.minutes == null
                        ? '${excersize.sets} sets x ${excersize.reps} reps'
                        : '${excersize.minutes} minutos'),
                    trailing: IconButton(
                      onPressed: () {
                        removeRoutineExcersize(excersize);
                      },
                      icon: const Icon(Icons.delete),
                    ),
                    onLongPress: () {
                      showEditRoutineExcersizeDialog(excersize);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddRoutineExcersizeDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

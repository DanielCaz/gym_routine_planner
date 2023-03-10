import 'package:flutter/material.dart';

abstract class Languages {
  static Languages? of(BuildContext context) {
    return Localizations.of<Languages>(context, Languages);
  }

  String get appName;

  String get loginScreenSubtitle;
  String get loginScreenLoginButton;

  String get monday;
  String get tuesday;
  String get wednesday;
  String get thursday;
  String get friday;
  String get saturday;
  String get sunday;
  String get routine;
  String get addExercise;
  String get cancel;
  String get save;
  String get editExercise;
  String get nameField;
  String get nameErrorMessage;
  String get minutesField;
  String get minutesErrorMessage;
  String get setsField;
  String get setsErrorMessageMins;
  String get setsErrorMessageReps;
  String get repsField;
  String get repsErrorMessageMins;
  String get repsErrorMessageSets;
  String get machineField;
  String get editRoutineName;
  String get editRoutineNameErrorMessage;
  String get logout;
  String get minutes;
  String get on;
  String get noExercisesText;
  String get routines;
  String get changeLanguage;
  String get english;
  String get spanish;
  String get exercises;
  String get pleaseSelectExercise;
  String get refresh;
}

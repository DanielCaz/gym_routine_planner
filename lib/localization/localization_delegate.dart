import 'package:flutter/material.dart';

import 'en_strings.dart';
import 'es_strings.dart';
import 'global_strings.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<Languages> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<Languages> load(Locale locale) => _load(locale);

  static Future<Languages> _load(Locale locale) async {
    switch (locale.languageCode) {
      case 'es':
        return LanguageES();
      default:
        return LanguageEN();
    }
  }

  @override
  bool shouldReload(LocalizationsDelegate<Languages> old) => false;
}

class LanguageData {
  final String flag;
  final String name;
  final String languageCode;

  LanguageData(this.flag, this.name, this.languageCode);

  static List<LanguageData> languageList() {
    return <LanguageData>[
      LanguageData("πΊπΈ", "English", 'en'),
      LanguageData("πͺπΈ", "Spanish", 'es'),
    ];
  }
}

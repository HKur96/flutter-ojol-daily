enum ObligationDefinitionType {
  harian,
  mingguan,
  bulanan;

  String get displayObligation {
    switch (this) {
      case ObligationDefinitionType.harian:
        return 'Harian';
      case ObligationDefinitionType.mingguan:
        return 'Mingguan';
      case ObligationDefinitionType.bulanan:
        return 'Bulanan';
    }
  }

  static ObligationDefinitionType fromString(String name) {
    return ObligationDefinitionType.values.firstWhere((e) => e.name == name);
  }
}

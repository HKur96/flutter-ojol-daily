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

enum DailyType { income, expense }

enum IncomeSource {
  gojek,
  grab,
  maxim,
  shopeefood,
  lalamove,
  bluebird,
  tips,
  other;

  String get displayIncomeSource {
    switch (this) {
      case IncomeSource.gojek:
        return 'Gojek';
      case IncomeSource.grab:
        return 'Grab';
      case IncomeSource.maxim:
        return 'Maxim';
      case IncomeSource.shopeefood:
        return 'ShopeeFood';
      case IncomeSource.lalamove:
        return 'Lalamove';
      case IncomeSource.bluebird:
        return 'Bluebird';
      case IncomeSource.tips:
        return 'Tips';
      case IncomeSource.other:
        return 'Lainnya';
    }
  }
}

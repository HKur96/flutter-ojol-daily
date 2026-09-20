import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _full = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Full format: Rp4.250.000
  static String format(num amount) => _full.format(amount);

  /// Abbreviated format: Rp4,25 jt / Rp680 rb
  static String abbreviated(num amount) {
    if (amount >= 1000000) {
      final jt = amount / 1000000;
      final formatted = jt == jt.roundToDouble()
          ? jt.toInt().toString()
          : jt.toStringAsFixed(2).replaceAll('.', ',');
      return 'Rp$formatted jt';
    } else if (amount >= 1000) {
      final rb = amount / 1000;
      final formatted = rb == rb.roundToDouble()
          ? rb.toInt().toString()
          : rb.toStringAsFixed(1).replaceAll('.', ',');
      return 'Rp$formatted rb';
    }
    return _full.format(amount);
  }

  static NumberFormat get currencyFormat =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
}

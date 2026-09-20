import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullDate = DateFormat('dd MMMM yyyy', 'id_ID');
  static final DateFormat _shortDate = DateFormat('dd MMM', 'id_ID');
  static final DateFormat _dayDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
  static final DateFormat _dayHours = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _month = DateFormat('MMMM yyyy', 'id_ID');

  static String fullDate(DateTime date) => _fullDate.format(date);
  static String shortDate(DateTime date) => _shortDate.format(date);
  static String dayDate(DateTime date) => _dayDate.format(date);
  static String dayHours(DateTime date) =>
      '${_dayHours.format(date)} ${DateTime.now().timeZoneName}';
  static String month(DateTime date) => _month.format(date);

  static DateTime fullDateToDateTime(String date) => _fullDate.parse(date);
  static DateTime shortDateToDateTime(String date) => _shortDate.parse(date);
  static DateTime dayDateToDateTime(String date) => _dayDate.parse(date);
  static DateTime dayHoursToDateTime(String date) => _dayHours.parse(date);

  static String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
}

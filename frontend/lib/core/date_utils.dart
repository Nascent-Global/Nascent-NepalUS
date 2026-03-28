import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static DateTime nowUtc() => DateTime.now().toUtc();

  static String toUtcIso(DateTime value) => value.toUtc().toIso8601String();

  static DateTime fromUtcIso(String value) => DateTime.parse(value).toUtc();

  static String dateKeyUtc(DateTime value) {
    final dt = value.toUtc();
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  static String dateKeyLocal(DateTime value) {
    return DateFormat('yyyy-MM-dd').format(value.toLocal());
  }

  static String todayUtcKey() => dateKeyUtc(DateTime.now().toUtc());

  static DateTime dateKeyToUtcStart(String key) {
    final parsed = DateTime.parse('$key 00:00:00');
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  static String relativeDirection(num current, num previous) {
    if (current > previous) return '↑';
    if (current < previous) return '↓';
    return '→';
  }
}

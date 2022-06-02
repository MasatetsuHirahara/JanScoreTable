import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class MyUtil {
  MyUtil._() {
    throw new AssertionError("private Constructor");
  } // private constructor

  // ignore: non_constant_identifier_names
  static String dayToString(DateTime day) {
    initializeDateFormatting('ja');
    return DateFormat.yMMMd('ja').format(day).toString();
  }
}

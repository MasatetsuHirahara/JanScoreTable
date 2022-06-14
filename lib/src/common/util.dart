import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class MyUtil {
  MyUtil._() {
    throw new AssertionError("private Constructor");
  } // private constructor

  static String dayToString(DateTime day) {
    initializeDateFormatting('ja');
    return DateFormat.yMMMMEEEEd('ja').format(day).toString();
  }

  // 末尾をbaseでroundする
  static int customRound(int src, int base) {
    final srcStr = src.toString();
    final lastStr = srcStr.substring(srcStr.length - 1);
    final last = int.parse(lastStr);

    // 末尾がbase以上なら切り上げ
    if (last >= base) {
      return src - last + 10;
    }
    // 切り捨て
    return src - last;
  }
}

// ある日の集計スコア
import '../common/const.dart';
import 'baseModel.dart';

class DayRecodeModel extends BaseModel {
  DayRecodeModel({this.day});
  DayRecodeModel.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnId] as int;
    day = map[columnDay] as String;
  }

  String day;

  @override
  Map<String, Object> toMap() {
    final map = <String, Object>{columnId: id, columnDay: day};
    return map;
  }
}

class DayRecodeAccessor extends BaseTableAccessor {
  DayRecodeAccessor() {
    tableName = tableDayRecode;
  }
}

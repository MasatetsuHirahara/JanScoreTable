import '../common/const.dart';
import 'baseModel.dart';

class ChipScoreModel extends BaseModel {
  ChipScoreModel({this.drId, this.number, int score}) {
    _score = score;
  }
  ChipScoreModel.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnId] as int;
    drId = map[columnDayRecodeId] as int;
    number = map[columnNumber] as int;
    _score = map[columnScore] == null ? null : map[columnScore] as int;
  }

  int drId;
  int number;
  int _score;

  int get score => _score == null ? 0 : _score;
  String get scoreString => _score == null ? '' : _score.toString();

  set score(int src) {
    _score = src;
  }

  @override
  Map<String, Object> toMap() {
    final map = <String, Object>{
      columnId: id,
      columnDayRecodeId: drId,
      columnNumber: number,
      columnScore: _score
    };
    return map;
  }
}

class ChipScoreAccessor extends BaseTableAccessor {
  ChipScoreAccessor() {
    tableName = tableChipScore;
  }
}

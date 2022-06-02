import '../common/const.dart';
import 'baseModel.dart';

class ScoreModel extends BaseModel {
  ScoreModel({this.drId, this.gameCount, this.number, int score}) {
    _score = score;
  }
  ScoreModel.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnId] as int;
    drId = map[columnDayRecodeId] as int;
    gameCount = map[columnGameCount] as int;
    number = map[columnNumber] as int;
    _score = map[columnScore] == null ? null : map[columnScore] as int;
  }

  int drId;
  int gameCount;
  int number;
  int _score;

  int get score => _score == null ? 0 : _score;
  String get scoreString => _score == null ? '' : _score.toString();

  @override
  Map<String, Object> toMap() {
    final map = <String, Object>{
      columnId: id,
      columnDayRecodeId: drId,
      columnGameCount: gameCount,
      columnNumber: number,
      columnScore: _score
    };
    return map;
  }
}

class ScoreAccessor extends BaseTableAccessor {
  ScoreAccessor() {
    tableName = tableScore;
  }
}

import '../common/const.dart';
import 'baseModel.dart';

class ScoreModel extends BaseModel {
  ScoreModel(
      {int id, this.drId, this.gameCount, this.number, int score, this.rank}) {
    this.id = id;
    _score = score;
  }
  ScoreModel.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnId] as int;
    drId = map[columnDayRecodeId] as int;
    gameCount = map[columnGameCount] as int;
    number = map[columnNumber] as int;
    _score = map.containsKey(columnScore) ? map[columnScore] as int : null;
    rank = map.containsKey(columnRank) ? map[columnRank] as int : 0;
  }

  int drId;
  int gameCount;
  int number;
  int _score;
  int rank;

  int get score => _score == null ? 0 : _score;
  set score(int score) => _score = score;
  String get scoreString => _score == null ? '' : _score.toString();

  @override
  Map<String, Object> toMap() {
    final map = <String, Object>{
      columnId: id,
      columnDayRecodeId: drId,
      columnGameCount: gameCount,
      columnNumber: number,
      columnScore: _score,
      columnRank: rank,
    };
    return map;
  }
}

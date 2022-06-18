import '../common/const.dart';
import 'baseModel.dart';

enum WindType { east, south, west, north, none }

extension WindeTypeExtension on WindType {
  static final numbers = {
    WindType.east: 4,
    WindType.south: 3,
    WindType.west: 2,
    WindType.north: 1,
    WindType.none: 0,
  };
  int get num => numbers[this];
  static WindType fromInt(int target) {
    for (final v in WindType.values) {
      if (target == v.num) {
        return v;
      }
    }
    return WindType.east;
  }

  // 東南西北の順に優先
  int compareTo(WindType to) {
    if (num > to.num) {
      return 1;
    }
    if (num < to.num) {
      return -1;
    }
    return 0;
  }
}

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
    _originScore = map.containsKey(columnOriginScore)
        ? map[columnOriginScore] as int
        : null;
    rank = map.containsKey(columnRank) ? map[columnRank] as int : 0;
    rankRemark =
        map.containsKey(columnRankRemark) ? map[columnRankRemark] as int : 0;
    ko = map.containsKey(columnKo) ? map[columnKo] as int : 0;
    fireBird = map.containsKey(columnFireBird) ? map[columnFireBird] as int : 0;
    wind = map.containsKey(columnWind)
        ? WindeTypeExtension.fromInt(map[columnWind] as int)
        : WindType.none;
  }

  int drId;
  int gameCount;
  int number;
  int _score;
  int _originScore;
  int rank;
  int rankRemark;
  int ko;
  int fireBird;
  WindType wind;

  int get score => _score == null ? 0 : _score;
  set score(int score) => _score = score;
  String get scoreString => _score == null ? '' : _score.toString();
  int get originScore => _originScore == null ? 0 : _originScore;
  set originScore(int score) => _originScore = score;
  String get originScoreString =>
      _originScore == null ? '' : originScore.toString();

  @override
  Map<String, Object> toMap() {
    final map = <String, Object>{
      columnId: id,
      columnDayRecodeId: drId,
      columnGameCount: gameCount,
      columnNumber: number,
      columnScore: _score,
      columnOriginScore: _originScore,
      columnRank: rank,
      columnRankRemark: rankRemark,
      columnKo: ko,
      columnFireBird: fireBird,
      columnWind: wind.num,
    };
    return map;
  }
}

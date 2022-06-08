import 'package:flutter_app/src/accessor/table/baseTableAccessor.dart';
import 'package:flutter_app/src/common/const.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/scoreModel.dart';
import '../dbAccessor.dart';

final scoreAccessor = ChangeNotifierProvider((ref) {
  return ScoreAccessor(ref);
});

class ScoreAccessor extends BaseTableAccessor {
  ScoreAccessor(Ref ref) {
    this.ref = ref;
    tableName = tableScore;
    get();
  }

  @override
  Future<void> get() async {
    final dba = ref.watch(dbAccessor);
    if (dba.isOpen == false) {
      return;
    }

    final list = await dba.get(tableName);

    scoreViewMap = {};
    for (final r in list) {
      final m = ScoreModel.fromMap(r);

      // すでに登場しているならadd。なければ新規
      if (scoreViewMap.containsKey(m.drId)) {
        scoreViewMap[m.drId].addMap(m);
        continue;
      }
      scoreViewMap[m.drId] = DayScore.fromModel(m);
    }

    // 一度でもgetできれば初期化完了
    isInitialized = true;
    notifyListeners();
  }

  bool isInitialized = false;
  Map<int, DayScore> scoreViewMap = {};
  List<ScoreModel> recodeList = [];

  // 列の全削除
  Future<int> deleteNumber(int drId, int number) async {
    if (scoreViewMap.containsKey(drId) == false) {
      return 0;
    }

    final ids = <int>[];
    for (final svm in scoreViewMap[drId].map.values) {
      if (svm.containsKey(number)) {
        ids.add(svm[number].id);
      }
    }

    final dba = ref.watch(dbAccessor);
    final ret = await dba.deleteIds(tableName, ids);

    // 削除が終わったら同期
    get();

    return ret;
  }

  // 指定した列にスコアが存在するか？
  bool isThereScore(int drId, int number) {
    if (scoreViewMap.containsKey(drId) == false) {
      return false;
    }
    for (final svm in scoreViewMap[drId].map.values) {
      if (svm.containsKey(number)) {
        return true;
      }
    }
    return false;
  }
}

// dayRecode単位でのスコアマップ
class DayScore {
  DayScore();
  DayScore.fromModel(ScoreModel m) {
    map = {
      m.gameCount: {m.number: m}
    };
    updateMaxIfNeed(m);
  }

  int maxNumber = -1;
  int maxGameCount = -1;
  Map<int, Map<int, ScoreModel>> map = {}; // [gameCount,[number,score]]

  void updateMaxIfNeed(ScoreModel m) {
    if (m.gameCount == null) {
      print('aaa');
    }
    if (maxGameCount < m.gameCount) {
      maxGameCount = m.gameCount;
    }
    if (maxNumber < m.number) {
      maxNumber = m.number;
    }
  }

  void addMap(ScoreModel m) {
    updateMaxIfNeed(m);

    if (map.containsKey(m.gameCount)) {
      map[m.gameCount][m.number] = m;
      return;
    }
    map[m.gameCount] = {m.number: m};
  }
}

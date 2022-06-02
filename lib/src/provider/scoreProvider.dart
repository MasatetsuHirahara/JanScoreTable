import 'package:flutter/material.dart';
import 'package:flutter_app/src/model/baseModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/scoreModel.dart';
import 'dbProvider.dart';

class DrIdScoreView {
  DrIdScoreView();
  DrIdScoreView.fromModel(ScoreModel m) {
    map = {
      m.gameCount: {m.number: m}
    };
    updateMaxIfNeed(m);
  }

  int maxNumber = -1;
  int maxGameCount = -1;
  Map<int, Map<int, ScoreModel>> map = {};

  void updateMaxIfNeed(ScoreModel m) {
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

final scoreProvider = ChangeNotifierProvider((ref) {
  return ScoreNotifier(ref);
});

class ScoreNotifier extends ChangeNotifier {
  ScoreNotifier(this.ref) {
    get();
  }

  Future<void> get() async {
    final dbp = ref.watch(dbProvider);
    if (dbp.isOpen == false) {
      return;
    }

    final list = await dbp.get(accessor);

    scoreViewMap = {};
    for (final r in list) {
      final m = ScoreModel.fromMap(r);

      // すでに登場しているならadd。なければ新規
      if (scoreViewMap.containsKey(m.drId)) {
        scoreViewMap[m.drId].addMap(m);
        continue;
      }
      scoreViewMap[m.drId] = DrIdScoreView.fromModel(m);
    }

    // 一度でもgetできれば初期化完了
    isInitialized = true;
    notifyListeners();
  }

  Ref ref;
  bool isInitialized = false;
  BaseTableAccessor accessor = ScoreAccessor();
  Map<int, DrIdScoreView> scoreViewMap = {};
  List<ScoreModel> recodeList = [];

  Future<int> insert(BaseModel bm) async {
    final dbModel = ref.read(dbProvider);
    await dbModel.insert(accessor, bm);
    await get();
    notifyListeners();
  }

  Future<int> upsert(BaseModel bm) async {
    final dbModel = ref.read(dbProvider);
    await dbModel.upsert(accessor, bm);
    await get();
    notifyListeners();
  }

  Future<void> update(BaseModel bm) async {
    final dbModel = ref.read(dbProvider);
    await dbModel.update(accessor, bm);
    await get();
    notifyListeners();
  }

  Future<void> delete(BaseModel bm) async {
    final dbp = ref.watch(dbProvider);
    final ret = await dbp.delete(accessor, bm);

    // 削除が終わったら同期
    get();
  }

  // 列の全削除
  Future<void> deleteNumber(int drId, int number) async {
    if (scoreViewMap.containsKey(drId) == false) {
      return;
    }

    final ids = <int>[];
    for (final svm in scoreViewMap[drId].map.values) {
      if (svm.containsKey(number)) {
        ids.add(svm[number].id);
      }
    }

    final dbp = ref.watch(dbProvider);
    final ret = await dbp.deleteIds(accessor, ids);

    // 削除が終わったら同期
    get();
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

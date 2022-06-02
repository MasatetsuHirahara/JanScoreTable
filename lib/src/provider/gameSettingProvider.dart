import 'package:flutter/material.dart';
import 'package:flutter_app/src/model/baseModel.dart';
import 'package:flutter_app/src/model/gameSettingModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dbProvider.dart';

final gameSettingProvider = ChangeNotifierProvider((ref) {
  return GameSettingNotifier(ref);
});

class GameSettingNotifier extends ChangeNotifier {
  GameSettingNotifier(this.ref) {
    get();
  }
  Future<void> get() async {
    final dbp = ref.watch(dbProvider);
    if (dbp.isOpen == false) {
      return;
    }

    final list = await dbp.get(accessor);
    recodeList = [];
    recodeMap = {};
    drIdMap = {};
    for (final r in list) {
      final m = GameSettingModel.fromMap(r);
      recodeList.add(m);
      recodeMap[m.id] = m;
      drIdMap[m.drId] = m;
    }

    // 一度でもgetできれば初期化完了
    isInitialized = true;
    notifyListeners();
  }

  Ref ref;
  bool isInitialized = false;
  BaseTableAccessor accessor = GameSettingAccessor();
  Map<int, GameSettingModel> drIdMap = {};
  Map<int, GameSettingModel> recodeMap = {};
  List<GameSettingModel> recodeList = [];

  Future<void> insert(BaseModel bm) async {
    final dbModel = ref.read(dbProvider);
    await dbModel.insert(accessor, bm);
    await get();
    notifyListeners();
  }

  Future<void> upsert(BaseModel bm) async {
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
    // 念の為チェック
    if (recodeMap.containsKey(bm.id) == false) {
      return;
    }

    final dbp = ref.watch(dbProvider);
    final ret = await dbp.delete(accessor, bm);

    // 削除が終わったら同期
    get();
  }
}

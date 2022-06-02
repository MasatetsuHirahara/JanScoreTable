import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/util.dart';
import '../model/baseModel.dart';
import '../model/dayRecodeModel.dart';
import 'dbProvider.dart';

final dayRecodeProvider = ChangeNotifierProvider((ref) {
  return DayRecodeNotifier(ref);
});

class DayRecodeNotifier extends ChangeNotifier {
  DayRecodeNotifier(this.ref) {
    get();
  }
  Future<void> get() async {
    final dbp = ref.watch(dbProvider);
    if (dbp.isOpen == false) {
      return;
    }

    final list = await dbp.get(accessor);
    drList = [];
    drMap = {};
    for (final r in list) {
      final m = DayRecodeModel.fromMap(r);
      drList.add(m);
      drMap[m.id] = m;
    }

    isInitialized = true;
    notifyListeners();
  }

  Ref ref;
  bool isInitialized = false;
  BaseTableAccessor accessor = DayRecodeAccessor();
  Map<int, DayRecodeModel> drMap = {};
  List<DayRecodeModel> drList = [];

  Future<void> newInsert() async {
    final dr = DayRecodeModel(day: MyUtil.dayToString(DateTime.now()));

    final dbModel = ref.read(dbProvider);
    await dbModel.insert(accessor, dr);
    await get();
    notifyListeners();
  }

  Future<void> delete(DayRecodeModel dr) async {
    // 念の為チェック
    if (drMap.containsKey(dr.id) == false) {
      return;
    }

    final dbp = ref.watch(dbProvider);
    final ret = await dbp.delete(accessor, dr);

    // 削除が終わったら同期
    get();
  }
}

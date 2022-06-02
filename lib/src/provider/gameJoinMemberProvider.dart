import 'package:flutter/material.dart';
import 'package:flutter_app/src/model/baseModel.dart';
import 'package:flutter_app/src/model/gameJoinMemberModel.dart';
import 'package:flutter_app/src/model/memberModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/const.dart';
import '../model/gameJoinMemberModel.dart';
import 'dbProvider.dart';

class GameJoinMemberView extends GameJoinMemberModel {
  GameJoinMemberView() {}
  GameJoinMemberView.fromMap(Map<dynamic, dynamic> map) : super.fromMap(map) {
    name = map[columnName] as String;
  }
  String name;
}

final gameJoinMemberProvider = ChangeNotifierProvider((ref) {
  return GameJoinMemberNotifier(ref);
});

class GameJoinMemberNotifier extends ChangeNotifier {
  GameJoinMemberNotifier(this.ref) {
    get();
  }
  Future<void> get() async {
    final dbp = ref.watch(dbProvider);
    if (dbp.isOpen == false) {
      return;
    }

    String sql = 'SELECT  '
        '${accessor.tableName}.$columnId, ${accessor.tableName}.$columnDayRecodeId, ${accessor.tableName}.$columnMemberId, '
        '${accessor.tableName}.$columnNumber, ${MemberAccessor().tableName}.$columnName '
        'FROM ${accessor.tableName} '
        'JOIN ${MemberAccessor().tableName} '
        'ON ${accessor.tableName}.$columnMemberId = ${MemberAccessor().tableName}.$columnId '
        'ORDER BY $columnNumber ASC';

    final list = await dbp.rawQuery(sql);
    recodeMap = {};
    drIdMap = {};
    for (final r in list) {
      final m = GameJoinMemberView.fromMap(r);
      recodeMap[m.id] = m;
      if (drIdMap.containsKey(m.drId)) {
        drIdMap[m.drId].add(m);
      } else {
        drIdMap[m.drId] = [m];
      }
    }

    // 一度でもgetできれば初期化完了
    isInitialized = true;
    notifyListeners();
  }

  Ref ref;
  bool isInitialized = false;
  BaseTableAccessor accessor = GameJoinMemberAccessor();
  Map<int, GameJoinMemberView> recodeMap = {};
  Map<int, List<GameJoinMemberView>> drIdMap = {};

  Future<void> insert(BaseModel bm) async {
    final dbModel = ref.read(dbProvider);
    await dbModel.insert(accessor, bm);
    await get();
    notifyListeners();
  }

  Future<void> upsertWithParam(int drId, int mId, int number) async {
    final gm = GameJoinMemberModel()
      ..drId = drId
      ..mId = mId
      ..number = number;
    final dbModel = ref.read(dbProvider);
    await dbModel.upsert(accessor, gm);
    await get();
    notifyListeners();
  }

  Future<void> upsert(BaseModel bm) async {
    final dbModel = ref.read(dbProvider);
    await dbModel.upsert(accessor, bm);
    await get();
    notifyListeners();
  }

  Future<void> deleteWithId(int id) async {
    // 念の為チェック
    if (recodeMap.containsKey(id) == false) {
      return;
    }

    // 削除にはIDだけあれば良い
    final bm = GameJoinMemberModel()..id = id;

    final dbp = ref.read(dbProvider);
    final ret = await dbp.delete(accessor, bm);

    // 削除が終わったら同期
    get();
  }

  Future<void> delete(BaseModel bm) async {
    // 念の為チェック
    if (recodeMap.containsKey(bm.id) == false) {
      return;
    }

    final dbp = ref.read(dbProvider);
    final ret = await dbp.delete(accessor, bm);

    // 削除が終わったら同期
    get();
  }
}

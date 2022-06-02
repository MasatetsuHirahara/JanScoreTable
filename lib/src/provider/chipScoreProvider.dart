import 'package:flutter/material.dart';
import 'package:flutter_app/src/common/const.dart';
import 'package:flutter_app/src/model/baseModel.dart';
import 'package:flutter_app/src/provider/gameJoinMemberProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/chipScoreModel.dart';
import '../model/gameJoinMemberModel.dart';
import '../model/memberModel.dart';
import 'dbProvider.dart';

class ChipScoreView extends ChipScoreModel {
  ChipScoreView.fromMap(Map<dynamic, dynamic> map) : super.fromMap(map) {
    mId = map[columnMemberId] as int;
    name = map[columnName] as String;
  }
  int mId;
  String name;
}

final chipScoreProvider = ChangeNotifierProvider((ref) {
  return ChipScoreNotifier(ref);
});

class ChipScoreNotifier extends ChangeNotifier {
  ChipScoreNotifier(this.ref) {
    get();
  }
  @override
  void dispose() {
    print('dispose ChipScoreNotifier');
  }

  Future<void> get() async {
    final dbp = ref.watch(dbProvider);
    if (dbp.isOpen == false) {
      return;
    }

    // gjmが主体なのでwatchする必要がある
    ref.watch(gameJoinMemberProvider);

    String sql = 'SELECT '
        '${accessor.tableName}.$columnId, ${GameJoinMemberAccessor().tableName}.$columnDayRecodeId, ${GameJoinMemberAccessor().tableName}.$columnNumber, ${accessor.tableName}.$columnScore,'
        '${GameJoinMemberAccessor().tableName}.$columnId as $columnGameJoinedMemberId, ${GameJoinMemberAccessor().tableName}.$columnMemberId, ${MemberAccessor().tableName}.$columnName '
        ' FROM ${GameJoinMemberAccessor().tableName} '
        'LEFT JOIN ${MemberAccessor().tableName} '
        'ON ${GameJoinMemberAccessor().tableName}.$columnMemberId = ${MemberAccessor().tableName}.$columnId '
        'LEFT JOIN ${accessor.tableName} '
        'ON ${accessor.tableName}.$columnDayRecodeId = ${GameJoinMemberAccessor().tableName}.$columnDayRecodeId AND ${accessor.tableName}.$columnNumber = ${GameJoinMemberAccessor().tableName}.$columnNumber '
        'ORDER BY ${GameJoinMemberAccessor().tableName}.$columnNumber ASC';

    final list = await dbp.rawQuery(sql);

    drIdMap = {};
    for (final r in list) {
      final m = ChipScoreView.fromMap(r);

      // すでに登場しているならadd。なければ新規
      if (drIdMap.containsKey(m.drId)) {
        drIdMap[m.drId].add(m);
        continue;
      }
      drIdMap[m.drId] = [m];
    }

    // 一度でもgetできれば初期化完了
    isInitialized = true;
    notifyListeners();
  }

  Ref ref;
  bool isInitialized = false;
  BaseTableAccessor accessor = ChipScoreAccessor();
  Map<int, List<ChipScoreView>> drIdMap = {};
  List<ChipScoreModel> recodeList = [];

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

  Future<void> deleteNumber(int drId, int number) async {
    String sql = 'DELETE FROM ${accessor.tableName} '
        'WHERE $columnDayRecodeId = $drId AND $columnNumber = $number';

    final dbp = ref.watch(dbProvider);
    final ret = await dbp.rawDelete(sql);

    // 削除が終わったら同期
    get();
  }
}

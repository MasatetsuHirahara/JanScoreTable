import 'package:flutter_app/src/accessor/table/baseTableAccessor.dart';
import 'package:flutter_app/src/accessor/table/gameJoinMemberProvider.dart';
import 'package:flutter_app/src/common/const.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/chipScoreModel.dart';
import '../dbAccessor.dart';

final chipScoreAccessor = ChangeNotifierProvider((ref) {
  return ChipScoreAccessor(ref);
});

class ChipScoreAccessor extends BaseTableAccessor {
  ChipScoreAccessor(Ref ref) {
    this.ref = ref;
    tableName = tableChipScore;
    get();
  }
  @override
  void dispose() {
    print('dispose ChipScoreNotifier');
  }

  Future<void> get() async {
    final dba = ref.watch(dbAccessor);
    if (dba.isOpen == false) {
      return;
    }

    // gjmが主体なのでwatchする必要がある
    ref.watch(gameJoinMemberAccessor);

    final sql = 'SELECT '
        '$tableName.$columnId, $tableGameJoinMember.$columnDayRecodeId, '
        '$tableGameJoinMember.$columnNumber, $tableName.$columnScore,'
        '$tableGameJoinMember.$columnId as $columnGameJoinedMemberId, '
        '$tableGameJoinMember.$columnMemberId, $tableMember.$columnName '
        ' FROM $tableGameJoinMember '
        'LEFT JOIN $tableMember '
        'ON $tableGameJoinMember.$columnMemberId = $tableMember.$columnId '
        'LEFT JOIN $tableName '
        'ON $tableName.$columnDayRecodeId = $tableGameJoinMember.$columnDayRecodeId AND $tableName.$columnNumber = $tableGameJoinMember.$columnNumber '
        'ORDER BY $tableGameJoinMember.$columnNumber ASC';

    final list = await dba.rawQuery(sql);

    drIdMap = {};
    for (final r in list) {
      final m = ChipScoreModelEx.fromMap(r);

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

  bool isInitialized = false;
  Map<int, List<ChipScoreModelEx>> drIdMap = {};
  List<ChipScoreModel> recodeList = [];

  Future<int> deleteNumber(int drId, int number) async {
    String sql = 'DELETE FROM $tableName '
        'WHERE $columnDayRecodeId = $drId AND $columnNumber = $number';

    final dba = ref.read(dbAccessor);
    final ret = await dba.rawDelete(sql);

    // 削除が終わったら同期
    get();

    return ret;
  }
}

class ChipScoreModelEx extends ChipScoreModel {
  ChipScoreModelEx.fromMap(Map<dynamic, dynamic> map) : super.fromMap(map) {
    mId = map[columnMemberId] as int;
    name = map[columnName] as String;
  }
  int mId;
  String name;
}

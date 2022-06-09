import 'package:flutter_app/src/model/gameJoinMemberModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/const.dart';
import '../../model/gameJoinMemberModel.dart';
import '../dbAccessor.dart';
import 'baseTableAccessor.dart';

class GameJoinMemberModelEx extends GameJoinMemberModel {
  GameJoinMemberModelEx() {}
  GameJoinMemberModelEx.fromMap(Map<dynamic, dynamic> map)
      : super.fromMap(map) {
    name = map[columnName] as String;
  }
  String name;
}

final gameJoinMemberAccessor = ChangeNotifierProvider((ref) {
  return GameJoinMemberAccessor(ref);
});

class GameJoinMemberAccessor extends BaseTableAccessor {
  GameJoinMemberAccessor(Ref ref) {
    this.ref = ref;
    tableName = tableGameJoinMember;
    get();
  }

  @override
  Future<void> get() async {
    final dba = ref.watch(dbAccessor);
    if (dba.isOpen == false) {
      return;
    }

    final sql = 'SELECT  '
        '$tableName.$columnId, $tableName.$columnDayRecodeId, $tableName.$columnMemberId, '
        '$tableName.$columnNumber, $tableMember.$columnName '
        'FROM $tableName '
        'JOIN $tableMember '
        'ON $tableName.$columnMemberId = $tableMember.$columnId '
        'ORDER BY $columnNumber ASC';

    final list = await dba.rawQuery(sql);
    recodeMap = {};
    drIdMap = {};
    for (final r in list) {
      final m = GameJoinMemberModelEx.fromMap(r);
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

  bool isInitialized = false;
  Map<int, GameJoinMemberModelEx> recodeMap = {};
  Map<int, List<GameJoinMemberModelEx>> drIdMap = {};

  Future<int> upsertWithParam(int drId, int mId, int number) async {
    final gjm = GameJoinMemberModel()
      ..drId = drId
      ..mId = mId
      ..number = number;
    return super.upsert(gjm);
  }

  Future<int> deleteWithId(int id) async {
    // 削除にはIDだけあれば良い
    final gjm = GameJoinMemberModel()..id = id;

    return super.delete(gjm);
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/common/const.dart';
import 'package:flutter_app/src/model/baseModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dbAccessor.dart';

class PersonalScoreModel extends BaseModel {
  PersonalScoreModel() {}
  PersonalScoreModel.fromMap(Map<dynamic, dynamic> map) {
    score = map.containsKey(columnScore) ? map[columnScore] as int : 0;
    rank = map.containsKey(columnRank) ? map[columnRank] as int : 0;
    name = map[columnName] as String;
    kind = map[columnKind] as int;
    rate = map[columnRate] as int;
  }
  int score;
  int rank;
  String name;
  int kind;
  int rate;
}

class PersonalScoreAccessor extends ChangeNotifier {
  PersonalScoreAccessor(this.ref, this.id);
  Ref ref;
  int id;

  Future<List<PersonalScoreModel>> get() async {
    final dba = ref.read(dbAccessor);
    if (dba.isOpen == false) {
      return [];
    }

    final sql = 'SELECT $tableScore.$columnScore, $tableScore.$columnRank, '
        '$tableMember.$columnName, $tableGameSetting.$columnKind, '
        '$tableGameSetting.$columnRate  FROM '
        '$tableScore '
        'LEFT JOIN $tableGameJoinMember '
        'ON $tableScore.$columnDayRecodeId =  $tableGameJoinMember.$columnDayRecodeId '
        'AND $tableScore.$columnNumber =  $tableGameJoinMember.$columnNumber '
        'LEFT JOIN $tableMember '
        'ON $tableMember.$columnId = $tableGameJoinMember.$columnMemberId '
        'LEFT JOIN $tableGameSetting '
        'ON $tableScore.$columnDayRecodeId = $tableGameSetting.$columnDayRecodeId '
        'WHERE $tableMember.$columnId = $id';

    final list = await dba.rawQuery(sql);

    final plist = <PersonalScoreModel>[];
    for (final p in list) {
      plist.add(PersonalScoreModel.fromMap(p));
    }

    return plist;
  }
}

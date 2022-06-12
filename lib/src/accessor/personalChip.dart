import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/common/const.dart';
import 'package:flutter_app/src/model/baseModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dbAccessor.dart';

class PersonalChipModel extends BaseModel {
  PersonalChipModel() {}
  PersonalChipModel.fromMap(Map<dynamic, dynamic> map) {
    mid = map[columnMemberId] as int;
    score = map.containsKey(columnScore) ? map[columnScore] as int : 0;
    rate = map[columnChipRate] as int;
    kind = map[columnKind] as int;
  }
  int mid;
  int score;
  int rate;
  int kind;
}

class PersonalChipAccessor extends ChangeNotifier {
  PersonalChipAccessor(this.ref, this.mId);
  Ref ref;
  int mId;

  Future<List<PersonalChipModel>> get() async {
    final dba = ref.read(dbAccessor);
    if (dba.isOpen == false) {
      return [];
    }

    final sql = 'SELECT '
        '$tableGameJoinMember.$columnMemberId, '
        '$tableChipScore.$columnScore, '
        '$tableGameSetting.$columnChipRate, $tableGameSetting.$columnKind '
        ' FROM $tableChipScore '
        'LEFT JOIN $tableGameJoinMember '
        'ON $tableChipScore.$columnDayRecodeId = $tableGameJoinMember.$columnDayRecodeId '
        'AND $tableChipScore.$columnNumber = $tableGameJoinMember.$columnNumber '
        'LEFT JOIN $tableGameSetting '
        'ON $tableChipScore.$columnDayRecodeId = $tableGameSetting.$columnDayRecodeId '
        'WHERE $tableGameJoinMember.$columnMemberId = $mId ';

    final list = await dba.rawQuery(sql);

    final plist = <PersonalChipModel>[];
    for (final p in list) {
      plist.add(PersonalChipModel.fromMap(p));
    }

    return plist;
  }
}

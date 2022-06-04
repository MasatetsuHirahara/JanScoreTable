import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/common/const.dart';
import 'package:flutter_app/src/model/memberModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dbAccessor.dart';

class SearchMemberAccessor extends ChangeNotifier {
  SearchMemberAccessor(this.ref);
  Ref ref;

  Future<List<MemberModel>> get(String name, int limit) async {
    final dba = ref.read(dbAccessor);
    if (dba.isOpen == false) {
      return [];
    }

    final sql = 'SELECT * FROM '
        '$tableMember '
        'WHERE $columnName LIKE \'$name%\' '
        'ORDER BY $columnLastJoin DESC '
        'LIMIT $limit';

    final list = await dba.rawQuery(sql);

    final memberList = <MemberModel>[];
    for (final r in list) {
      memberList.add(MemberModel.fromMap(r));
    }

    return memberList;
  }
}

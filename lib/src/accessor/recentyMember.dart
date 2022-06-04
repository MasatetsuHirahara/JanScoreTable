import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/common/const.dart';
import 'package:flutter_app/src/model/memberModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dbAccessor.dart';

class RecentlyMemberAccessor extends ChangeNotifier {
  RecentlyMemberAccessor(this.ref, int limit) {
    get(limit);
  }
  Ref ref;
  List<MemberModel> memberList = [];

  @override
  void dispose() {
    print('dispose RecentlyMemberAccessor');
    super.dispose();
  }

  Future<void> get(int limit) async {
    final dba = ref.read(dbAccessor);
    if (dba.isOpen == false) {
      return;
    }

    final sql = 'SELECT * FROM '
        '$tableMember '
        'ORDER BY $columnLastJoin DESC '
        'LIMIT $limit';

    final list = await dba.rawQuery(sql);

    memberList = [];
    for (final r in list) {
      memberList.add(MemberModel.fromMap(r));
    }

    notifyListeners();
  }
}

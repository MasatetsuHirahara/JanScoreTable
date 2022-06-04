import 'package:flutter_app/src/common/const.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/memberModel.dart';
import '../dbAccessor.dart';
import 'baseTableAccessor.dart';

final memberAccessor = ChangeNotifierProvider((ref) {
  return MemberAccessor(ref);
});

class MemberAccessor extends BaseTableAccessor {
  MemberAccessor(Ref ref) {
    this.ref = ref;
    tableName = tableMember;
    get();
  }

  @override
  Future<void> get() async {
    final dba = ref.watch(dbAccessor);
    if (dba.isOpen == false) {
      return;
    }

    final list = await dba.get(tableName);
    recodeList = [];
    recodeMap = {};
    for (final r in list) {
      final m = MemberModel.fromMap(r);
      recodeList.add(m);
      recodeMap[m.id] = m;
    }

    // 一度でもgetできれば初期化完了
    isInitialized = true;
    notifyListeners();
  }

  bool isInitialized = false;
  Map<int, MemberModel> recodeMap = {};
  List<MemberModel> recodeList = [];

  int getId(String name) {
    for (final r in recodeList) {
      if (r.name == name) {
        return r.id;
      }
    }
  }
}

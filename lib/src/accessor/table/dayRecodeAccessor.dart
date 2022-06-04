import 'package:flutter_app/src/common/const.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/util.dart';
import '../../model/dayRecodeModel.dart';
import '../dbAccessor.dart';
import 'baseTableAccessor.dart';

final dayRecodeAccessor = ChangeNotifierProvider((ref) {
  return DayRecodeAccessor(ref);
});

class DayRecodeAccessor extends BaseTableAccessor {
  DayRecodeAccessor(Ref ref) {
    this.ref = ref;
    tableName = tableDayRecode;
    get();
  }

  @override
  Future<void> get() async {
    final dba = ref.watch(dbAccessor);
    if (dba.isOpen == false) {
      return;
    }

    final list = await dba.get(tableName);
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

  bool isInitialized = false;
  Map<int, DayRecodeModel> drMap = {};
  List<DayRecodeModel> drList = [];

  Future<DayRecodeModel> newInsert() async {
    final dr = DayRecodeModel(day: MyUtil.dayToString(DateTime.now()));

    final dbModel = ref.read(dbAccessor);
    await dbModel.insert(tableName, dr);
    await get();
    notifyListeners();

    return dr;
  }
}

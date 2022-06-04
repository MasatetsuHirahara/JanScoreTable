import 'package:flutter_app/src/common/const.dart';
import 'package:flutter_app/src/model/gameSettingModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dbAccessor.dart';
import 'baseTableAccessor.dart';

final gameSettingAccessor = ChangeNotifierProvider((ref) {
  return GameSettingAccessor(ref);
});

class GameSettingAccessor extends BaseTableAccessor {
  GameSettingAccessor(Ref ref) {
    this.ref = ref;
    tableName = tableGameSetting;
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
    drIdMap = {};
    for (final r in list) {
      final m = GameSettingModel.fromMap(r);
      recodeList.add(m);
      recodeMap[m.id] = m;
      drIdMap[m.drId] = m;
    }

    // 一度でもgetできれば初期化完了
    isInitialized = true;
    notifyListeners();
  }

  bool isInitialized = false;
  Map<int, GameSettingModel> drIdMap = {};
  Map<int, GameSettingModel> recodeMap = {};
  List<GameSettingModel> recodeList = [];
}

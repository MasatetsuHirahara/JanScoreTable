import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/dayRecodeModel.dart';
import '../../model/gameSettingModel.dart';
import '../../provider/dayRecodeProvider.dart';
import '../../provider/gameJoinMemberProvider.dart';
import '../../provider/gameSettingProvider.dart';

final gameListViewProvider = ChangeNotifierProvider.autoDispose((ref) {
  return GameListViewModel(ref);
});

class GameListViewModel extends ChangeNotifier {
  GameListViewModel(this.ref) {
    watchDayRecode();
    watchGameSetting();
    watchGameJoinModel();
  }
  Ref ref;
  Map<int, DrProperty> drPropertyMap = {};
  List<DayRecodeModel> drList = [];

  void watchDayRecode() {
    final p = ref.watch(dayRecodeProvider);
    if (p.isInitialized) {
      drList = p.drList;
      notifyListeners();
    }
  }

  void watchGameSetting() {
    final p = ref.watch(gameSettingProvider);
    if (p.isInitialized) {
      p.drIdMap.forEach((key, value) {
        if (drPropertyMap.containsKey(key)) {
          drPropertyMap[key].gameSettingModel = value;
        } else {
          drPropertyMap[key] = DrProperty()..gameSettingModel = value;
        }
      });
      notifyListeners();
    }
  }

  void watchGameJoinModel() {
    final p = ref.watch(gameJoinMemberProvider);
    if (p.isInitialized) {
      p.drIdMap.forEach((key, value) {
        if (drPropertyMap.containsKey(key)) {
          drPropertyMap[key].memberList = value;
        } else {
          drPropertyMap[key] = DrProperty()..memberList = value;
        }
      });
      notifyListeners();
    }
  }

  List<CardProperty> getProperty() {
    final ret = <CardProperty>[];

    // drListを基準に各要素をセットしていく
    for (final dr in drList) {
      final rProperty = CardProperty()..dr = dr;

      final dp = drPropertyMap[dr.id];
      if (dp == null) {
        continue;
      }

      if (dp.gameSettingModel != null) {
        final kind = KindValueExtension.fromInt(dp.gameSettingModel.kind);
        rProperty.kind = kind.gameName;
      }

      for (final m in dp.memberList) {
        rProperty.nameList.add(m.name);
      }

      ret.add(rProperty);
    }

    return ret;
  }

  void deleteDayRecode(int index) {
    if (index >= drList.length) {
      return;
    }

    ref.read(dayRecodeProvider).delete(drList[index]);
  }
}

class DrProperty {
  GameSettingModel gameSettingModel;
  List<GameJoinMemberView> memberList = [];
}

class CardProperty {
  CardProperty() {}
  DayRecodeModel dr;
  String kind;
  List<String> nameList = [];
}

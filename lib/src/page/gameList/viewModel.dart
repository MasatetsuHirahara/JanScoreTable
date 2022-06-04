import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessor/table/dayRecodeAccessor.dart';
import '../../accessor/table/gameJoinMemberProvider.dart';
import '../../accessor/table/gameSettingProvider.dart';
import '../../model/dayRecodeModel.dart';
import '../../model/gameSettingModel.dart';

final gameListViewModel = ChangeNotifierProvider.autoDispose((ref) {
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
    final dra = ref.watch(dayRecodeAccessor);
    if (dra.isInitialized) {
      drList = dra.drList;
      notifyListeners();
    }
  }

  void watchGameSetting() {
    final accessor = ref.watch(gameSettingAccessor);
    if (accessor.isInitialized) {
      accessor.drIdMap.forEach((key, value) {
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
    final accessor = ref.watch(gameJoinMemberAccessor);
    if (accessor.isInitialized) {
      accessor.drIdMap.forEach((key, value) {
        if (drPropertyMap.containsKey(key)) {
          drPropertyMap[key].gameJoinMemberList = value;
        } else {
          drPropertyMap[key] = DrProperty()..gameJoinMemberList = value;
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

      for (final gjm in dp.gameJoinMemberList) {
        rProperty.nameList.add(gjm.name);
      }

      ret.add(rProperty);
    }

    return ret;
  }

  void deleteDayRecode(int index) {
    if (index >= drList.length) {
      return;
    }

    ref.read(dayRecodeAccessor).delete(drList[index]);
  }
}

class DrProperty {
  GameSettingModel gameSettingModel;
  List<GameJoinMemberModelEx> gameJoinMemberList = [];
}

class CardProperty {
  CardProperty() {}
  DayRecodeModel dr;
  String kind;
  List<String> nameList = [];
}

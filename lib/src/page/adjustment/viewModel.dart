import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessor/table/chipScoreAccessor.dart';
import '../../accessor/table/gameSettingAccessor.dart';
import '../../accessor/table/scoreAccessor.dart';
import '../../model/gameSettingModel.dart';

class AdjustmentViewModel extends ChangeNotifier {
  AdjustmentViewModel(this.ref, this.drId) {
    listenGameSetting();
    listenScore();
    listenChipScore();
  }

  Ref ref;
  int drId;
  List<PointProperty> pointList = [];
  GameSettingModel gameSetting;
  List<int> totalList = [];
  List<ChipScoreModelEx> chipScoreList;
  TextEditingController placeFeeController = TextEditingController()
    ..text = '0';

  void listenGameSetting() {
    final accessor = ref.watch(gameSettingAccessor);
    if (accessor.isInitialized) {
      if (accessor.drIdMap.containsKey(drId)) {
        gameSetting = accessor.drIdMap[drId];
        setPointPropertyList();
      }
    }
  }

  void listenScore() {
    final accessor = ref.watch(scoreAccessor);
    if (accessor.isInitialized) {
      if (accessor.scoreViewMap.containsKey(drId)) {
        final drIdScoreView = accessor.scoreViewMap[drId];
        totalList = [];
        for (var i = 0; i <= drIdScoreView.maxGameCount; i++) {
          for (var j = 0; j <= drIdScoreView.maxNumber; j++) {
            // マップからスコアを取得。ない場合0と扱って加算する
            final score = drIdScoreView.map[i].containsKey(j)
                ? drIdScoreView.map[i][j].score
                : 0;
            if (i == 0) {
              totalList.add(score);
              continue;
            }
            totalList[j] += score;
          }
        }
        setPointPropertyList();
      }
    }
  }

  void listenChipScore() {
    final accessor = ref.watch(chipScoreAccessor);
    if (accessor.isInitialized) {
      if (accessor.drIdMap.containsKey(drId)) {
        chipScoreList = accessor.drIdMap[drId];
        setPointPropertyList();
      }
    }
  }

  void setPointPropertyList() {
    if (gameSetting == null) {
      return;
    }
    if (chipScoreList == null) {
      return;
    }

    // 場代をセット
    placeFeeController
      ..text = gameSetting.placeFee.toString()
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: placeFeeController.text.length),
      );

    // 表示するポイントを計算する
    // chipScoreListはgjm分のindexを持っているのでchipScoreをベースにする
    pointList = [];
    var topIndex = 0;
    var topScore = 0;
    for (final cs in chipScoreList) {
      final name = cs.name;
      final chipPoint = cs.score * gameSetting.chipRate;
      var point = chipPoint;
      if (totalList.length > cs.number) {
        final total = totalList[cs.number];
        if (total > topScore) {
          topIndex = cs.number;
          topScore = total;
        }
        point += totalList[cs.number] * gameSetting.rate;
      }
      pointList.add(PointProperty(name, point, chipPoint));
    }

    // 一人あたりの場代を計算。１の位は余りとしてトップに分配
    var placeFeePerOne = 0;
    var reminder = 0;
    final placeFee = gameSetting.placeFee;
    if (pointList.length != 0) {
      placeFeePerOne = placeFee ~/ pointList.length;
      final perOneStr = placeFeePerOne.toString();
      final onesPlace = int.parse(perOneStr.substring(perOneStr.length - 1));
      placeFeePerOne -= onesPlace;
      reminder = (placeFee % pointList.length) + onesPlace * pointList.length;
    }

    for (final p in pointList) {
      p.addPlaceFee(placeFeePerOne);
    }

    // topにあまりを追加
    pointList[topIndex].addPlaceFee(reminder);

    notifyListeners();
  }

  void afterPlaceFeeInput() {
    final fee = int.parse(placeFeeController.text);
    if (fee == null) {
      return;
    }
    gameSetting.placeFee = fee;
    ref.read(gameSettingAccessor).upsert(gameSetting);
  }
}

class PointProperty {
  PointProperty(this.name, this.point, this.chipPoint) {}

  String name = '';
  int point = 0;
  int chipPoint = 0;
  int placeFee = 0;

  int get totalPoint {
    return point + chipPoint - placeFee;
  }

  void addPlaceFee(int fee) {
    placeFee += fee;
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/accessor/table/chipScoreProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const cellHeight = 50.0;

class ChipRowProperty {
  ChipRowProperty(this.chipScoreView) {
    controller.text = chipScoreView.scoreString;
  }
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();

  ChipScoreModelEx chipScoreView;

  bool validateInput() {
    // １文字単位の制限しかできなかったのでここでバリデート
    // マイナスが先頭以外にあったらエラー(数字に後ろにあったら)
    return !new RegExp(r'[0-9]-').hasMatch(controller.text);
  }

  void clearScore() {
    controller.text = '';
    chipScoreView.score = 0;
  }

  bool hasFocus() {
    return focusNode.hasFocus;
  }

  bool afterInput() {
    // バリデートエラーならクリアして終わり
    if (validateInput() == false) {
      clearScore();
      return true;
    }

    //変化があったら更新
    final newScore = scoreCastInt(controller.text);
    if (newScore != chipScoreView.score) {
      chipScoreView.score = newScore;
      return true;
    }

    return false;
  }
}

class ChipScoreViewModel extends ChangeNotifier {
  ChipScoreViewModel(this.ref, this.drId) {
    listenChipScore();
  }
  Ref ref;
  int drId;
  List<ChipRowProperty> chipRowList = [];

  void listenChipScore() {
    localFunc(ChipScoreAccessor accessor) {
      if (accessor.isInitialized) {
        if (accessor.drIdMap.containsKey(drId)) {
          chipRowList = [];
          for (final csv in accessor.drIdMap[drId]) {
            chipRowList.add(ChipRowProperty(csv));
          }
          notifyListeners();
        }
      }
    }

    final accessor = ref.read(chipScoreAccessor);
    localFunc(accessor);

    ref.listen<ChipScoreAccessor>(chipScoreAccessor, (previous, next) {
      localFunc(next);
    });
  }

  int getTotal() {
    var total = 0;
    for (final view in chipRowList) {
      total += scoreCastInt(view.controller.text);
    }

    return total;
  }

  void afterInput(int index) {
    // after処理。変化がある場合は通知
    if (chipRowList[index].afterInput()) {
      notifyListeners();
    }
  }

  int getFocusIndex() {
    for (var i = 0; i < chipRowList.length; i++) {
      if (chipRowList[i].hasFocus()) {
        return i;
      }
    }

    return -1;
  }

  Future saveScore() async {
    final accessor = ref.read(chipScoreAccessor);

    for (final csv in chipRowList) {
      await accessor.upsert(csv.chipScoreView);
    }
  }
}

int scoreCastInt(String src) {
  return src != '' ? int.parse(src) : 0;
}

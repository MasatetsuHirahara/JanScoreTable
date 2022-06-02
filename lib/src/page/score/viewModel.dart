import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/model/gameSettingModel.dart';
import 'package:flutter_app/src/model/scoreModel.dart';
import 'package:flutter_app/src/provider/gameJoinMemberProvider.dart';
import 'package:flutter_app/src/provider/gameSettingProvider.dart';
import 'package:flutter_app/src/provider/scoreProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO
// スコアを毎回全体更新だと遅いかも

class Coordinate {
  Coordinate(this.row, this.col);
  int row;
  int col;

  bool isNotEqual(int row, int col) {
    return this.row != row || this.col != col;
  }
}

class SpeechBubbleProperty {
  String score = '';
  Coordinate coordinate = Coordinate(0, 0);
  bool isVisible = false;
  void clear() {
    isVisible = false;
    score = '';
  }

  void setProperty(String score, int row, int col) {
    this.score = score;
    coordinate = Coordinate(row, col);
    isVisible = true;
  }
}

// スコアの1行分のproperty
class ScoreRowProperty {
  ScoreRowProperty(int joinedCounter) {
    addNewScore(joinedCounter);
  }

  Color color;
  List<ScoreCellProperty> scoreCellList = [];

  void addNewScore(int num) {
    for (var i = 0; i < num; i++) {
      scoreCellList.add(ScoreCellProperty());
    }
  }

  void removeLastScore(int num) {
    for (var i = 0; i < num; i++) {
      scoreCellList.removeLast();
    }
  }

  bool isFull() {
    for (final s in scoreCellList) {
      if (s.controller.text == '') {
        return false;
      }
    }
    return true;
  }

  String getScoreText(int col) {
    return scoreCellList[col].controller.text;
  }

  int getScore(int col) {
    return scoreCellList[col].score;
  }

  void setScore(int col, String score) {
    scoreCellList[col].controller.text = score;
    scoreCellList[col].score = scoreCastInt(score);
  }

  void setScoreModel(int col, ScoreModel score) {
    scoreCellList[col].controller.text = score.scoreString;
    scoreCellList[col].score = score.score;
  }

  void setAllCursorToEnd() {
    for (final c in scoreCellList) {
      c.setCursorToEnd();
    }
  }

  int getFocusCol() {
    for (var i = 0; i < scoreCellList.length; i++) {
      if (scoreCellList[i].focusNode.hasFocus) return i;
    }
    return -1;
  }

  bool validateInputScore(int col) {
    return scoreCellList[col].validateInput();
  }

  void clearScore(int col) {
    scoreCellList[col].clearScore();
  }

  bool isNotNeedSpeechBubble(int notIncludeCol, int kindValue) {
    // ゲーム人数-1　入力されていれば補完できる
    // タップされたセルはカウントしない
    var cnt = 0;
    for (var i = 0; i < scoreCellList.length; i++) {
      if (i == notIncludeCol) {
        continue;
      }
      if (scoreCellList[i].controller.text != '') {
        cnt++;
        if (cnt >= kindValue - 1) {
          return false;
        }
      }
    }
    return true;
  }

  int sumScore() {
    var ret = 0;
    for (final s in scoreCellList) {
      ret += s.score;
    }
    return ret;
  }

  bool validateScoreSum(int kind) {
    var total = 0;
    var cnt = 0;
    for (final c in scoreCellList) {
      total += c.score;
      if (c.controller.text != '') {
        cnt++;
      }
    }

    if (total != 0) {
      return false;
    }

    return true;
  }

  void setRowColor(Color color) {
    this.color = color;
  }
}

// スコア1セル分のproperty
class ScoreCellProperty {
  ScoreCellProperty() {
    controller.addListener(() {});
  }
  int score = 0; // 補助　textFieldを正とする
  int row;
  int col;
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();

  VoidCallback focusOut;

  void setFocusOut(VoidCallback f) {
    controller.removeListener(focusOut);
    focusOut = f;
    controller.addListener(focusOut);
  }

  void setCursorToEnd() {
    controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length));
  }

  bool isChanged() {
    if (focusNode.hasFocus) {
      return false;
    }
    return score != scoreCastInt(controller.text);
  }

  bool validateInput() {
    // １文字単位の制限しかできなかったのでここでバリデート
    // マイナスが先頭以外にあったらエラー(数字に後ろにあったら)
    return !new RegExp(r'[0-9]-').hasMatch(controller.text);
  }

  bool clearScore() {
    score = 0;
    controller.text = '';
  }
}

// viewModel
final scoreViewProvider =
    ChangeNotifierProvider.autoDispose.family<ScoreViewModel, int>((ref, drId) {
  return ScoreViewModel(ref, drId);
});

const maxGame = 30;
const defaultGameCount = 1;
const defaultJoinedCount = 4;

class ScoreViewModel extends ChangeNotifier {
  ScoreViewModel(this.ref, this.drId) {
    addNewScoreRow(defaultGameCount);
    addNewTotalPoint(joinedCount);
    listenGameSetting();
    listenGjm();
    listenScore();
  }

  Ref ref;
  int drId;

  List<ScoreRowProperty> rowPropertyList = [];
  List<int> totalPointList = [];
  int joinedCount = defaultJoinedCount;
  List<String> nameList = ['', '', '', ''];
  SpeechBubbleProperty speechBubbleProperty = SpeechBubbleProperty();
  GameSettingModel gameSettingModel = GameSettingModel()
    ..kind = KindValue.YONMA.num;
  bool keyBoardVisible = false;

  @override
  void dispose() {
    print('desipose !!!');
    // TODO: implement dispose
    super.dispose();
  }

  void listenGameSetting() {
    final provider = ref.read(gameSettingProvider);
    if (provider.isInitialized) {
      if (provider.drIdMap.containsKey(drId)) {
        gameSettingModel = provider.drIdMap[drId];
      }
    }

    ref.listen<GameSettingNotifier>(gameSettingProvider, (previous, next) {
      if (next.isInitialized) {
        if (next.drIdMap.containsKey(drId)) {
          gameSettingModel = next.drIdMap[drId];
        }
      }
    });
  }

  void listenScore() {
    final provider = ref.read(scoreProvider);
    if (provider.scoreViewMap.containsKey(drId)) {
      renewScore(provider.scoreViewMap[drId]);
      notifyListeners();
    }
    ref.listen<ScoreNotifier>(scoreProvider, (previous, next) {
      if (next.scoreViewMap.containsKey(drId)) {
        renewScore(next.scoreViewMap[drId]);
        notifyListeners();
      }
    });
  }

  void renewScore(DrIdScoreView dIdScoreView) {
    final totalMap = <int, int>{};

    // DBの中のscore表のサイズが現在のスコア表より大きかった作り直す
    if (rowPropertyList.length <= dIdScoreView.maxGameCount ||
        joinedCount <= dIdScoreView.maxNumber) {
      rowPropertyList = [];
      addNewScoreRow(dIdScoreView.maxGameCount + 1);
    }

    dIdScoreView.map.forEach((gameCount, scoreMap) {
      scoreMap.forEach((number, scoreModel) {
        rowPropertyList[gameCount].setScoreModel(number, scoreModel);

        if (totalMap.containsKey(number)) {
          totalMap[number] += scoreModel.score;
        } else {
          totalMap[number] = scoreModel.score;
        }
      });
    });

    //トータルを更新
    totalPointList.asMap().forEach((index, value) {
      if (totalMap.containsKey(index)) {
        totalPointList[index] = totalMap[index];
      } else {
        totalPointList[index] = 0;
      }
    });

    // 吹き出しを表示している場合は表示内容をリセット
    if (speechBubbleProperty.isVisible) {
      setSpeechBubble(speechBubbleProperty.coordinate.row,
          speechBubbleProperty.coordinate.col);
    }
    incrementGameCountIfNeed();
    notifyListeners();
  }

  void incrementGameCountIfNeed([int index]) {
    if (index != null) {
      final inputGc = index ~/ joinedCount;

      // 末尾のgcの更新でなければ追加を考慮する必要なし
      if (rowPropertyList.length > inputGc + 1) {
        return;
      }
    }
    // 末尾のスコアを確認して、空欄があれば追加しない
    if (rowPropertyList.last.isFull() == false) {
      return;
    }

    // 追加
    addNewScoreRow(1);
  }

  void listenGjm() {
    final provider = ref.read(gameJoinMemberProvider);
    if (provider.isInitialized) {
      if (provider.drIdMap.containsKey(drId)) {
        renewGameJoinedMember(provider.drIdMap[drId]);
        notifyListeners();
      }
    }
    ref.listen<GameJoinMemberNotifier>(gameJoinMemberProvider,
        (previous, next) {
      if (next.isInitialized) {
        if (next.drIdMap.containsKey(drId)) {
          print(
              'listenGjm GC:$joinedCount, length:${next.drIdMap[drId].length}');
          renewGameJoinedMember(next.drIdMap[drId]);
          notifyListeners();
        }
      }
    });
  }

  void renewGameJoinedMember(List<GameJoinMemberView> list) {
    // 参加人数に増減がなければ名前だけ書き換える
    if (joinedCount == list.length) {
      list.asMap().forEach((index, value) {
        nameList[index] = value.name;
      });

      return;
    }

    // 数が違うので表を操作する
    print('renewGameJoinedMember GC:$joinedCount, length:${list.length}');
    final diff = list.length - joinedCount;

    // nameListは作り直す
    nameList.clear();
    for (final m in list) {
      nameList.add(m.name);
    }

    // totalPointは増減させる
    if (diff > 0) {
      addNewTotalPoint(diff);
    } else {
      lastRemoveTotalPont(diff.abs());
    }

    // scoreは増減させる
    // 末尾から表を操作することで、追加削除によるindexの変動をうけないようにする
    for (final rp in rowPropertyList) {
      if (diff > 0) {
        rp.addNewScore(diff);
      } else {
        rp.removeLastScore(diff.abs());
      }
    }

    // 忘れずに更新
    joinedCount = list.length;
    print('END GC:$joinedCount, length:${list.length}');
  }

  void addNewTotalPoint(int num) {
    for (var i = 0; i < num; i++) {
      totalPointList.add(0);
    }
  }

  void lastRemoveTotalPont(int num) {
    for (var i = 0; i < num; i++) {
      totalPointList.removeAt(totalPointList.length - 1);
    }
  }

  void addNewScoreRow(int num) {
    for (var i = 0; i < num; i++) {
      rowPropertyList.add(ScoreRowProperty(joinedCount));
    }
  }

  Coordinate getFocusCoordinate() {
    for (var row = rowPropertyList.length - 1; row >= 0; row--) {
      final col = rowPropertyList[row].getFocusCol();
      if (col >= 0) {
        return Coordinate(row, col);
      }
    }

    return null;
  }

  void setSpeechBubble(int row, int col) {
    final rowProperty = rowPropertyList[row];
    if (rowProperty.isNotNeedSpeechBubble(col, gameSettingModel.kind)) {
      clearSpeechBubbleIfNeed();
      notifyListeners();
      return;
    }

    final currentTotal = rowProperty.sumScore() - rowProperty.getScore(col);
    final suggestPoint = -currentTotal;

    speechBubbleProperty.setProperty(suggestPoint.toString(), row, col);
    notifyListeners();
  }

  void clearSpeechBubbleIfNeed() {
    if (speechBubbleProperty.isVisible) {
      speechBubbleProperty.clear();
      notifyListeners();
    }
  }

  void speechBubbleTap() {
    rowPropertyList[speechBubbleProperty.coordinate.row].setScore(
        speechBubbleProperty.coordinate.col, speechBubbleProperty.score);
    afterInput(speechBubbleProperty.coordinate.row,
        speechBubbleProperty.coordinate.col);
    clearSpeechBubbleIfNeed();
  }

  void afterInput(int row, int col) {
    print('afterInput $row , $col');
    // 吹き出しクリア
    //clearSpeechBubbleIfNeed();

    // バリデートエラーならクリアして終わり
    final rowProperty = rowPropertyList[row];
    if (rowProperty.validateInputScore(col) == false) {
      rowProperty.clearScore(col);
      return;
    }

    // cellに保存する
    final inputScore = rowProperty.getScoreText(col) == ''
        ? null
        : scoreCastInt(rowProperty.getScoreText(col));
    final sm =
        ScoreModel(drId: drId, gameCount: row, number: col, score: inputScore);
    final provider = ref.read(scoreProvider);
    provider.upsert(sm);
  }

  bool validateRowScoreSum(int row) {
    // 最後のゲームでゲーム人数以上入力されていない場合はvalidate対象外
    if (row == rowPropertyList.length - 1) {
      var cnt = 0;
      for (final p in rowPropertyList[row].scoreCellList) {
        if (p.controller.text != '') {
          cnt++;
        }
      }

      if (cnt < joinedCount) {
        return true;
      }
    }

    return rowPropertyList[row].validateScoreSum(gameSettingModel.kind);
  }

  void setKeyBoardVisible(bool src) {
    if (keyBoardVisible == src) {
      return;
    }
    keyBoardVisible = src;
    notifyListeners();
  }
}

int scoreCastInt(String src) {
  return src != '' ? int.parse(src) : 0;
}
import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/accessor/table/gameJoinMemberProvider.dart';
import 'package:flutter_app/src/accessor/table/gameSettingProvider.dart';
import 'package:flutter_app/src/accessor/table/scoreProvider.dart';
import 'package:flutter_app/src/model/gameSettingModel.dart';
import 'package:flutter_app/src/model/scoreModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO
// スコアを毎回全体更新だと遅いかも

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

  void listenGameSetting() {
    final gsa = ref.read(gameSettingAccessor);
    if (gsa.isInitialized) {
      if (gsa.drIdMap.containsKey(drId)) {
        gameSettingModel = gsa.drIdMap[drId];
      }
    }

    ref.listen<GameSettingAccessor>(gameSettingAccessor, (previous, next) {
      if (next.isInitialized) {
        if (next.drIdMap.containsKey(drId)) {
          gameSettingModel = next.drIdMap[drId];
        }
      }
    });
  }

  void listenScore() {
    final accessor = ref.read(scoreAccessor);
    if (accessor.scoreViewMap.containsKey(drId)) {
      renewScore(accessor.scoreViewMap[drId]);
      notifyListeners();
    }
    ref.listen<ScoreAccessor>(scoreAccessor, (previous, next) {
      if (next.scoreViewMap.containsKey(drId)) {
        renewScore(next.scoreViewMap[drId]);
        notifyListeners();
      }
    });
  }

  void renewScore(DayScore dayScore) {
    final totalMap = <int, int>{};

    // DBの中のscore表のサイズが現在のスコア表より大きかった作り直す
    if (rowPropertyList.length <= dayScore.maxGameCount ||
        joinedCount <= dayScore.maxNumber) {
      rowPropertyList = [];
      addNewScoreRow(dayScore.maxGameCount + 1);
    }

    dayScore.map.forEach((gameCount, scoreMap) {
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
    final accessor = ref.read(gameJoinMemberAccessor);
    if (accessor.isInitialized) {
      if (accessor.drIdMap.containsKey(drId)) {
        renewGameJoinedMember(accessor.drIdMap[drId]);
        notifyListeners();
      }
    }
    ref.listen<GameJoinMemberAccessor>(gameJoinMemberAccessor,
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

  void renewGameJoinedMember(List<GameJoinMemberModelEx> list) {
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
      lastRemoveTotalPoint(diff.abs());
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

  void lastRemoveTotalPoint(int num) {
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

    speechBubbleProperty.setProperty(suggestPoint, row, col);
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

    // バリデートエラーならクリアして終わり
    final rowProperty = rowPropertyList[row];
    if (rowProperty.validateInputScore(col) == false) {
      rowProperty.clearScore(col);
      return;
    }

    // 順位を設定
    rowProperty.setRank();

    final accessor = ref.read(scoreAccessor);
    for (var i = 0; i < rowProperty.scoreCellList.length; i++) {
      final sc = rowProperty.scoreCellList[i];
      // inputされていないcellもrank更新されているかもしれないので更新
      // idがないは明らかに不要なのでスルー
      if (i != col) {
        if (sc.scoreModel.id != null) {
          accessor.upsert(sc.scoreModel);
        }
        continue;
      }

      // inputされたcell
      final inputScore = sc.controller.text == ''
          ? null
          : scoreCastInt(rowProperty.getScoreText(col));
      final newSm = ScoreModel(
          id: sc.scoreModel.id,
          drId: sc.scoreModel.drId,
          gameCount: sc.scoreModel.gameCount,
          number: sc.scoreModel.number,
          score: inputScore,
          rank: sc.scoreModel.rank);
      accessor.upsert(newSm);
    }
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

class Coordinate {
  Coordinate(this.row, this.col);
  int row;
  int col;

  bool isNotEqual(int row, int col) {
    return this.row != row || this.col != col;
  }
}

class SpeechBubbleProperty {
  int score = 0;
  Coordinate coordinate = Coordinate(0, 0);
  bool isVisible = false;
  void clear() {
    isVisible = false;
    score = 0;
  }

  void setProperty(int score, int row, int col) {
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

  //　順位を設定
  void setRank() {
    // スコアでソート済みのリストを作る
    // 現在の入力値を参照するためcontrolloerで比較
    final sortList = List.of(scoreCellList)
      ..sort((a, b) => scoreCastInt(b.controller.text)
          .compareTo(scoreCastInt(a.controller.text)));

    // ソート済みリストから保持するlistのランクを更新
    var rank = 1;
    for (final s in sortList) {
      // 未入力のセルにはスコアなし
      if (scoreCellList[s.scoreModel.number].controller.text == '') {
        scoreCellList[s.scoreModel.number].scoreModel.rank = null;
        continue;
      }

      scoreCellList[s.scoreModel.number].scoreModel.rank = rank;
      rank++;
    }
  }

  ScoreModel getScoreModel(int col) {
    return scoreCellList[col].scoreModel;
  }

  String getScoreText(int col) {
    return scoreCellList[col].controller.text;
  }

  int getScore(int col) {
    return scoreCellList[col].scoreModel.score;
  }

  void setScore(int col, int score) {
    scoreCellList[col].controller.text = score.toString();
    scoreCellList[col].scoreModel.score = score;
  }

  void setScoreModel(int col, ScoreModel score) {
    scoreCellList[col].controller.text = score.scoreString;
    scoreCellList[col].scoreModel = score;
  }

  void setAllCursorToEnd() {
    for (final c in scoreCellList) {
      c.setCursorToEnd();
    }
  }

  int getFocusCol() {
    for (var i = 0; i < scoreCellList.length; i++) {
      if (scoreCellList[i].focusNode.hasFocus) {
        return i;
      }
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
      ret += s.scoreModel.score;
    }
    return ret;
  }

  bool validateScoreSum(int kind) {
    var total = 0;
    var cnt = 0;
    for (final c in scoreCellList) {
      total += c.scoreModel.score;
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
  ScoreModel scoreModel = ScoreModel();

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
    return scoreModel.score != scoreCastInt(controller.text);
  }

  bool validateInput() {
    // １文字単位の制限しかできなかったのでここでバリデート
    // マイナスが先頭以外にあったらエラー(数字に後ろにあったら)
    return !new RegExp(r'[0-9]-').hasMatch(controller.text);
  }

  bool clearScore() {
    scoreModel.score = 0;
    controller.text = '';
  }
}

int scoreCastInt(String src) {
  return src != '' ? int.parse(src) : 0;
}

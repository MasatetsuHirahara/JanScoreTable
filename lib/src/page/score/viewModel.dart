import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/accessor/table/gameJoinMemberAccesor.dart';
import 'package:flutter_app/src/accessor/table/gameSettingAccessor.dart';
import 'package:flutter_app/src/accessor/table/scoreAccessor.dart';
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
  GameSettingModel gameSettingModel = GameSettingModel()
    ..kind = KindValue.yonma.num;
  bool keyBoardVisible = false;
  bool isNeedScroll = false;

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

    // 行が追加されたらスクロールする
    if (incrementGameCountIfNeed()) {
      isNeedScroll = true;
    }

    notifyListeners();
  }

  // 必要ならgameCntを追加。追加したらtrueを返す
  bool incrementGameCountIfNeed([int index]) {
    if (index != null) {
      final inputGc = index ~/ joinedCount;

      // 末尾のgcの更新でなければ追加を考慮する必要なし
      if (rowPropertyList.length > inputGc + 1) {
        return false;
      }
    }
    // 末尾のスコアを確認して、必要数入力されていなければ追加しない
    if (rowPropertyList.last.isInputComplete(gameSettingModel.kind) == false) {
      return false;
    }

    // 追加
    addNewScoreRow(1);

    return true;
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

  void afterInput(int row, int col, InputValue inputValue) {
    print('afterInput $row , $col');

    final rowProperty = rowPropertyList[row];

    // スコアをセット
    rowProperty.setScore(col, inputValue.score);

    // 入力が完了していれば、ランクを計算
    if (rowProperty.isInputComplete(gameSettingModel.kind)) {
      rowProperty.setRank();
    } else {
      //完了していない場合はクリアする
      rowProperty.clearAllRank();
    }

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

      // vmで保存しているmodelをベースにdrIdとgcを補完
      // インスタンス生成時に、セットしていないため。
      final newSm = ScoreModel.fromMap(sc.scoreModel.toMap())
        ..drId = drId
        ..gameCount = row;
      accessor.upsert(newSm);
    }
  }

  bool isVisibleSuggest(int row) {
    // 入力完了数 - 1　が入力されていれば可能
    return rowPropertyList[row].isInputComplete(gameSettingModel.kind - 1);
  }

  List<errType> validateInput(int row) {
    final p = rowPropertyList[row];
    return p.validateInput(gameSettingModel);
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

  bool isInputComplete(int completeNum) {
    var inputCnt = 0;
    for (final s in scoreCellList) {
      if (s.scoreModel.scoreString != '') {
        inputCnt++;
        if (inputCnt >= completeNum) {
          return true;
        }
      }
    }
    return false;
  }

  /// 引数のcol以外の合算
  int getOtherTotalScore(int col) {
    var ret = 0;

    for (var i = 0; i < scoreCellList.length; i++) {
      if (i == col) {
        continue;
      }
      ret += scoreCellList[i].scoreModel.score;
    }

    return ret;
  }

  //　順位を設定
  void setRank() {
    // スコアでソート済みのリストを作る
    final sortList = List.of(scoreCellList)
      ..sort((a, b) => b.scoreModel.score.compareTo(a.scoreModel.score));

    // ソート済みリストから保持するlistのランクを更新
    var rank = 1;
    for (final s in sortList) {
      // 未入力のセルにはスコアなし
      if (s.scoreModel.number == null) {
        continue;
      }
      if (scoreCellList[s.scoreModel.number].scoreModel.scoreString == '') {
        scoreCellList[s.scoreModel.number].scoreModel.rank = null;
        continue;
      }

      scoreCellList[s.scoreModel.number].scoreModel.rank = rank;
      rank++;
    }
  }

  void setScore(int col, int score) {
    scoreCellList[col].scoreModel.score = score;
    scoreCellList[col].scoreModel.number = col;
  }

  void setScoreModel(int col, ScoreModel score) {
    scoreCellList[col].scoreModel = score;
  }

  void clearAllRank() {
    for (final s in scoreCellList) {
      s.scoreModel.rank = null;
    }
  }

  List<errType> validateInput(GameSettingModel gameSettingModel) {
    final ret = <errType>[];

    //　バリデートが必要ない
    if (!isNeedValidate(gameSettingModel)) {
      return ret;
    }

    if (!validateScoreSum(gameSettingModel)) {
      ret.add(errType.scoreSum);
    }

    if (!validateInputCnt(gameSettingModel)) {
      ret.add(errType.inputCnt);
    }

    return ret;
  }

  bool isNeedValidate(GameSettingModel gameSettingModel) {
    var cnt = 0;
    for (final c in scoreCellList) {
      if (c.scoreModel.scoreString == '') {
        continue;
      }
      cnt++;
    }

    // 入力が満たない場合は対象外
    if (cnt < gameSettingModel.kind) {
      return false;
    }

    return true;
  }

  bool validateScoreSum(GameSettingModel gameSettingModel) {
    var total = 0;
    for (final c in scoreCellList) {
      if (c.scoreModel.scoreString == '') {
        continue;
      }
      total += c.scoreModel.score;
    }

    // 0でなければエラー
    if (total != 0) {
      return false;
    }

    return true;
  }

  bool validateInputCnt(GameSettingModel gameSettingModel) {
    var cnt = 0;
    for (final c in scoreCellList) {
      if (c.scoreModel.scoreString == '') {
        continue;
      }
      cnt++;
    }

    if (cnt > gameSettingModel.kind) {
      return false;
    }

    return true;
  }
}

// スコア1セル分のproperty
class ScoreCellProperty {
  ScoreModel scoreModel = ScoreModel();

  bool clearScore() {
    scoreModel.score = 0;
  }
}

int scoreCastInt(String src) {
  return src != '' ? int.parse(src) : 0;
}

class InputValue {
  InputValue(this.score);
  int score;
}

enum errType { scoreSum, isNeedWind, koCnt, inputCnt }

extension errTypeExtension on errType {
  static final messages = {
    errType.scoreSum: 'スコアの合計が違います\n',
    errType.inputCnt: '不参加者は空にしてください\n',
  };
  String get message => messages[this];
}

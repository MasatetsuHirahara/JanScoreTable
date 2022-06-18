import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/accessor/table/gameJoinMemberAccesor.dart';
import 'package:flutter_app/src/accessor/table/gameSettingAccessor.dart';
import 'package:flutter_app/src/accessor/table/scoreAccessor.dart';
import 'package:flutter_app/src/common/util.dart';
import 'package:flutter_app/src/model/gameSettingModel.dart';
import 'package:flutter_app/src/model/scoreModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO
// スコアを毎回全体更新だと遅いかも

const maxGame = 30;
const defaultGameCount = 1;
const defaultJoinedCount = 4;

class OriginScoreViewModel extends ChangeNotifier {
  OriginScoreViewModel(this.ref, this.drId) {
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
    // 末尾のスコアを確認して、必要数入力されていなければ追加しない
    if (rowPropertyList.last.isInputComplete(gameSettingModel.kind) == false) {
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

  /// 入力後の処理
  void afterInput(int row, int col, int originScore) {
    // 入力内容を保存
    final rowProperty = rowPropertyList[row]..setOriginScore(col, originScore);

    // 入力が完了していれば、ランクとスコアを計算、設定のバリデーションを行う
    if (rowProperty.isInputComplete(gameSettingModel.kind)) {
      rowProperty
        ..setRank(gameSettingModel)
        ..calculateScore(gameSettingModel);
    } else {
      //完了していない場合はクリアする
      rowProperty.clearScore();
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

      // vmで保存しているmodelをベースにdrIdとgc,numberを補完
      // インスタンス生成時に、セットしていないため。
      final newS = ScoreModel.fromMap(sc.scoreModel.toMap())
        ..drId = drId
        ..gameCount = row
        ..number = col;
      accessor.upsert(newS);
    }
  }

  // bool validateRowScore(int row) {
  //   if (!validateRowScoreSum(row)) {
  //     return false;
  //   }
  //
  //   if (!rowPropertyList[row].validateKoCnt()) {
  //     return false;
  //   }
  // }

  // bool validateRowScoreSum(int row) {
  //   // 最後のゲームでなければ対象外
  //   if (row != rowPropertyList.length - 1) {
  //     return true;
  //     var cnt = 0;
  //     for (final p in rowPropertyList[row].scoreCellList) {
  //       if (p.scoreModel.originScoreString == '') {
  //         cnt++;
  //       }
  //     }
  //
  //     if (cnt < joinedCount) {
  //       return true;
  //     }
  //   }
  //
  //   return rowPropertyList[row].validateScoreSum(gameSettingModel.kind);
  // }

  bool isInputComplete(int row) {
    return rowPropertyList[row].isInputComplete(gameSettingModel.kind);
  }

  bool canVisibleSuggest(int row) {
    // 入力完了数 - 1　が入力されていれば可能
    return rowPropertyList[row].isInputComplete(gameSettingModel.kind - 1);
  }

  int getSuggestScore(int row, int col) {
    final total = rowPropertyList[row].getOtherTotalOriginScore(col);

    return (gameSettingModel.originPoint * gameSettingModel.kind) - total;
  }

  ValidateErr validateInput(int row) {
    final p = rowPropertyList[row];
    return p.validateInput(gameSettingModel);
  }
}

// スコアの1行分のproperty
class ScoreRowProperty {
  ScoreRowProperty(int joinedCounter) {
    addNewScore(joinedCounter);
  }

  List<ScoreCellProperty> scoreCellList = [];
  bool isNeedWind = false;

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
      if (s.scoreModel.originScoreString != '') {
        inputCnt++;
        if (inputCnt >= completeNum) {
          return true;
        }
      }
    }
    return false;
  }

  /// 引数のcol以外の合算
  int getOtherTotalOriginScore(int col) {
    var ret = 0;

    for (var i = 0; i < scoreCellList.length; i++) {
      if (i == col) {
        continue;
      }
      ret += scoreCellList[i].scoreModel.originScore;
    }

    return ret;
  }

  //　順位を設定
  void setRank(GameSettingModel gameSettingModel) {
    // スコアでソート済みのリストを作る
    final sortList = List.of(scoreCellList)
      ..sort((a, b) => b.scoreModel.wind.compareTo(a.scoreModel.wind))
      ..sort((a, b) =>
          b.scoreModel.originScore.compareTo(a.scoreModel.originScore));

    // ソート済みリストから保持するlistのランクを更新
    var rank = 0;
    var isNeedWind = false;
    int lastScore;
    var rankStock = 0;
    for (var i = 0; i < sortList.length; i++) {
      final s = sortList[i];
      if (s.scoreModel.number == null) {
        continue;
      }
      if (scoreCellList[s.scoreModel.number].scoreModel.originScoreString ==
          '') {
        scoreCellList[s.scoreModel.number].scoreModel.rank = null;
        continue;
      }

      // 同じ点数で、分けの場合
      if (lastScore == s.scoreModel.originScore &&
          gameSettingModel.samePointType == SamePointType.divide) {
        // 分けの場合は、rankはそのまま。
        // isSameOn
        scoreCellList[s.scoreModel.number].isSame = true;

        // 一つ前のフラグも更新。1回目のループで入ることはないので-1で対応
        final before = sortList[i - 1];
        scoreCellList[before.scoreModel.number].isSame = true;

        // 同着分の順位を下げるためrankStockを追加しておく
        rankStock++;
      } else {
        // 分けではないのでrankを更新
        scoreCellList[s.scoreModel.number].isSame = false;
        rank++;
        rank += rankStock;
        rankStock = 0;
        lastScore = s.scoreModel.originScore;

        // 同じ点数で風がセットされていない場合は警告を出す
        if (lastScore == s.scoreModel.originScore) {
          if (s.scoreModel.wind == WindType.none) {
            isNeedWind = true;
          }
        }
      }

      scoreCellList[s.scoreModel.number].scoreModel.rank = rank;
    }

    isNeedWind = isNeedWind;
  }

  void calculateScore(GameSettingModel gameSettingModel) {
    for (final s in scoreCellList) {
      // 順位はなしはスコアをなくす
      if (s.scoreModel.rank == null) {
        s.scoreModel.score = null;
        continue;
      }

      // オカ計算
      var point = s.scoreModel.originScore - gameSettingModel.basePoint;
      if (s.scoreModel.rank == 1) {
        var oka = (gameSettingModel.basePoint - gameSettingModel.originPoint) *
            gameSettingModel.kind;
        if (s.isSame) {
          // トップ同点はオカを分ける
          // TODO 3人同時の考慮
          oka ~/= 2;
        }
        point += oka;
      }

      // 切り上げ/切り捨てをして、下1桁は落とす
      point = MyUtil.customRound(point, gameSettingModel.roundType.num);
      point ~/= 10;

      // ウマを計算
      if (!s.isSame) {
        // 同点でない場合は素直に加算
        point += gameSettingModel.getRankPoint(s.scoreModel.rank);
      } else {
        // 同点の場合は分けて計算
        // TODO 3人同時の考慮
        point += gameSettingModel.getDivideRankPoint(s.scoreModel.rank);
      }

      // 飛びの計算
      if (s.scoreModel.originScore < 0) {
        point -= gameSettingModel.koPoint;
      }
      if (s.scoreModel.ko == 1) {
        // TODO 3人同時の考慮
        // 同時飛ばしもあり得る
        point += (gameSettingModel.koPoint * getWasKoCnt()) ~/ getKoCnt();
      }

      s.scoreModel.score = point;
    }
  }

  bool validateKoCnt() {
    // マイナス点がいるのにkoが０はおかしい
    if (getWasKoCnt() > 0) {
      if (getKoCnt() <= 0) {
        return false;
      }
    }

    return true;
  }

  int getWasKoCnt() {
    var ret = 0;
    for (final s in scoreCellList) {
      if (s.scoreModel.originScore < 0) {
        ret++;
      }
    }

    return ret;
  }

  int getKoCnt() {
    var ret = 0;
    for (final s in scoreCellList) {
      if (s.scoreModel.ko == 1) {
        ret++;
      }
    }

    return ret;
  }

  void clearScore() {
    for (final s in scoreCellList) {
      s.clearScore();
    }
  }

  ScoreModel getScoreModel(int col) {
    return scoreCellList[col].scoreModel;
  }

  // String getScoreText(int col) {
  //   return scoreCellList[col].scoreModel.scoreString;
  // }
  //
  // int getScore(int col) {
  //   return scoreCellList[col].scoreModel.score;
  // }
  //
  // void setScore(int col, int score) {
  //   scoreCellList[col].scoreModel.score = score;
  // }

  void setOriginScore(int col, int originScore) {
    scoreCellList[col].scoreModel
      ..originScore = originScore
      ..number = col;
  }

  void setScoreModel(int col, ScoreModel score) {
    scoreCellList[col].scoreModel = score;
  }

  // int sumScore() {
  //   var ret = 0;
  //   for (final s in scoreCellList) {
  //     ret += s.scoreModel.score;
  //   }
  //   return ret;
  // }

  bool validateOriginScoreSum(GameSettingModel gameSettingModel) {
    var total = 0;
    var cnt = 0;
    for (final c in scoreCellList) {
      if (c.scoreModel.originScoreString == '') {
        continue;
      }
      cnt++;
      total += c.scoreModel.originScore;
    }

    // 入力が満たない場合は対象外
    if (cnt < gameSettingModel.kind) {
      return true;
    }

    // 配給点と合わなければエラー
    if (total != gameSettingModel.originPoint * gameSettingModel.kind) {
      return false;
    }

    return true;
  }

  ValidateErr validateInput(GameSettingModel gameSettingModel) {
    final ret = ValidateErr();
    if (isNeedWind) {
      ret.isNeedWind = true;
    }

    if (!validateKoCnt()) {
      ret.errKoCnt = true;
    }

    if (!validateOriginScoreSum(gameSettingModel)) {
      ret.errScoreSum = true;
    }

    return ret;
  }
}

// スコア1セル分のproperty
class ScoreCellProperty {
  ScoreCellProperty() {}
  ScoreModel scoreModel = ScoreModel();
  bool isSame = false; // 同点が他にいるか？

  void clearScore() {
    scoreModel
      ..score = null
      ..rank = null;
    isSame = false;
  }
}

class ValidateErr {
  bool isNeedWind = false;
  bool errScoreSum = false;
  bool errKoCnt = false;

  bool hasErr() {
    return isNeedWind || errScoreSum || errKoCnt;
  }

  bool noErr() {
    return !hasErr();
  }
}

int scoreCastInt(String src) {
  return src != '' ? int.parse(src) : 0;
}

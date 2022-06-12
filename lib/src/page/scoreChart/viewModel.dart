import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/page/scoreChart/view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessor/table/gameJoinMemberAccesor.dart';
import '../../accessor/table/gameSettingAccessor.dart';
import '../../accessor/table/scoreAccessor.dart';
import '../../model/gameSettingModel.dart';

class ResultProperty {
  ResultProperty();
  int firstCnt = 0;
  int secondCnt = 0;
  int thirdCnt = 0;
  int fourthCnt = 0;
  int joinCnt = 0;

  double averageRation() {
    if (joinCnt == 0) {
      return 0;
    }

    var total = firstCnt * 1;
    total += secondCnt * 2;
    total += thirdCnt * 3;
    total += fourthCnt * 4;

    return total / joinCnt;
  }

  double rentaiRation() {
    if (joinCnt == 0) {
      return 0;
    }
    return (firstCnt + secondCnt) / joinCnt * 100;
  }

  double firstRation() {
    if (joinCnt == 0) {
      return 0;
    }
    return firstCnt / joinCnt * 100;
  }

  double secondRation() {
    if (joinCnt == 0) {
      return 0;
    }
    return secondCnt / joinCnt * 100;
  }

  double thirdRation() {
    if (joinCnt == 0) {
      return 0;
    }
    return thirdCnt / joinCnt * 100;
  }

  double fourthRation() {
    if (joinCnt == 0) {
      return 0;
    }
    return fourthCnt / joinCnt * 100;
  }

  void cntUp(int rank) {
    joinCnt++;

    switch (rank) {
      case 1:
        firstCnt++;
        break;
      case 2:
        secondCnt++;
        break;
      case 3:
        thirdCnt++;
        break;
      case 4:
        fourthCnt++;
        break;
      default:
        break;
    }
  }
}

class ScoreChartViewModel extends ChangeNotifier {
  ScoreChartViewModel(this.ref, this.drId) {
    listenGameSetting();
    listenGameJoinedMember();
    listenScore();
  }
  Ref ref;
  int drId;
  double maxX = 0;
  double maxY = 0;
  double minY = 0;

  List<LineChartBarData> chartBarDataList = [];
  List<ResultProperty> resultList = [];
  List<String> nameList = [];
  bool isVisibleFourth = true;

  void listenGameJoinedMember() {
    localFunc(GameJoinMemberAccessor p) {
      if (p.drIdMap.containsKey(drId)) {
        final memberList = p.drIdMap[drId];
        for (var i = 0; i < memberList.length; i++) {
          if (nameList.length <= i) {
            nameList.add(memberList[i].name);
            continue;
          } else {
            nameList[i] = memberList[i].name;
          }
        }
      }

      notifyListeners();
    }

    final accessor = ref.read(gameJoinMemberAccessor);
    if (accessor.isInitialized) {
      localFunc(accessor);
    }

    ref.listen<GameJoinMemberAccessor>(gameJoinMemberAccessor,
        (previous, next) {
      if (next.isInitialized) {
        localFunc(next);
      }
    });
  }

  void chaneMinMaxYIfNeed(double src) {
    if (minY > src) {
      minY = src;
      return;
    }

    if (maxY < src) {
      maxY = src;
      return;
    }
  }

  void listenScore() {
    // ignore: prefer_function_declarations_over_variables
    localFunc(ScoreAccessor accessor) {
      if (accessor.scoreViewMap.containsKey(drId)) {
        final drIdScoreView = accessor.scoreViewMap[drId];
        maxX = drIdScoreView.maxGameCount + 1.0;

        initChartBarDataList(drIdScoreView.maxNumber + 1);
        initResultList(drIdScoreView.maxNumber + 1);
        for (var i = 0; i <= drIdScoreView.maxGameCount; i++) {
          for (var j = 0; j <= drIdScoreView.maxNumber; j++) {
            // yPointは累積になるようにする
            // スコアがなければ前回のポイントから変動なし
            if (drIdScoreView.map[i].containsKey(j) == false) {
              final flSpot =
                  FlSpot((i + 1).toDouble(), chartBarDataList[j].spots[i].y);
              chartBarDataList[j].spots.add(flSpot);
              continue;
            }
            if (drIdScoreView.map[i][j].scoreString == '') {
              final flSpot =
                  FlSpot((i + 1).toDouble(), chartBarDataList[j].spots[i].y);
              chartBarDataList[j].spots.add(flSpot);
              continue;
            }
            var yPoint = drIdScoreView.map[i][j].score.toDouble();
            if (chartBarDataList[j].spots.length <= i) {
              print('aa');
            }
            yPoint += chartBarDataList[j].spots[i].y;

            // MinMaxの更新
            chaneMinMaxYIfNeed(yPoint);

            final flSpot = FlSpot((i + 1).toDouble(), yPoint);
            chartBarDataList[j].spots.add(flSpot);

            resultList[j].cntUp(drIdScoreView.map[i][j].rank);
          }
        }
      }
      notifyListeners();
    }

    final accessor = ref.read(scoreAccessor);
    if (accessor.isInitialized) {
      localFunc(accessor);
    }

    ref.listen<ScoreAccessor>(scoreAccessor, (previous, next) {
      if (next.isInitialized) {
        localFunc(next);
      }
    });
  }

  void initChartBarDataList(int num) {
    chartBarDataList = [];
    for (var i = 0; i < num; i++) {
      final data = LineChartBarData(
          spots: [const FlSpot(0, 0)],
          colors: [numberColorExtension.fromInt(i).color]);
      chartBarDataList.add(data);
    }
  }

  void initResultList(int num) {
    resultList = [];
    for (var i = 0; i < num; i++) {
      resultList.add(ResultProperty());
    }
  }

  void listenGameSetting() {
    localFunc(GameSettingAccessor p) {
      if (p.drIdMap.containsKey(drId)) {
        final gs = p.drIdMap[drId];
        isVisibleFourth = gs.kind == KindValue.YONMA.num;
      }
      notifyListeners();
    }

    final accessor = ref.read(gameSettingAccessor);
    if (accessor.isInitialized) {
      localFunc(accessor);
    }
    ref.listen<GameSettingAccessor>(gameSettingAccessor, (previous, next) {
      if (next.isInitialized) {
        localFunc(next);
      }
    });
  }
}

class GraphLineProperty {
  GraphLineProperty(this.name);
  GraphLineProperty.fromChartData(this.chartBarData);

  LineChartBarData chartBarData;
  String name;
}

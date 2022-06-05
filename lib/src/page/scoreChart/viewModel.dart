import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/page/scoreChart/view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessor/table/gameJoinMemberProvider.dart';
import '../../accessor/table/scoreProvider.dart';

class ScoreChartViewModel extends ChangeNotifier {
  ScoreChartViewModel(this.ref, this.drId) {
    listenGameJoinedMember();
    listenScore();
  }
  Ref ref;
  int drId;
  double maxX = 0;
  double maxY = 0;
  double minY = 0;

  List<LineChartBarData> chartBarDataList = [];
  List<String> nameList = [];

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
        for (var i = 0; i <= drIdScoreView.maxGameCount; i++) {
          for (var j = 0; j <= drIdScoreView.maxNumber; j++) {
            // yPointは累積になるようにする
            if (drIdScoreView.map[i].containsKey(j) == false) {
              continue;
            }
            if (drIdScoreView.map[i][j].scoreString == '') {
              continue;
            }
            var yPoint = drIdScoreView.map[i][j].score.toDouble();
            yPoint += chartBarDataList[j].spots[i].y;

            // MinMaxの更新
            chaneMinMaxYIfNeed(yPoint);

            final flSpot = FlSpot((i + 1).toDouble(), yPoint);
            chartBarDataList[j].spots.add(flSpot);
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
}

class GraphLineProperty {
  GraphLineProperty(this.name);
  GraphLineProperty.fromChartData(this.chartBarData);

  LineChartBarData chartBarData;
  String name;
}

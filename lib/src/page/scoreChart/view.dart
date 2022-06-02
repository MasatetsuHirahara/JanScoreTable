import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../provider/gameJoinMemberProvider.dart';
import '../../provider/scoreProvider.dart';
import '../../widget/text.dart';

enum numberColor {
  red,
  blue,
  green,
  orange,
  black,
}

extension numberColorExtension on numberColor {
  static final colors = {
    numberColor.red: Colors.red,
    numberColor.blue: Colors.indigoAccent,
    numberColor.green: Colors.green,
    numberColor.orange: Colors.orange,
    numberColor.black: Colors.black,
  };
  static final numbers = {
    numberColor.red: 0,
    numberColor.blue: 1,
    numberColor.green: 2,
    numberColor.orange: 3,
    numberColor.black: 4,
  };

  Color get color => colors[this];
  int get number => numbers[this];
  static numberColor fromInt(int src) {
    for (final v in numberColor.values) {
      if (src == v.number) {
        return v;
      }
    }
    return numberColor.black;
  }
}

final scoreChartViewProvider = ChangeNotifierProvider.autoDispose
    .family<ScoreChartViewModel, int>((ref, drId) {
  return ScoreChartViewModel(ref, drId);
});

class GraphLineProperty {
  GraphLineProperty(this.name);
  GraphLineProperty.fromChartData(this.chartBarData);

  LineChartBarData chartBarData;
  String name;
}

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
  @override
  void dispose() {
    print('dipose ScoreChartViewModel');
  }

  void listenGameJoinedMember() {
    localFunc(GameJoinMemberNotifier p) {
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

    final provider = ref.read(gameJoinMemberProvider);
    if (provider.isInitialized) {
      localFunc(provider);
    }

    ref.listen<GameJoinMemberNotifier>(gameJoinMemberProvider,
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
    localFunc(ScoreNotifier p) {
      if (p.scoreViewMap.containsKey(drId)) {
        final drIdScoreView = p.scoreViewMap[drId];
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

    final provider = ref.read(scoreProvider);
    if (provider.isInitialized) {
      localFunc(provider);
    }

    ref.listen<ScoreNotifier>(scoreProvider, (previous, next) {
      if (next.isInitialized) {
        localFunc(next);
      }
    });
  }

  void initChartBarDataList(int num) {
    chartBarDataList = [];
    for (var i = 0; i < num; i++) {
      final data = LineChartBarData(
          spots: [FlSpot(0, 0)],
          colors: [numberColorExtension.fromInt(i).color]);
      chartBarDataList.add(data);
    }
  }
}

class ScoreChartPage extends ConsumerWidget {
  static Route<dynamic> route({
    @required int drId,
  }) {
    return MaterialPageRoute<dynamic>(
        builder: (_) => ScoreChartPage(),
        settings: RouteSettings(arguments: drId),
        fullscreenDialog: true);
  }

  int drId;

  @override
  void dispose() {
    print('dispose !!!!!!!!');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 引数処理
    drId = ModalRoute.of(context).settings.arguments as int;
    final provider = ref.watch(scoreChartViewProvider(drId));
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('スコアグラフ'),
        leading: IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                provider.chartBarDataList.isNotEmpty
                    ? chart(provider)
                    : Expanded(
                        child: Container(
                        child: Align(
                          alignment: Alignment.center,
                          child: HeadingText('表示するデータがありません'),
                        ),
                      )),
                SizedBox(
                  height: 50.h,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 0, 0, 0.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.nameList.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width:
                              (screenSize.width - 8) / provider.nameList.length,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              '${provider.nameList[index]}',
                              style: TextStyle(
                                color:
                                    numberColorExtension.fromInt(index).color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: 8.h,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget chart(ScoreChartViewModel vm) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          baselineY: 0,
          minX: 0, //x軸最小値
          maxX: vm.maxX, //x軸最大値
          minY: vm.minY - 10.0, //y軸最小値
          maxY: vm.maxY + 10.0, //y
          lineBarsData: vm.chartBarDataList,
          titlesData: FlTitlesData(
            show: true,
            topTitles: SideTitles(
              showTitles: false,
            ),
            bottomTitles: SideTitles(
              showTitles: true,
              // 整数値だけラベルに表示
              getTitles: (double value) {
                if (value - value.floor() != 0) {
                  return '';
                }
                return value.toInt().toString();
              },
            ),
            leftTitles: SideTitles(
              showTitles: true,
              // 整数値だけラベルに表示
              getTitles: (double value) {
                if (value - value.floor() != 0) {
                  return '';
                }
                if (value % 5 != 0) {
                  return '';
                }
                return value.toInt().toString();
              },
            ),
            rightTitles: SideTitles(
              showTitles: true,
              // 整数値だけラベルに表示
              getTitles: (double value) {
                if (value - value.floor() != 0) {
                  return '';
                }
                if (value % 5 != 0) {
                  return '';
                }
                return value.toInt().toString();
              },
            ),
          ),
        ),
      ),
    ),
  );
}

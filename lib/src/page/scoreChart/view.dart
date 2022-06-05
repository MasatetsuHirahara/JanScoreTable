import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/page/scoreChart/viewModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

final _viewModel = ChangeNotifierProvider.autoDispose
    .family<ScoreChartViewModel, int>((ref, drId) {
  return ScoreChartViewModel(ref, drId);
});

// ignore: must_be_immutable
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
  Widget build(BuildContext context, WidgetRef ref) {
    // 引数処理
    drId = ModalRoute.of(context).settings.arguments as int;
    final provider = ref.watch(_viewModel(drId));
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('スコアグラフ'),
        leading: IconButton(
          icon: const Icon(Icons.clear),
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
                        child: const Align(
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
      padding: const EdgeInsets.all(16),
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

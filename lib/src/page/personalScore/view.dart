import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/page/personalScore/viewModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widget/text.dart';

const buttonWidth = 150.0;

final _viewModel = ChangeNotifierProvider.autoDispose
    .family<PersonalScoreViewModel, int>((ref, mId) {
  return PersonalScoreViewModel(ref, mId);
});

class PersonalScorePage extends ConsumerWidget {
  static Route<dynamic> route({
    @required int mId,
  }) {
    return MaterialPageRoute<dynamic>(
        builder: (_) => PersonalScorePage(),
        settings: RouteSettings(arguments: mId),
        fullscreenDialog: false);
  }

  @override
  void dispose() {
    print('dispose !!!!!!!!');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 引数処理
    final mID = ModalRoute.of(context).settings.arguments as int;

    final vm = ref.watch(_viewModel(mID));

    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
          appBar: AppBar(
            title: Text('${vm.name}'),
            leading: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => Navigator.of(context).pop(),
            ),
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(
                  icon: HeadingText(
                    '4麻',
                    color: Colors.white,
                  ),
                ),
                Tab(
                  icon: HeadingText(
                    '3麻',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [tabView(vm.result4, true), tabView(vm.result3, false)],
          )),
    );
  }
}

Widget tabView(ResultProperty result, bool isVisibleFourth) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              scoreRow('通算スコア', result.totalScore),
              scoreRow('通算G', result.totalValue, trailing: 'G'),
              rankRow(
                  '平均順位', result.averageRation().toStringAsFixed(rationDigit)),
              rankRow('連対率',
                  '${result.rentaiRation().toStringAsFixed(rationDigit)} %'),
              rankRow('1着', rankFormat(result.firstCnt, result.firstRation())),
              rankRow(
                  '2着', rankFormat(result.secondCnt, result.secondRation())),
              rankRow('3着', rankFormat(result.thirdCnt, result.thirdRation())),
              Visibility(
                  visible: isVisibleFourth,
                  child: rankRow('4着',
                      rankFormat(result.fourthCnt, result.fourthRation()))),
            ],
          ),
        ),
      ),
    ),
  );
}

const rationDigit = 2;
String rankFormat(int cnt, double ration) {
  final rationStr = ration.toStringAsFixed(rationDigit);
  return '$cnt回 / $rationStr%';
}

Widget scoreRow(String title, int score, {String trailing}) {
  return Row(
    children: [
      Expanded(
        child: Align(
          alignment: Alignment.center,
          child: HeadingText(title),
        ),
      ),
      Expanded(
        child: Align(
          alignment: Alignment.center,
          child: ScoreText(score, trailing: trailing),
        ),
      ),
    ],
  );
}

Widget rankRow(String title, String value, {Color color}) {
  return Row(
    children: [
      Expanded(
        child: Align(
          alignment: Alignment.center,
          child: HeadingText(title),
        ),
      ),
      Expanded(
        child: Align(
          alignment: Alignment.center,
          child: color == null
              ? NormalText(value)
              : NormalText(value, color: color),
        ),
      ),
    ],
  );
}

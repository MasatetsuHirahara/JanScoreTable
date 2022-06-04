import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/accessor/table/gameSettingProvider.dart';
import 'package:flutter_app/src/model/gameSettingModel.dart';
import 'package:flutter_app/src/widget/text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../accessor/table/chipScoreProvider.dart';
import '../../accessor/table/scoreProvider.dart';

final _viewModel = ChangeNotifierProvider.autoDispose
    .family<AdjustmentViewModel, int>((ref, drId) {
  return AdjustmentViewModel(ref, drId);
});

class AdjustmentViewModel extends ChangeNotifier {
  AdjustmentViewModel(this.ref, this.drId) {
    listenGameSetting();
    listenScore();
    listenChipScore();
  }

  Ref ref;
  int drId;
  List<PointProperty> pointList = [];
  GameSettingModel gameSetting;
  List<int> totalList = [];
  List<ChipScoreModelEx> chipScoreList;
  TextEditingController placeFeeController = TextEditingController()
    ..text = '0';

  void setPointPropertyList() {
    if (gameSetting == null) {
      return;
    }
    if (chipScoreList == null) {
      return;
    }

    // 場代をセット
    placeFeeController
      ..text = gameSetting.placeFee.toString()
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: placeFeeController.text.length),
      );

    // 一人あたりの場代を計算。１の位は余りとしてトップに分配
    var placeFeePerOne = 0;
    var reminder = 0;
    final placeFee = gameSetting.placeFee;
    if (placeFee != 0) {
      placeFeePerOne = (placeFee ~/ pointList.length);
      final onesPlace = int.parse(placeFeePerOne.toString().substring(0, 1));
      placeFeePerOne -= onesPlace;
      reminder = (placeFee % pointList.length) + onesPlace * pointList.length;
    }

    // 表示するポイントを計算する
    // chipScoreListはgjm分のindexを持っているのでchipScoreをベースにする
    pointList = [];
    var topIndex = 0;
    var topScore = 0;
    for (final cs in chipScoreList) {
      final name = cs.name;
      final chipPoint = cs.score * gameSetting.chipRate;
      var point = chipPoint;
      if (totalList.length > cs.number) {
        final total = totalList[cs.number];
        if (total > topScore) {
          topIndex = cs.number;
          topScore = total;
        }
        point += totalList[cs.number] * gameSetting.rate;
      }
      pointList.add(PointProperty(name, point, chipPoint, placeFeePerOne));
    }

    // topにあまりを追加
    pointList[topIndex].addPlaceFee(reminder);

    notifyListeners();
  }

  void listenGameSetting() {
    final accessor = ref.watch(gameSettingAccessor);
    if (accessor.isInitialized) {
      if (accessor.drIdMap.containsKey(drId)) {
        gameSetting = accessor.drIdMap[drId];
        setPointPropertyList();
      }
    }
  }

  void listenScore() {
    final accessor = ref.watch(scoreAccessor);
    if (accessor.isInitialized) {
      if (accessor.scoreViewMap.containsKey(drId)) {
        final drIdScoreView = accessor.scoreViewMap[drId];
        totalList = [];
        for (var i = 0; i <= drIdScoreView.maxGameCount; i++) {
          for (var j = 0; j <= drIdScoreView.maxNumber; j++) {
            if (drIdScoreView.map[i].containsKey(j) == false) {
              continue;
            }
            if (i == 0) {
              totalList.add(drIdScoreView.map[i][j].score);
              continue;
            }
            totalList[j] += drIdScoreView.map[i][j].score;
          }
        }
        setPointPropertyList();
      }
    }
  }

  void listenChipScore() {
    final accessor = ref.watch(chipScoreAccessor);
    if (accessor.isInitialized) {
      if (accessor.drIdMap.containsKey(drId)) {
        chipScoreList = accessor.drIdMap[drId];
        setPointPropertyList();
      }
    }
  }

  void afterPlaceFeeInput() {
    final fee = int.parse(placeFeeController.text);
    if (fee == null) {
      return;
    }
    gameSetting.placeFee = fee;
    ref.read(gameSettingAccessor).upsert(gameSetting);
  }
}

class PointProperty {
  PointProperty(this.name, this.point, this.chipPoint, this.placeFee) {}

  String name;
  int point;
  int chipPoint;
  int placeFee;

  int get totalPoint {
    return point + chipPoint - placeFee;
  }

  void addPlaceFee(int fee) {
    placeFee += fee;
  }
}

const cellHeight = 50.0;

class PlaceFeeCard extends StatelessWidget {
  const PlaceFeeCard(this.controller, this.onSubmitted);

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.black,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: ListTile(
        title: HeadingText('場代'),
        trailing: SizedBox(
          width: 100.w,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              FilteringTextInputFormatter.singleLineFormatter,
            ],
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }
}

class PointCard extends StatelessWidget {
  const PointCard(this.property);

  final PointProperty property;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.black,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: ExpansionTile(
        title: HeadingText(property.name),
        trailing: ScoreText(
          property.totalPoint,
          trailing: 'G',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('スコア  '),
                ScoreText(
                  property.point,
                  trailing: 'G',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('チップ代  '),
                ScoreText(
                  property.chipPoint,
                  trailing: 'G',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 8.0,
          )
        ],
      ),
    );
  }
}

class AdjustmentPage extends ConsumerWidget {
  static Route<dynamic> route({
    @required int drId,
  }) {
    return MaterialPageRoute<dynamic>(
        builder: (_) => AdjustmentPage(),
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

    // provider処理
    final provider = ref.watch(_viewModel(drId));

    return Scaffold(
        appBar: AppBar(
          title: Text('精算'),
          leading: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  for (final p in provider.pointList) PointCard(p),
                  SizedBox(
                    height: 16,
                  ),
                  PlaceFeeCard(provider.placeFeeController, (String value) {
                    provider.setPointPropertyList();
                  }),
                ],
              ),
            ),
          ),
        ));

    return Scaffold(
      appBar: AppBar(
        title: Text('精算'),
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
                SizedBox(
                  height: cellHeight * provider.pointList.length,
                  child: ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: provider.pointList.length,
                    itemBuilder: (context, index) {
                      return scoreRowWidget(index, provider);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget scoreRowWidget(int index, AdjustmentViewModel viewModel) {
  final rowProperty = viewModel.pointList[index];
  return Container(
    child: Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Text('${rowProperty.name}'),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 0, 0, 0),
              child: Text(
                '${rowProperty.point}',
                style: TextStyle(
                  backgroundColor: Colors.red,
                  color: rowProperty.point >= 0 ? Colors.black : Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

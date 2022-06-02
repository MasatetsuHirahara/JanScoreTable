import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/model/gameSettingModel.dart';
import 'package:flutter_app/src/provider/gameSettingProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/chipScoreProvider.dart';
import '../../provider/scoreProvider.dart';

final adjustmentViewProvider = ChangeNotifierProvider.autoDispose
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
  List<ScoreRowProperty> scoreRowList = [];
  GameSettingModel gameSetting;
  List<int> totalList = [];
  List<ChipScoreView> chipScoreList;
  void setScoreRowPropertyList() {
    if (gameSetting == null) {
      return;
    }
    if (chipScoreList == null) {
      return;
    }

    scoreRowList = [];
    for (final cs in chipScoreList) {
      final name = cs.name;
      final chipPoint = cs.score * gameSetting.chipRate;
      var point = chipPoint;
      if (totalList.length > cs.number) {
        point += totalList[cs.number] * gameSetting.rate;
      }
      scoreRowList.add(ScoreRowProperty(name, point, chipPoint));
    }

    notifyListeners();
  }

  void listenGameSetting() {
    final provider = ref.watch(gameSettingProvider);
    if (provider.isInitialized) {
      if (provider.drIdMap.containsKey(drId)) {
        gameSetting = provider.drIdMap[drId];
        setScoreRowPropertyList();
      }
    }
  }

  void listenScore() {
    final provider = ref.watch(scoreProvider);
    if (provider.isInitialized) {
      if (provider.scoreViewMap.containsKey(drId)) {
        final drIdScoreView = provider.scoreViewMap[drId];
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
        setScoreRowPropertyList();
      }
    }
  }

  void listenChipScore() {
    final provider = ref.watch(chipScoreProvider);
    if (provider.isInitialized) {
      if (provider.drIdMap.containsKey(drId)) {
        chipScoreList = provider.drIdMap[drId];
        setScoreRowPropertyList();
      }
    }
  }
}

class ScoreRowProperty {
  ScoreRowProperty(this.name, this.point, this.chipPoint) {}

  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();

  String name;
  int point;
  int chipPoint;
}

const cellHeight = 50.0;

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
    final provider = ref.watch(adjustmentViewProvider(drId));

    return Scaffold(
      appBar: AppBar(
        title: Text('精算'),
        leading: IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: cellHeight * provider.scoreRowList.length,
              child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                itemCount: provider.scoreRowList.length,
                itemBuilder: (context, index) {
                  return scoreRowWidget(index, provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget scoreRowWidget(int index, AdjustmentViewModel viewModel) {
  final rowProperty = viewModel.scoreRowList[index];
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

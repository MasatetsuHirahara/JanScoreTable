import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/page/adjustment/view.dart';
import 'package:flutter_app/src/page/gameSetting/view.dart';
import 'package:flutter_app/src/page/originScore/viewModel.dart';
import 'package:flutter_app/src/widget/text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chipScore/view.dart';
import '../scoreChart/view.dart';

const subjectCellWidth = 30.0;
const nameCellHeight = 70.0;
const totalCellHeight = 70.0;
const scoreCellHeight = 70.0;
const columnDividerHeight = 1.0;
const columnBoldDividerHeight = 2.0;
const rowDividerWidth = 1.0;

final _viewModel = ChangeNotifierProvider.autoDispose
    .family<OriginScoreViewModel, int>((ref, drId) {
  return OriginScoreViewModel(ref, drId);
});

// ignore: must_be_immutable
class OriginScorePage extends ConsumerWidget {
  static Route<dynamic> route({
    @required int drId,
  }) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => OriginScorePage(),
      settings: RouteSettings(arguments: drId),
    );
  }

  int drId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    drId = ModalRoute.of(context).settings.arguments as int;

    final vm = ref.watch(_viewModel(drId));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('スコア'),
        leading: const BackButton(),
        actions: [
          IconButton(
            onPressed: () {
              transitionProcess(context, vm);
              Navigator.of(context)
                  .push<dynamic>(AdjustmentPage.route(drId: drId));
            },
            icon: const Icon(Icons.paid_rounded),
          ),
          IconButton(
            onPressed: () {
              transitionProcess(context, vm);
              Navigator.of(context)
                  .push<dynamic>(ChipScorePage.route(drId: drId));
            },
            icon: const Icon(Icons.copyright_rounded),
          ),
          IconButton(
            onPressed: () {
              transitionProcess(context, vm);
              Navigator.of(context)
                  .push<dynamic>(ScoreChartPage.route(drId: drId));
            },
            icon: const Icon(Icons.show_chart),
          ),
          IconButton(
              onPressed: () {
                transitionProcess(context, vm);
                Navigator.of(context)
                    .push<dynamic>(GameSettingPage.route(drId: drId));
              },
              icon: const Icon(Icons.settings)),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              Column(
                children: [
                  nameSection(context, nameCellHeight, vm.nameList),
                  myDivider(screenSize.width, columnDividerHeight),
                  totalSection(context, totalCellHeight, vm),
                  myDivider(screenSize.width, columnBoldDividerHeight),
                  scoreSection(context, scoreCellHeight, vm),
                ],
              ),
              // Align(
              //   alignment: Alignment.topLeft,
              //   child: speechBubble(context, pProvider),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget nameSection(BuildContext context, double height, List<String> list) {
    final screenSize = MediaQuery.of(context).size;

    return SizedBox(
      height: height,
      width: screenSize.width,
      child: Row(children: [
        SizedBox(
            width: subjectCellWidth,
            height: height,
            child: subjectCell(height, '')),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: (screenSize.width - subjectCellWidth) / list.length,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Center(
                          child: Text('${list[index]}'),
                        ),
                      ),
                    ),
                    myDivider(rowDividerWidth, height)
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget totalSection(BuildContext context, double height,
      OriginScoreViewModel scoreViewModel) {
    final screenSize = MediaQuery.of(context).size;

    return SizedBox(
      height: height,
      width: screenSize.width,
      child: Row(children: [
        SizedBox(
            width: subjectCellWidth,
            height: height,
            child: subjectCell(height, '計')),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: scoreViewModel.totalPointList.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  SizedBox(
                    width: (screenSize.width - subjectCellWidth) /
                        scoreViewModel.totalPointList.length,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: Center(
                              child: ScoreText(
                                  scoreViewModel.totalPointList[index]),
                            ),
                          ),
                        ),
                        myDivider(rowDividerWidth, height)
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget scoreSection(
      BuildContext context, double height, OriginScoreViewModel vm) {
    final screenSize = MediaQuery.of(context).size;
    var totalHeight = MediaQuery.of(context).padding.top + // safeArea
        AppBar().preferredSize.height +
        nameCellHeight +
        columnDividerHeight +
        totalCellHeight +
        columnBoldDividerHeight +
        (scoreCellHeight + columnDividerHeight) *
            vm.rowPropertyList.length.toDouble();
    // if (vm.keyBoardVisible) {
    //   totalHeight += MediaQuery.of(context).viewInsets.bottom;
    // }

    final isScroll = screenSize.height <= totalHeight;
    print('scoreSection $isScroll');
    return Expanded(
      child: ListView.builder(
        physics: isScroll ? null : const NeverScrollableScrollPhysics(),
        itemCount: vm.rowPropertyList.length,
        itemBuilder: (context, index) {
          var rowColor = Colors.white;
          final err = vm.validateInput(index);
          if (err.hasErr()) {
            rowColor = Colors.yellow;
          }

          return Column(children: [
            scoreRow(context, height, index, vm, rowColor),
            myDivider(screenSize.width, columnDividerHeight),
          ]);
        },
      ),
    );
  }

  Future<int> waringAlert(BuildContext context, ValidateErr err) async {
    var errText = '';
    if (err.errScoreSum) {
      errText += 'スコアの合計が違います\n';
    }
    if (err.isNeedWind) {
      errText += '風の設定をしてください\n';
    }
    if (err.errKoCnt) {
      errText += '飛びの設定をしてください\n';
    }

    return showDialog<int>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('エラー詳細'),
          content: Text(errText),
          actions: <Widget>[
            TextButton(
              child: const Text('閉じる'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
        ;
      },
    );
  }

  Widget scoreRow(BuildContext context, double height, int rowIndex,
      OriginScoreViewModel vm, Color rowColor) {
    final screenSize = MediaQuery.of(context).size;
    final rowProperty = vm.rowPropertyList[rowIndex];

    final validateErr = vm.validateInput(rowIndex);
    return SizedBox(
      height: height,
      width: screenSize.width,
      child: Row(children: [
        SizedBox(
          width: subjectCellWidth,
          height: height,
          child: Stack(
            children: [
              subjectCell(height, '${(rowIndex + 1).toString()}'),
              Visibility(
                visible: validateErr.hasErr(),
                child: Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: const Icon(
                      Icons.warning_outlined,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      waringAlert(context, validateErr);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: rowProperty.scoreCellList.length,
              itemBuilder: (context, index) {
                final cell = rowProperty.scoreCellList[index];
                final os = cell.scoreModel.originScoreString != ''
                    ? cell.scoreModel.originScore * 100
                    : null;
                return SizedBox(
                  width: (screenSize.width - subjectCellWidth) /
                      rowProperty.scoreCellList.length,
                  child: Container(
                    color: rowColor,
                    child: Column(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              int suggest;
                              if (vm.canVisibleSuggest(rowIndex)) {
                                suggest = vm.getSuggestScore(rowIndex, index);
                              }
                              final originScore = await pointKeyboard(context,
                                  cell.scoreModel.originScoreString, suggest);
                              vm.afterInput(rowIndex, index, originScore);
                            },
                            child: Center(child: ScoreText(os, fontSize: 20)),
                          ),
                        ),
                        Divider(),
                        ScoreText(cell.scoreModel.score, fontSize: 16),
                      ],
                    ),
                  ),
                );
              }),
        ),
      ]),
    );
  }

  Widget bubble(OriginScoreViewModel scoreViewModel, int row, int col) {
    // if (scoreViewModel.speechBubbleProperty.isVisible == false) {
    //   return Container();
    // }
    //
    // // 表示対象のセルでない場合は適当なcontainerを返す
    // // フォーカスセル
    // if (scoreViewModel.speechBubbleProperty.coordinate.row != row + 1 ||
    //     scoreViewModel.speechBubbleProperty.coordinate.col != col) {
    //   return Container();
    // // }
    // return Padding(
    //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
    //   child: Container(
    //     decoration: const ShapeDecoration(
    //       shape: SpeechBubble(),
    //       color: Colors.blueGrey,
    //     ),
    //     child: Padding(
    //       padding: const EdgeInsets.all(0),
    //       child: Center(
    //         child: TextButton(
    //           child: NormalText('${scoreViewModel.speechBubbleProperty.score}'),
    //           onPressed: () {
    //             keyBoardHideProcess(scoreViewModel);
    //             scoreViewModel.speechBubbleTap();
    //           },
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }

  Widget subjectCell(double height, String title) {
    return Container(
      color: Colors.blueGrey,
      child: Align(
        alignment: Alignment.center,
        child: NormalText(title),
      ),
    );
  }

  Widget myDivider(double width, double height) {
    return SizedBox(
        width: width, height: height, child: Container(color: Colors.black));
  }

  Future<int> pointKeyboard(
      BuildContext context, String defaultStr, int suggest) async {
    return showDialog<int>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return KeyBoard(defaultStr, suggest);
      },
    );
  }

// キーボード表示するときのあれこれ
  void keyBoardShowProcess(OriginScoreViewModel viewModel) {
    // viewModel.setKeyBoardVisible(true);
  }

// キーボード閉じるするときのあれこれ
  void keyBoardHideProcess(OriginScoreViewModel viewModel) {
    //final coordinate = viewModel.getFocusCoordinate();
    // if (coordinate != null) {
    //   viewModel.rowPropertyList[coordinate.row].scoreCellList[coordinate.col]
    //       .focusNode
    //       .unfocus();
    // }
    //viewModel.setKeyBoardVisible(false);
  }

// 遷移時にするあれこれ
  void transitionProcess(
      BuildContext context, OriginScoreViewModel scoreViewModel) {
    FocusScope.of(context).unfocus();
    // scoreViewModel.clearSpeechBubbleIfNeed();
  }
}

class KeyBoard extends StatefulWidget {
  KeyBoard(
    this.score,
    this.suggest, {
    Key key = null,
  }) : super(key: key) {
    defaultScore = score;
  }

  String score;
  String defaultScore;
  int suggest;

  @override
  _KeyBoardState createState() => _KeyBoardState();
}

class _KeyBoardState extends State<KeyBoard> {
  void addScore(String src) {
    setState(() {
      widget.score += src;
    });
  }

  void backSpace() {
    if (widget.score == '') {
      return;
    }
    setState(() {
      widget.score = widget.score.substring(0, widget.score.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: HeadingText(widget.score),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                const NormalText('00'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 9; i >= 7; i--)
                  ElevatedButton(
                    onPressed: () {
                      addScore(i.toString());
                    },
                    child: ButtonText(i.toString()),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 6; i >= 4; i--)
                  ElevatedButton(
                    onPressed: () {
                      addScore(i.toString());
                    },
                    child: ButtonText(i.toString()),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 3; i >= 1; i--)
                  ElevatedButton(
                    onPressed: () {
                      addScore(i.toString());
                    },
                    child: ButtonText(i.toString()),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: widget.score == ''
                      ? () {
                          addScore('-');
                        }
                      : null,
                  child: const ButtonText('-'),
                ),
                ElevatedButton(
                  onPressed: () {
                    addScore('0');
                  },
                  child: const ButtonText('0'),
                ),
                ElevatedButton(
                  onPressed: backSpace,
                  child: const Icon(Icons.backspace_outlined),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.transparent,
                    onSurface: Colors.transparent,
                    elevation: 0,
                    onPrimary: Colors.black,
                  ),
                ),
              ],
            ),
            Visibility(
              visible: widget.suggest != null,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(widget.suggest);
                },
                child: Text('自動計算(${widget.suggest})'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orangeAccent, //ボタンの背景色
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('キャンセル'),
          onPressed: () {
            final ret = widget.defaultScore != ''
                ? int.parse(widget.defaultScore)
                : null;
            Navigator.of(context).pop(ret);
          },
        ),
        TextButton(
          child: const Text('保存'),
          onPressed: () {
            final ret = widget.score != '' ? int.parse(widget.score) : null;
            Navigator.of(context).pop(ret);
          },
        ),
      ],
    );
  }
}

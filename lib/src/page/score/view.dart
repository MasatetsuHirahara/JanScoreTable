import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/page/adjustment/view.dart';
import 'package:flutter_app/src/page/gameSetting/view.dart';
import 'package:flutter_app/src/page/score/viewModel.dart';
import 'package:flutter_app/src/widget/text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chipScore/view.dart';
import '../scoreChart/view.dart';

const subjectCellWidth = 30.0;
const nameCellHeight = 50.0;
const totalCellHeight = 50.0;
const scoreCellHeight = 50.0;
const columnDividerHeight = 1.0;
const columnBoldDividerHeight = 2.0;
const rowDividerWidth = 1.0;
const keyButtonRowCnt = 3;

final _viewModel =
    ChangeNotifierProvider.autoDispose.family<ScoreViewModel, int>((ref, drId) {
  return ScoreViewModel(ref, drId);
});

// ignore: must_be_immutable
class ScorePage extends ConsumerWidget {
  static Route<dynamic> route({
    @required int drId,
  }) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => ScorePage(),
      settings: RouteSettings(arguments: drId),
    );
  }

  int drId;
  ScrollController scoreScrollController = ScrollController();

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
              Navigator.of(context)
                  .push<dynamic>(AdjustmentPage.route(drId: drId));
            },
            icon: const Icon(Icons.paid_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push<dynamic>(ChipScorePage.route(drId: drId));
            },
            icon: const Icon(Icons.copyright_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push<dynamic>(ScoreChartPage.route(drId: drId));
            },
            icon: const Icon(Icons.show_chart),
          ),
          IconButton(
              onPressed: () {
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
        subjectCell(height, ''),
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

  Widget totalSection(
      BuildContext context, double height, ScoreViewModel scoreViewModel) {
    final screenSize = MediaQuery.of(context).size;

    return SizedBox(
      height: height,
      width: screenSize.width,
      child: Row(children: [
        subjectCell(height, '計'),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: scoreViewModel.totalPointList.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: (screenSize.width - subjectCellWidth) /
                    scoreViewModel.totalPointList.length,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Center(
                          child:
                              ScoreText(scoreViewModel.totalPointList[index]),
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

  Widget scoreSection(BuildContext context, double height, ScoreViewModel vm) {
    final screenSize = MediaQuery.of(context).size;
    final totalHeight = MediaQuery.of(context).padding.top +
        MediaQuery.of(context).padding.bottom +
        AppBar().preferredSize.height +
        nameCellHeight +
        columnDividerHeight +
        totalCellHeight +
        columnBoldDividerHeight +
        (scoreCellHeight + columnDividerHeight) *
            vm.rowPropertyList.length.toDouble();

    final isScroll = screenSize.height <= totalHeight;
    print('scoreSection $isScroll');

    // スクロールが必要な場合、build後にスクロールする
    if (vm.isNeedScroll) {
      vm.isNeedScroll = false;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        scoreScrollController.animateTo(
            scoreScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 0),
            curve: Curves.linear);
      });
    }
    return Expanded(
      child: ListView.builder(
        physics: isScroll ? null : const NeverScrollableScrollPhysics(),
        controller: scoreScrollController,
        itemCount: vm.rowPropertyList.length,
        itemBuilder: (context, index) {
          var rowColor = Colors.white;
          if (vm.validateInput(index).isNotEmpty) {
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

  Widget scoreRow(BuildContext context, double height, int rowIndex,
      ScoreViewModel vm, Color rowColor) {
    final screenSize = MediaQuery.of(context).size;
    final rowProperty = vm.rowPropertyList[rowIndex];

    final errList = vm.validateInput(rowIndex);
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
                visible: errList.isNotEmpty,
                child: Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: const Icon(
                      Icons.warning_outlined,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      waringAlert(context, errList);
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
                final score = cell.scoreModel.scoreString != ''
                    ? cell.scoreModel.score
                    : null;

                return SizedBox(
                  width: (screenSize.width - subjectCellWidth) /
                      rowProperty.scoreCellList.length,
                  child: Container(
                    color: rowColor,
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              int suddest;
                              if (vm.isVisibleSuggest(rowIndex)) {
                                suddest =
                                    -rowProperty.getOtherTotalScore(index);
                              }
                              final iv = await pointKeyboard(context,
                                  cell.scoreModel.scoreString, suddest);
                              if (iv != null) {
                                vm.afterInput(rowIndex, index, iv);
                              }
                            },
                            child: Center(child: ScoreText(score)),
                          ),
                        ),
                        myDivider(rowDividerWidth, height),
                      ],
                    ),
                  ),
                );
              }),
        ),
      ]),
    );
  }

  Future<InputValue> pointKeyboard(
      BuildContext context, String score, int suggest) async {
    return showDialog<InputValue>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return ScoreKeyBoard(score, suggest);
      },
    );
  }

  Future<int> waringAlert(BuildContext context, List<errType> errList) async {
    final errText = StringBuffer();
    for (final e in errList) {
      errText.write(e.message);
    }

    return showDialog<int>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('エラー詳細'),
          content: Text(errText.toString()),
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

  Widget subjectCell(double height, String title) {
    return SizedBox(
      width: subjectCellWidth,
      height: height,
      child: Container(
        color: Colors.blueGrey,
        child: Align(
          alignment: Alignment.center,
          child: NormalText(title),
        ),
      ),
    );
  }

  Widget myDivider(double width, double height) {
    return SizedBox(
        width: width, height: height, child: Container(color: Colors.black));
  }
}

class ScoreKeyBoard extends StatefulWidget {
  ScoreKeyBoard(
    this.score,
    this.suggest, {
    Key key = null,
  }) : super(key: key) {}
  String score;
  int suggest;

  @override
  _ScoreKeyBoardState createState() => _ScoreKeyBoardState();
}

class _ScoreKeyBoardState extends State<ScoreKeyBoard> {
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
            Align(
              alignment: Alignment.centerRight,
              child: HeadingText(widget.score),
            ),
            const Divider(),
            Column(
              children: [
                for (var i = 1; i <= 9; i += keyButtonRowCnt) keyButtonRow(i),
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
                  final iv = InputValue(widget.suggest);
                  Navigator.of(context).pop(iv);
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
            Navigator.of(context).pop(null);
          },
        ),
        TextButton(
          child: const Text('保存'),
          onPressed: () {
            final score = widget.score != '' ? int.parse(widget.score) : null;
            final iv = InputValue(score);
            Navigator.of(context).pop(iv);
          },
        ),
      ],
    );
  }

  Widget keyButtonRow(int start) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = start; i < start + keyButtonRowCnt; i++)
          ElevatedButton(
            onPressed: () {
              addScore(i.toString());
            },
            child: ButtonText(i.toString()),
          ),
      ],
    );
  }
}

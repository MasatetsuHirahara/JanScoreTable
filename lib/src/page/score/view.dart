import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/page/adjustment/view.dart';
import 'package:flutter_app/src/page/gameSetting/view.dart';
import 'package:flutter_app/src/page/score/viewModel.dart';
import 'package:flutter_app/src/widget/speechBubble.dart';
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
  double keyboardHeight = 0;

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
                  keyBoardBlank(context),
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

  // キーボード分を空けておいて、キーボードの表示非表示でスクロールしないようにする
  Widget keyBoardBlank(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).viewInsets.bottom,
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
                  Positioned.fill(
                    child: bubble(scoreViewModel, -1, index),
                  ), // scoreのtopが0なので-1...
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget scoreSection(
      BuildContext context, double height, ScoreViewModel provider) {
    final screenSize = MediaQuery.of(context).size;
    var totalHeight = MediaQuery.of(context).padding.top + // safeArea
        AppBar().preferredSize.height +
        nameCellHeight +
        columnDividerHeight +
        totalCellHeight +
        columnBoldDividerHeight +
        (scoreCellHeight + columnDividerHeight) *
            provider.rowPropertyList.length.toDouble();
    if (provider.keyBoardVisible) {
      totalHeight += MediaQuery.of(context).viewInsets.bottom;
    }

    final isScroll = screenSize.height <= totalHeight;
    print('scoreSection $isScroll');
    return Expanded(
      child: ListView.builder(
        physics: isScroll ? null : const NeverScrollableScrollPhysics(),
        itemCount: provider.rowPropertyList.length,
        itemBuilder: (context, index) {
          var rowColor = Colors.white;
          if (provider.validateRowScoreSum(index) == false) {
            rowColor = Colors.yellow;
          }

          return Column(children: [
            scoreRow(context, height, index, provider, rowColor),
            myDivider(screenSize.width, columnDividerHeight),
          ]);
        },
      ),
    );
  }

  Widget scoreRow(BuildContext context, double height, int rowIndex,
      ScoreViewModel provider, Color rowColor) {
    final screenSize = MediaQuery.of(context).size;
    final rowProperty = provider.rowPropertyList[rowIndex];

    return SizedBox(
      height: height,
      width: screenSize.width,
      child: Row(children: [
        subjectCell(height, '${(rowIndex + 1).toString()}'),
        Expanded(
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: rowProperty.scoreCellList.length,
              itemBuilder: (context, index) {
                final cellProperty = rowProperty.scoreCellList[index];
                cellProperty.setFocusOut(() {
                  if (cellProperty.isChanged() == false) {
                    return;
                  }
                  if (cellProperty.validateInput() == false) {
                    cellProperty.clearScore();
                    return;
                  }
                  print('setFocusOut $rowIndex $index');
                });

                // textに合わせてカーソル位置を末端にしておく
                rowProperty.setAllCursorToEnd();
                return Stack(
                  children: [
                    SizedBox(
                      width: (screenSize.width - subjectCellWidth) /
                          rowProperty.scoreCellList.length,
                      child: Container(
                        color: rowColor,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                textAlign: TextAlign.center,
                                controller: cellProperty.controller,
                                focusNode: cellProperty.focusNode,
                                textInputAction: TextInputAction.unspecified,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        signed: true, decimal: true),
                                style: TextStyle(
                                  color: cellProperty.scoreModel.score >= 0
                                      ? Colors.black
                                      : Colors.red,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[-0-9]')),
                                  FilteringTextInputFormatter
                                      .singleLineFormatter,
                                ],
                                onTap: () {
                                  // 入力中に他のTFをタップしたら、後処理を呼ぶ
                                  // タップされたセルとフォーカス中のセルが同じならスルー
                                  final cd = provider.getFocusCoordinate();
                                  if (cd != null) {
                                    if (cd.isNotEqual(rowIndex, index)) {
                                      print('onTap $rowIndex, $index');
                                      provider.afterInput(cd.row, cd.col);
                                    }
                                  }

                                  // 吹き出し判定
                                  provider.setSpeechBubble(rowIndex, index);

                                  keyBoardShowProcess(provider);
                                },
                                onEditingComplete: () {
                                  print('aaa');
                                },
                                onSubmitted: (value) {
                                  print('onSubmitted $rowIndex, $index');
                                  provider
                                    ..afterInput(rowIndex, index)
                                    ..clearSpeechBubbleIfNeed();
                                  keyBoardHideProcess(provider);
                                },
                              ),
                            ),
                            myDivider(rowDividerWidth, height),
                          ],
                        ),
                      ),
                    ),
                    bubble(provider, rowIndex, index),
                  ],
                );
              }),
        ),
      ]),
    );
  }

  Widget bubble(ScoreViewModel scoreViewModel, int row, int col) {
    if (scoreViewModel.speechBubbleProperty.isVisible == false) {
      return Container();
    }

    // 表示対象のセルでない場合は適当なcontainerを返す
    // フォーカスセル
    if (scoreViewModel.speechBubbleProperty.coordinate.row != row + 1 ||
        scoreViewModel.speechBubbleProperty.coordinate.col != col) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        decoration: const ShapeDecoration(
          shape: SpeechBubble(),
          color: Colors.blueGrey,
        ),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Center(
            child: TextButton(
              child: NormalText('${scoreViewModel.speechBubbleProperty.score}'),
              onPressed: () {
                keyBoardHideProcess(scoreViewModel);
                scoreViewModel.speechBubbleTap();
              },
            ),
          ),
        ),
      ),
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

// キーボード表示するときのあれこれ
  void keyBoardShowProcess(ScoreViewModel viewModel) {
    viewModel.setKeyBoardVisible(true);
  }

// キーボード閉じるするときのあれこれ
  void keyBoardHideProcess(ScoreViewModel viewModel) {
    //final coordinate = viewModel.getFocusCoordinate();
    // if (coordinate != null) {
    //   viewModel.rowPropertyList[coordinate.row].scoreCellList[coordinate.col]
    //       .focusNode
    //       .unfocus();
    // }
    //viewModel.setKeyBoardVisible(false);
  }

// 遷移時にするあれこれ
  void transitionProcess(BuildContext context, ScoreViewModel scoreViewModel) {
    FocusScope.of(context).unfocus();
    scoreViewModel.clearSpeechBubbleIfNeed();
  }
}

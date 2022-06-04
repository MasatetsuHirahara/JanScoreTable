import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/page/adjustment/view.dart';
import 'package:flutter_app/src/page/gameSetting/view.dart';
import 'package:flutter_app/src/page/score/viewModel.dart';
import 'package:flutter_app/src/widget/speechBubble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessor/table/gameSettingProvider.dart';
import '../chipScore/view.dart';
import '../scoreChart/view.dart';

const indexCellWidth = 30.0;
const nameCellHeight = 50.0;
const totalCellHeight = 50.0;
const scoreCellHeight = 50.0;
const topDividerHeight = 3.0;
const scoreDividerHeight = 1.0;
const speechBubbleHeight = scoreCellHeight + 10.0;
const speechBubbleWidthDiff = 10.0;
// TODO
// スクロール

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
  bool isGsInitialized = false;

  void goGsIfNeed(BuildContext context, WidgetRef ref) {
    final gsa = ref.watch(gameSettingAccessor);
    if (isGsInitialized) {
      return;
    }
    if (gsa.isInitialized) {
      if (!isGsInitialized) {
        final gs = gsa.drIdMap[drId];
        if (gs == null) {
          //　初回ビルドが完了する前に遷移するとエラーなるので、ビルド完了を待つ
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context)
                .push<dynamic>(GameSettingPage.route(drId: drId));
          });
        }
        isGsInitialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    drId = ModalRoute.of(context).settings.arguments as int;

    // プロバイダ
    final pProvider = ref.watch(scoreViewProvider(drId));

    // 必要なら設定画面に遷移
    goGsIfNeed(context, ref);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('スコア'),
        leading: BackButton(),
        actions: [
          IconButton(
            onPressed: () {
              transitionProcess(context, pProvider);
              Navigator.of(context)
                  .push<dynamic>(AdjustmentPage.route(drId: drId));
            },
            icon: Icon(Icons.paid_rounded),
          ),
          IconButton(
            onPressed: () {
              transitionProcess(context, pProvider);
              Navigator.of(context)
                  .push<dynamic>(ChipScorePage.route(drId: drId));
            },
            icon: Icon(Icons.copyright_rounded),
          ),
          IconButton(
            onPressed: () {
              transitionProcess(context, pProvider);
              Navigator.of(context)
                  .push<dynamic>(ScoreChartPage.route(drId: drId));
            },
            icon: Icon(Icons.show_chart),
          ),
          IconButton(
              onPressed: () {
                transitionProcess(context, pProvider);
                Navigator.of(context)
                    .push<dynamic>(GameSettingPage.route(drId: drId));
              },
              icon: Icon(Icons.settings)),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              Column(
                children: [
                  nameSection(context, nameCellHeight, pProvider.nameList),
                  myDivider(topDividerHeight, screenSize.width),
                  totalSection(context, totalCellHeight, pProvider),
                  myDivider(topDividerHeight, screenSize.width),
                  scoreSection(context, scoreCellHeight, pProvider),
                  keyBoardBlank(context, pProvider.keyBoardVisible),
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
}

Widget keyBoardBlank(BuildContext context, bool isVisble) {
  final screenSize = MediaQuery.of(context).size;
  final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

  return SizedBox(
    width: screenSize.width,
    height: isVisble ? keyboardHeight : 0,
  );
}

Widget speechBubble(BuildContext context, ScoreViewModel provider) {
  final size = calculateSpeechBubbleSize(context, provider);
  final padding = calculateSpeechBubblePadding(context, provider);
  final property = provider.speechBubbleProperty;

  return Padding(
    padding: padding,
    child: SizedBox(
      width: size.width,
      height: size.height,
      child: Visibility(
        visible: property.isVisible,
        child: Container(
          decoration: const ShapeDecoration(
            shape: SpeechBubble(),
            color: Colors.blue,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: TextButton(
                    child: Text(
                      '${property.score}',
                      style: TextStyle(fontSize: 15, color: Colors.black),
                    ),
                    onPressed: () {
                      keyBoardHideProcess(provider);
                      provider.speechBubbleTap();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Size calculateSpeechBubbleSize(BuildContext context, ScoreViewModel provider) {
  final screenSize = MediaQuery.of(context).size;
  final scoreCellWidth =
      (screenSize.width - indexCellWidth) / provider.nameList.length;

  return Size(scoreCellWidth - speechBubbleWidthDiff, speechBubbleHeight);
}

EdgeInsets calculateSpeechBubblePadding(
    BuildContext context, ScoreViewModel provider) {
  final property = provider.speechBubbleProperty;
  final screenSize = MediaQuery.of(context).size;
  final scoreCellWidth =
      (screenSize.width - indexCellWidth) / provider.nameList.length;

  // topPaddingを計算　対象のセルの上の方に出したいので　1個分上にずらす
  final top = nameCellHeight +
      totalCellHeight +
      scoreCellHeight * property.coordinate.row -
      scoreCellHeight;

  // leftPaddingを計算　中央に出したいので最後に /2 を足す
  final left = indexCellWidth +
      scoreCellWidth * property.coordinate.col +
      speechBubbleWidthDiff / 2;

  return EdgeInsets.fromLTRB(left, top, 0, 0);
}

Widget nameSection(BuildContext context, double height, List<String> list) {
  final screenSize = MediaQuery.of(context).size;

  return SizedBox(
    height: height,
    width: screenSize.width,
    child: Row(children: [
      SizedBox(
        width: indexCellWidth,
        height: height,
        child: Container(color: Colors.blue),
      ),
      Expanded(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: (screenSize.width - indexCellWidth) / list.length,
              child: Row(children: [
                Expanded(
                    child: Container(
                        color: Colors.green,
                        child: Center(child: Text('${list[index]}')))),
                myDivider(height, 1)
              ]),
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
      SizedBox(
        width: indexCellWidth,
        height: height,
        child: Container(color: Colors.blue),
      ),
      Expanded(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: scoreViewModel.totalPointList.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                SizedBox(
                  width: (screenSize.width - indexCellWidth) /
                      scoreViewModel.totalPointList.length,
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        color: Colors.green,
                        child: Center(
                          child: Text(
                            '${scoreViewModel.totalPointList[index]}',
                            style: TextStyle(
                              color: scoreViewModel.totalPointList[index] >= 0
                                  ? Colors.black
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                    myDivider(height, 1)
                  ]),
                ),
                buble(context, scoreViewModel, -1, index),
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
  var totalHeight = AppBar().preferredSize.height +
      nameCellHeight +
      topDividerHeight +
      totalCellHeight +
      topDividerHeight +
      (scoreCellHeight + scoreDividerHeight) *
          provider.rowPropertyList.length.toDouble();
  if (provider.keyBoardVisible) {
    totalHeight += MediaQuery.of(context).viewInsets.bottom;
  }

  final isScroll = screenSize.height <= totalHeight;
  print('scoreSection $isScroll');
  print('scoreSection total=$totalHeight, screen=${screenSize.height}');
  return Expanded(
    child: ListView.builder(
      shrinkWrap: true,
      physics: isScroll ? null : NeverScrollableScrollPhysics(),
      itemCount: provider.rowPropertyList.length,
      itemBuilder: (context, index) {
        var rowColor = Colors.green;
        if (provider.validateRowScoreSum(index) == false) {
          rowColor = Colors.yellow;
        }
        return scoreRow(context, height, index, provider, rowColor);
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
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: indexCellWidth,
          height: height,
          child: Container(
              color: Colors.blue,
              child: Center(child: Text('${(rowIndex + 1).toString()}'))),
        ),
      ),
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
                //provider.afterInput(rowIndex, index);
              });

              // textに合わせてカーソル位置を末端にしておく
              rowProperty.setAllCursorToEnd();
              return Stack(
                children: [
                  SizedBox(
                    width: (screenSize.width - indexCellWidth) /
                        rowProperty.scoreCellList.length,
                    child: Container(
                      color: rowColor,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
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
                              textAlign: TextAlign.center,
                              controller: cellProperty.controller,
                              style: TextStyle(
                                color: cellProperty.score >= 0
                                    ? Colors.black
                                    : Colors.red,
                              ),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[-0-9]')),
                                FilteringTextInputFormatter.singleLineFormatter,
                              ],
                              focusNode: cellProperty.focusNode,
                              onSubmitted: (value) {
                                print('onSubmitted $rowIndex, $index');
                                provider.afterInput(rowIndex, index);
                                provider.clearSpeechBubbleIfNeed();
                                keyBoardHideProcess(provider);
                              },
                            ),
                          ),
                          myDivider(height, 1)
                        ],
                      ),
                    ),
                  ),
                  buble(context, provider, rowIndex, index),
                ],
              );
            }),
      ),
    ]),
  );
}

Widget buble(
    BuildContext context, ScoreViewModel scoreViewModel, int row, int col) {
  if (scoreViewModel.speechBubbleProperty.isVisible == false) {
    return Container();
  }

  // 表示対象のセルでない場合は適当なcontainerを返す
  // 表示対象はフォーカスのセルの一つ上
  if (scoreViewModel.speechBubbleProperty.coordinate.row != row + 1 ||
      scoreViewModel.speechBubbleProperty.coordinate.col != col) {
    return Container();
  }
  return Padding(
    padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
    child: Container(
      decoration: const ShapeDecoration(
        shape: SpeechBubble(),
        color: Colors.blue,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: Center(
              child: TextButton(
                // style: TextButton.styleFrom(
                //   backgroundColor: Colors.red,
                // ),
                child: Text(
                  '${scoreViewModel.speechBubbleProperty.score}',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                onPressed: () {
                  keyBoardHideProcess(scoreViewModel);
                  scoreViewModel.speechBubbleTap();
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// キーボード表示するときのあれこれ
void keyBoardShowProcess(ScoreViewModel viewModel) {
  viewModel.setKeyBoardVisible(true);
}

// キーボード閉じるするときのあれこれ
void keyBoardHideProcess(ScoreViewModel viewModel) {
  final coordinate = viewModel.getFocusCoordinate();
  if (coordinate != null) {
    viewModel
        .rowPropertyList[coordinate.row].scoreCellList[coordinate.col].focusNode
        .unfocus();
  }

  viewModel.setKeyBoardVisible(false);
}

// 遷移時にするあれこれ
void transitionProcess(BuildContext context, ScoreViewModel scoreViewModel) {
  FocusScope.of(context).unfocus();
  scoreViewModel.clearSpeechBubbleIfNeed();
}

Widget myDivider(double height, double width) {
  return SizedBox(
      width: width, height: height, child: Container(color: Colors.red));
}

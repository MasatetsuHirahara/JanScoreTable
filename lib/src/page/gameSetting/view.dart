import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/model/gameSettingModel.dart';
import 'package:flutter_app/src/page/copySetting/view.dart';
import 'package:flutter_app/src/page/gameSetting/viewModel.dart';
import 'package:flutter_app/src/page/searchName/view.dart';
import 'package:flutter_app/src/widget/text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../widget/dialog.dart';

const buttonWidth = 150.0;

final _viewModel = ChangeNotifierProvider.autoDispose
    .family<GameSettingViewModel, int>((ref, drId) {
  return GameSettingViewModel(ref, drId);
});

class GameSettingPage extends ConsumerWidget {
  static Route<dynamic> route({
    @required int drId,
  }) {
    return MaterialPageRoute<dynamic>(
        builder: (_) => GameSettingPage(),
        settings: RouteSettings(arguments: drId),
        fullscreenDialog: true);
  }

  @override
  void dispose() {
    print('dispose !!!!!!!!');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 引数処理
    final drId = ModalRoute.of(context).settings.arguments as int;

    final vm = ref.watch(_viewModel(drId));

    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('ゲーム設定'),
          leading: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Visibility(
              visible: drId == 0,
              child: IconButton(
                onPressed: () async {
                  final id = await Navigator.of(context)
                      .push<dynamic>(CopySettingPage.route()) as int;
                  vm.copySetting(id);
                },
                icon: const Icon(Icons.content_copy_outlined),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
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
                      Visibility(
                        visible: drId == 0, // 途中変更は不可とする
                        child: gameKindRow(vm),
                      ),
                      rateRow(vm),
                      chipRateRow(vm),
                      for (var i = 0; i < vm.mpList.length; i++)
                        memberRow(context, vm, i),
                      addRemoveRow(context, vm),
                      detailSetting(vm),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          child: const ButtonText('保存'),
                          onPressed: () async {
                            await vm.tappedSave();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}

Widget detailSetting(GameSettingViewModel vm) {
  return ExpansionTile(
    title: const HeadingText('詳細設定'),
    tilePadding: EdgeInsets.symmetric(horizontal: 8),
    childrenPadding: EdgeInsets.fromLTRB(8, 0, 0, 0),
    children: [
      okaSection(vm),
      umaSection(vm, true),
      koRow(vm),
      inputTypeRow(vm),
    ],
  );
}

Widget okaSection(GameSettingViewModel vm) {
  final genten = RateProperty('原点', vm.gentenController, '配給原点', '');
  final kaeshi = RateProperty('返し', vm.kaeshiController, '基準点', '');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const HeadingText('オカ'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
        child: Column(
          children: [
            rateWidget(genten),
            rateWidget(kaeshi),
          ],
        ),
      ),
    ],
  );
}

Widget umaSection(GameSettingViewModel vm, bool isVisibleFourth) {
  final first = RateProperty('1着', vm.firstUmaController, '順位点', '');
  final second = RateProperty('2着', vm.secondUmaController, '順位点', '');
  final third = RateProperty('3着', vm.thirdUmaController, '順位点', '');
  final fourth = RateProperty('4着', vm.fourthUmaController, '順位点', '');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const HeadingText('ウマ'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
        child: Column(
          children: [
            rateWidget(first),
            rateWidget(second),
            rateWidget(third),
            Visibility(visible: isVisibleFourth, child: rateWidget(fourth)),
          ],
        ),
      ),
    ],
  );
}

Widget koRow(GameSettingViewModel vm) {
  final p = RateProperty('飛び', vm.rateController, 'ポイント', '');
  return rateWidget(p);
}

Widget inputTypeRow(GameSettingViewModel vm) {
  final groupValue = vm.inputType;
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const HeadingText('入力方法'),
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const NormalText('ポイント'),
            Radio(
              value: InputTypeValue.POINT,
              groupValue: groupValue,
              onChanged: vm.setInputType,
            ),
            const NormalText('素点'),
            Radio(
              value: InputTypeValue.SOTEN,
              groupValue: groupValue,
              onChanged: vm.setInputType,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget gameKindRow(GameSettingViewModel vm) {
  final groupValue = vm.kind;
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const HeadingText('四麻？三麻？'),
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const NormalText('四麻'),
            Radio(
              value: KindValue.YONMA,
              groupValue: groupValue,
              onChanged: vm.setKind,
            ),
            const NormalText('三麻'),
            Radio(
              value: KindValue.SANMA,
              groupValue: groupValue,
              onChanged: vm.setKind,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget rateRow(GameSettingViewModel vm) {
  final p = RateProperty('レート', vm.rateController, '千点あたり', 'G');
  return rateWidget(p);
}

Widget chipRateRow(GameSettingViewModel vm) {
  final p = RateProperty('チップレート', vm.chipRateController, '1枚あたり', 'G');
  return rateWidget(p);
}

Widget memberRow(BuildContext context, GameSettingViewModel vm, int index) {
  final mp = vm.mpList[index];
  final isLast = vm.mpList.length - 1 <= index;
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HeadingText('参加者${index + 1}'),
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    width: 150.w,
                    child: TextField(
                      focusNode: mp.focusNode,
                      textInputAction:
                          isLast ? TextInputAction.done : TextInputAction.next,
                      controller: mp.controller,
                      textAlign: TextAlign.center,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.singleLineFormatter,
                      ],
                      onChanged: (name) {
                        mp.clearId();
                      },
                      onSubmitted: (value) {
                        if (!isLast) {
                          FocusScope.of(context)
                              .requestFocus(vm.mpList[index + 1].focusNode);
                        }
                      },
                    ),
                  ),
                  IconButton(
                      onPressed: () async {
                        final id = await Navigator.of(context)
                            .push<dynamic>(SearchNamePage.route()) as int;

                        vm.setMpList(index, id);
                      },
                      icon: const Icon(Icons.search)),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget addRemoveRow(BuildContext context, GameSettingViewModel vm) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Visibility(
        visible: vm.addButtonVisible,
        child: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () async {
            vm.addMemberProperty();
          },
        ),
      ),
      Visibility(
        visible: vm.removeButtonVisible,
        child: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () async {
            // スコアがあるメンバーは確認をする
            if (vm.isThereScore()) {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return const DeleteDialog('登録されているスコアも削除されますよろしいですか？');
                },
              );
              // いいえならなにもしない
              if (!result) {
                return;
              }
            }

            vm.removeMemberProperty();
          },
        ),
      ),
    ],
  );
}

class RateProperty {
  RateProperty(this.title, this.controller, this.hint, this.trailing);
  String title;
  TextEditingController controller;
  String hint;
  String trailing;
}

Widget rateWidget(RateProperty property) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      HeadingText(property.title),
      Container(
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              width: 100,
              child: TextField(
                textInputAction: TextInputAction.next,
                controller: property.controller,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  FilteringTextInputFormatter.singleLineFormatter,
                ],
                decoration: InputDecoration(
                  hintText: property.hint,
                ),
              )),
          NormalText(property.trailing),
        ]),
      ),
    ],
  );
}

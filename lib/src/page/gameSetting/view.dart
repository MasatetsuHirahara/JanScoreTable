import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/model/gameSettingModel.dart';
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
                      gameKindRow(vm),
                      rateRow(vm),
                      chipRateRow(vm),
                      for (var i = 0; i < vm.mpList.length; i++)
                        memberRow(context, vm, i),
                      addRemoveRow(context, vm),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          child: ButtonText('保存'),
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

Widget gameKindRow(GameSettingViewModel vm) {
  final groupValue = vm.kind;
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      HeadingText('四麻？三麻？'),
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            NormalText('四麻'),
            Radio(
              value: KindValue.YONMA,
              groupValue: groupValue,
              onChanged: vm.setKind,
            ),
            NormalText('三麻'),
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
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      HeadingText('レート'),
      Container(
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              width: 100,
              child: TextField(
                textInputAction: TextInputAction.next,
                controller: vm.rateController,
                textAlign: TextAlign.center,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  FilteringTextInputFormatter.singleLineFormatter,
                ],
                decoration: const InputDecoration(
                  hintText: '千点あたり',
                ),
              )),
          NormalText('G'),
        ]),
      ),
    ],
  );
}

Widget chipRateRow(GameSettingViewModel vm) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      HeadingText('チップレート'),
      Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
              width: 100.w,
              child: TextField(
                  textInputAction: TextInputAction.next,
                  controller: vm.chipRateController,
                  textAlign: TextAlign.center,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    FilteringTextInputFormatter.singleLineFormatter,
                  ],
                  decoration: const InputDecoration(
                    hintText: '1枚あたり',
                  )),
            ),
            NormalText('G'),
          ],
        ),
      ),
    ],
  );
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

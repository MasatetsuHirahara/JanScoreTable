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

  final GlobalKey<FormState> _rateKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _chipRateKey = GlobalKey<FormState>();
  final List<GlobalKey<FormState>> _memberKeyList = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

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
                        memberRow(_memberKeyList[i], context, vm, i),
                      addRemoveRow(context, vm),
                      detailSetting(vm),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          child: const ButtonText('保存'),
                          onPressed: () async {
                            var isErr = false;
                            if (!_rateKey.currentState.validate()) {
                              isErr = true;
                            }
                            if (!_chipRateKey.currentState.validate()) {
                              isErr = true;
                            }
                            for (var i = 0;
                                i < _memberKeyList.length && i < vm.kind.num;
                                i++) {
                              if (!_memberKeyList[i].currentState.validate()) {
                                isErr = true;
                              }
                            }

                            if (isErr) {
                              return;
                            }

                            if (!vm.validateInput()) {
                              await showDialog<void>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const NormalText('同じ名前は登録できません'),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const NormalText('閉じる')),
                                      ],
                                    );
                                  });

                              return;
                            }
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
    return rateWidget(p, _rateKey);
  }

  Widget chipRateRow(GameSettingViewModel vm) {
    final p = RateProperty('チップレート', vm.chipRateController, '1枚あたり', 'G');
    return rateWidget(p, _chipRateKey);
  }

  Widget memberRow(
      Key key, BuildContext context, GameSettingViewModel vm, int index) {
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
                      child: Form(
                        key: key,
                        child: TextFormField(
                          focusNode: mp.focusNode,
                          textInputAction: isLast
                              ? TextInputAction.done
                              : TextInputAction.next,
                          controller: mp.controller,
                          textAlign: TextAlign.center,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.singleLineFormatter,
                          ],
                          onChanged: (name) {
                            mp.clearId();
                          },
                          onFieldSubmitted: (value) {
                            if (!isLast) {
                              FocusScope.of(context)
                                  .requestFocus(vm.mpList[index + 1].focusNode);
                            }
                          },
                          validator: (value) {
                            if (value == '') {
                              return '入力してください';
                            }
                            return null;
                          },
                        ),
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

  Widget detailSetting(GameSettingViewModel vm) {
    return ExpansionTile(
      title: const HeadingText('詳細設定'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
      children: [
        okaSection(vm),
        rankingPointSection(vm, vm.kind == KindValue.YONMA),
        koRow(vm),
        fireBirdRow(vm),
        inputTypeRow(vm),
        roundTypeRow(vm),
        samePointTypeRow(vm),
      ],
    );
  }

  Widget okaSection(GameSettingViewModel vm) {
    final originPoint =
        RateProperty('原点', vm.originPointController, '百点単位', '00');
    final basePoint = RateProperty('返し', vm.basePointController, '百点単位', '00');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HeadingText('オカ'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
          child: Column(
            children: [
              rateWidget(originPoint, key),
              rateWidget(basePoint, key),
            ],
          ),
        ),
      ],
    );
  }

  Widget rankingPointSection(GameSettingViewModel vm, bool isVisibleFourth) {
    final first = RateProperty('1着', vm.firstRankingPointController, '順位点', '');
    final second =
        RateProperty('2着', vm.secondRankingPointController, '順位点', '');
    final third = RateProperty('3着', vm.thirdRankingPointController, '順位点', '');
    final fourth =
        RateProperty('4着', vm.fourthRankingPointController, '順位点', '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HeadingText('ウマ'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
          child: Column(
            children: [
              pointWidget(first),
              pointWidget(second),
              pointWidget(third),
              Visibility(visible: isVisibleFourth, child: pointWidget(fourth)),
            ],
          ),
        ),
      ],
    );
  }

  Widget koRow(GameSettingViewModel vm) {
    final p = RateProperty('飛び', vm.koController, 'なし', '');
    return rateWidget(p, key);
  }

  Widget fireBirdRow(GameSettingViewModel vm) {
    final p = RateProperty('焼き鳥', vm.fireBirdController, 'なし', '');
    return rateWidget(p, key);
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

  Widget roundTypeRow(GameSettingViewModel vm) {
    final groupValue = vm.roundType;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const HeadingText('切り上げ'),
        Container(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const NormalText('五捨六入'),
              Radio(
                value: RoundType.GOSYA,
                groupValue: groupValue,
                onChanged: vm.setRoundType,
              ),
              const NormalText('四捨五入'),
              Radio(
                value: RoundType.SISYA,
                groupValue: groupValue,
                onChanged: vm.setRoundType,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget samePointTypeRow(GameSettingViewModel vm) {
    final groupValue = vm.samePointType;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const HeadingText('同点の場合'),
        Container(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const NormalText('上家優先'),
              Radio(
                value: SamePointType.KAMICHA,
                groupValue: groupValue,
                onChanged: vm.setSamePointType,
              ),
              const NormalText('分け'),
              Radio(
                value: SamePointType.DIVIDE,
                groupValue: groupValue,
                onChanged: vm.setSamePointType,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget rateWidget(RateProperty property, Key key) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        HeadingText(property.title),
        Container(
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                width: 100,
                child: Form(
                  key: key,
                  child: TextFormField(
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
                    validator: (value) {
                      if (value == '') {
                        return '入力してください';
                      }
                      return null;
                    },
                  ),
                )),
            NormalText(property.trailing),
          ]),
        ),
      ],
    );
  }

  Widget pointWidget(RateProperty property) {
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
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9]')),
                    FilteringTextInputFormatter.singleLineFormatter,
                  ],
                  decoration: InputDecoration(
                    hintText: property.hint,
                  ),
                  onSubmitted: (value) {
                    // バリデーション
                    if (new RegExp(r'[0-9]-').hasMatch(value)) {
                      property.controller.text = '';
                    }
                  },
                )),
            NormalText(property.trailing),
          ]),
        ),
      ],
    );
  }
}

class RateProperty {
  RateProperty(this.title, this.controller, this.hint, this.trailing);
  String title;
  TextEditingController controller;
  String hint;
  String trailing;
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/model/gameJoinMemberModel.dart';
import 'package:flutter_app/src/model/gameSettingModel.dart';
import 'package:flutter_app/src/model/memberModel.dart';
import 'package:flutter_app/src/page/searchName.dart';
import 'package:flutter_app/src/provider/chipScoreProvider.dart';
import 'package:flutter_app/src/provider/gameJoinMemberProvider.dart';
import 'package:flutter_app/src/provider/memberProvider.dart';
import 'package:flutter_app/src/provider/scoreProvider.dart';
import 'package:flutter_app/src/widget/text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../provider/dayRecodeProvider.dart';
import '../provider/gameSettingProvider.dart';

// TODO
// focusnodeがふようになった
const int defaultMemberNum = 4;
const int maxMemberNum = 5;

final gameSettingPageProvider = ChangeNotifierProvider.autoDispose
    .family<GameSettingViewModel, int>((ref, drId) {
  return GameSettingViewModel(ref, drId);
});

class GameSettingViewModel extends ChangeNotifier {
  GameSettingViewModel(this.ref, this.drId) {
    for (var i = 0; i < defaultMemberNum; i++) {
      mpList.add(MemberProperty());
    }
    listenGameSetting();
    listenGameJoinedMember();
  }
  Ref ref;
  int drId;
  bool isInitializedGameSetting = false;
  bool isInitializedGameJoinedMember = false;

  TextEditingController rateController = TextEditingController();
  TextEditingController chipRateController = TextEditingController();
  KindValue kind = KindValue.YONMA;
  List<MemberProperty> mpList = [];
  bool addButtonVisible = true;
  bool removeButtonVisible = false;

  List<GameJoinMemberView> gameJoinedMemberList = [];

  void listenGameSetting() {
    localFunc(GameSettingNotifier p) {
      // gsは一度しか取得しない
      if (isInitializedGameSetting) {
        return;
      }
      if (p.isInitialized) {
        if (p.drIdMap.containsKey(drId)) {
          final gs = p.drIdMap[drId];
          kind = KindValueExtension.fromInt(gs.kind);
          rateController.text = gs.rate.toString();
          chipRateController.text = gs.chipRate.toString();
        }
        isInitializedGameSetting = true;
      }
    }

    final provider = ref.read(gameSettingProvider);
    localFunc(provider);
    ref.listen<GameSettingNotifier>(gameSettingProvider, (previous, next) {
      localFunc(next);
    });
  }

  void listenGameJoinedMember() {
    localFunc(GameJoinMemberNotifier p) {
      if (isInitializedGameJoinedMember) {
        return;
      }
      if (p.isInitialized) {
        if (p.drIdMap.containsKey(drId)) {
          mpList = [];
          final gjmList = p.drIdMap[drId];
          for (var i = 0; i < gjmList.length; i++) {
            addMemberProperty(gjm: gjmList[i]);
          }
        }
        isInitializedGameJoinedMember = true;
      }
    }

    final provider = ref.read(gameJoinMemberProvider);
    localFunc(provider);
    ref.listen<GameJoinMemberNotifier>(gameJoinMemberProvider,
        (previous, next) {
      localFunc(next);
    });
  }

  void setKind(KindValue k) {
    kind = k;

    if (mpList.length < kind.num) {
      for (var i = 0; i < kind.num - mpList.length; i++) {
        mpList.add(MemberProperty());
      }
    }

    addButtonVisible = mpList.length < maxMemberNum;
    removeButtonVisible = mpList.length > kind.num;
    notifyListeners();
  }

  void setMpList(int index, int id) {
    final m = ref.read(memberProvider).recodeMap[id];
    mpList[index].memberId = m.id;
    mpList[index].controller.text = m.name;
    notifyListeners();
  }

  void addMemberProperty({GameJoinMemberView gjm}) {
    if (gjm == null) {
      mpList.add(MemberProperty());
    } else {
      mpList.add(MemberProperty.fromGjm(gjm));
    }

    addButtonVisible = mpList.length < maxMemberNum;
    removeButtonVisible = mpList.length > kind.num;
    notifyListeners();
  }

  bool isThereScore() {
    return ref.read(scoreProvider).isThereScore(drId, mpList.length - 1);
  }

  Future<void> removeMemberProperty() async {
    // gjmに関連するデータを削除
    await ref.read(gameJoinMemberProvider).deleteWithId(mpList.last.gjmId);
    await ref.read(scoreProvider).deleteNumber(drId, mpList.length - 1);
    await ref.read(chipScoreProvider).deleteNumber(drId, mpList.length - 1);
    mpList.removeLast();

    addButtonVisible = mpList.length < maxMemberNum;
    removeButtonVisible = mpList.length > kind.num;

    notifyListeners();
  }

  void saveGameSetting() {
    // ゲーム設定を保存
    final gs = GameSettingModel()
      ..drId = drId
      ..kind = kind.num
      ..rate = int.parse(rateController.text)
      ..chipRate = int.parse(chipRateController.text);
    ref.read(gameSettingProvider).upsert(gs);
  }

  // メンバーを保存
  Future<void> saveMember() async {
    final dr = ref.read(dayRecodeProvider);
    final day = dr.drMap[drId].day;
    final mProvider = ref.read(memberProvider);
    for (var i = 0; i < mpList.length; i++) {
      final m = mpList[i];
      if (m.controller.text == null || m.controller.text == '') {
        continue;
      }
      if (m.memberId == null) {
        // 名前がすでに存在するか確認して、あればそのIDを利用
        m.memberId = mProvider.getId(m.controller.text);
      } else {
        //　名前が変わっている場合は、IDを変換する必要ある。
        if (m.readName != m.controller.text) {
          m.memberId = mProvider.getId(m.controller.text);
        }
      }

      // メンバーを保存。新規追加の場合IDがほしいのでawaitで待つ
      final member = MemberModel.fromPara(m.memberId, m.controller.text, day);
      await mProvider.upsert(member);

      // メンバー参加を保存
      final gjm = GameJoinMemberModel.fromParam(m.gjmId, drId, member.id, i);
      ref.read(gameJoinMemberProvider).upsert(gjm);
    }
  }
}

class MemberProperty {
  MemberProperty();
  MemberProperty.fromGjm(GameJoinMemberView gjm) {
    memberId = gjm.mId;
    gjmId = gjm.id;
    readName = gjm.name;
    controller.text = gjm.name;
  }
  final TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();
  int memberId;
  int gjmId;
  String readName = '';
  void clearId() {
    memberId = null;
  }
}

const buttonWidth = 150.0;

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

    // provider処理
    final pProvider = ref.watch(gameSettingPageProvider(drId));

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('設定'),
          leading: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      gameKindRow(pProvider),
                      rateRow(pProvider),
                      chipRateRow(pProvider),
                      for (var i = 0; i < pProvider.mpList.length; i++)
                        memberRow(context, pProvider, i),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          child: ButtonText('保存'),
                          onPressed: () async {
                            pProvider.saveGameSetting();
                            await pProvider.saveMember();
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
              padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
              width: 100,
              child: TextField(
                textInputAction: TextInputAction.next,
                controller: vm.rateController,
                textAlign: TextAlign.center,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  FilteringTextInputFormatter.singleLineFormatter,
                ],
                decoration: InputDecoration(
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
              width: 100,
              child: TextField(
                  textInputAction: TextInputAction.next,
                  controller: vm.chipRateController,
                  textAlign: TextAlign.center,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    FilteringTextInputFormatter.singleLineFormatter,
                  ],
                  decoration: InputDecoration(
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
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
                    width: 150.w,
                    child: TextField(
                      focusNode: mp.focusNode,
                      textInputAction: TextInputAction.next,
                      controller: mp.controller,
                      textAlign: TextAlign.center,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.singleLineFormatter,
                      ],
                      onChanged: (name) {
                        mp.clearId();
                      },
                      onSubmitted: (value) {
                        // if (index < vm.mpList.length - 1) {
                        //   vm.mpList[index + 1].focusNode.requestFocus();
                        // }
                      },
                    ),
                  ),
                  IconButton(
                      onPressed: () async {
                        final id = await Navigator.of(context)
                            .push<dynamic>(SearchNamePage.route()) as int;

                        vm.setMpList(index, id);
                      },
                      icon: Icon(Icons.search)),
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
          icon: Icon(Icons.add_circle_outline),
          onPressed: () async {
            vm.addMemberProperty();
          },
        ),
      ),
      Visibility(
        visible: vm.removeButtonVisible,
        child: IconButton(
          icon: Icon(Icons.remove_circle_outline),
          onPressed: () async {
            if (vm.isThereScore()) {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('登録されているスコアも削除されますよろしいですか？'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('いいえ'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: Text('はい'),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
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

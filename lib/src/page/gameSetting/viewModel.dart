import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/model/dayRecodeModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/gameJoinMemberModel.dart';
import '../../model/gameSettingModel.dart';
import '../../model/memberModel.dart';
import '../../provider/chipScoreProvider.dart';
import '../../provider/dayRecodeProvider.dart';
import '../../provider/gameJoinMemberProvider.dart';
import '../../provider/gameSettingProvider.dart';
import '../../provider/memberProvider.dart';
import '../../provider/scoreProvider.dart';

const int defaultMemberNum = 4;
const int maxMemberNum = 5;

final gameSettingViewModel = ChangeNotifierProvider.autoDispose
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

    final p = ref.read(gameSettingProvider);
    localFunc(p);
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

  // 保存ボタンが押された
  Future<void> tappedSave() async {
    final dr = await saveDayRecode();
    saveGameSetting();
    await saveMember(dr);
  }

  // drを保存
  Future<DayRecodeModel> saveDayRecode() async {
    // drIdが0でなければすでにあるのでスルー
    if (drId != 0) {
      return null;
    }

    final dr = await ref.read(dayRecodeProvider).newInsert();
    drId = dr.id;

    return dr;
  }

  // ゲーム設定を保存
  void saveGameSetting() {
    final gs = GameSettingModel()
      ..drId = drId
      ..kind = kind.num
      ..rate = int.parse(rateController.text)
      ..chipRate = int.parse(chipRateController.text);
    ref.read(gameSettingProvider).upsert(gs);
  }

  // メンバーを保存
  Future<void> saveMember(DayRecodeModel dayRecode) async {
    var day = '';
    if (dayRecode == null) {
      // drがnullはすでにdrが存在する時なのでread(スコア画面から遷移)
      final dr = ref.read(dayRecodeProvider);
      day = dr.drMap[drId].day;
    } else {
      day = dayRecode.day;
    }

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

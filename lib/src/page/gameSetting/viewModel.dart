import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/model/dayRecodeModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accessor/table/chipScoreAccessor.dart';
import '../../accessor/table/dayRecodeAccessor.dart';
import '../../accessor/table/gameJoinMemberAccesor.dart';
import '../../accessor/table/gameSettingAccessor.dart';
import '../../accessor/table/memberAccessor.dart';
import '../../accessor/table/scoreAccessor.dart';
import '../../model/gameJoinMemberModel.dart';
import '../../model/gameSettingModel.dart';
import '../../model/memberModel.dart';

const int defaultMemberNum = 4;
const int maxMemberNum = 5;

class GameSettingViewModel extends ChangeNotifier {
  GameSettingViewModel(this.ref, this.drId) {
    for (var i = 0; i < defaultMemberNum; i++) {
      mpList.add(MemberProperty());
    }
    initDetailPointSetting();
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
  TextEditingController originPointController = TextEditingController();
  TextEditingController basePointController = TextEditingController();
  TextEditingController firstRankingPointController = TextEditingController();
  TextEditingController secondRankingPointController = TextEditingController();
  TextEditingController thirdRankingPointController = TextEditingController();
  TextEditingController fourthRankingPointController = TextEditingController();
  TextEditingController koController = TextEditingController()
    ..text = koPointDefault.toString();
  InputTypeValue inputType = InputTypeValue.POINT;

  List<GameJoinMemberModelEx> gameJoinedMemberList = [];

  void initDetailPointSetting() {
    originPointController.text = kind.originDefault.toString();
    basePointController.text = kind.baseDefault.toString();
    firstRankingPointController.text = kind.firstDefault.toString();
    secondRankingPointController.text = kind.secondDefault.toString();
    thirdRankingPointController.text = kind.thirdDefault.toString();
    fourthRankingPointController.text = kind.fourthDefault.toString();
  }

  void listenGameSetting() {
    final accessor = ref.read(gameSettingAccessor);
    if (!isInitializedGameSetting) {
      renewGameSetting(drId, accessor);
      isInitializedGameSetting = true;
    }

    ref.listen<GameSettingAccessor>(gameSettingAccessor, (previous, next) {
      if (!isInitializedGameSetting) {
        renewGameSetting(drId, next);
        isInitializedGameSetting = true;
      }
    });
  }

  void renewGameSetting(int id, GameSettingAccessor gsa) {
    if (gsa.isInitialized) {
      if (gsa.drIdMap.containsKey(id)) {
        final gs = gsa.drIdMap[id];
        kind = KindValueExtension.fromInt(gs.kind);
        rateController.text = gs.rate.toString();
        chipRateController.text = gs.chipRate.toString();
        originPointController.text = gs.originPoint.toString();
        basePointController.text = gs.basePoint.toString();
        firstRankingPointController.text = gs.firstPoint.toString();
        secondRankingPointController.text = gs.secondPoint.toString();
        thirdRankingPointController.text = gs.thirdPoint.toString();
        fourthRankingPointController.text = gs.fourthPoint.toString();
      }
    }
  }

  void listenGameJoinedMember() {
    final accessor = ref.read(gameJoinMemberAccessor);
    if (!isInitializedGameJoinedMember) {
      renewMpList(drId, accessor);
      isInitializedGameJoinedMember = true;
    }

    ref.listen<GameJoinMemberAccessor>(gameJoinMemberAccessor,
        (previous, next) {
      if (!isInitializedGameJoinedMember) {
        renewMpList(drId, next);
        isInitializedGameJoinedMember = true;
      }
    });
  }

  void renewMpList(int id, GameJoinMemberAccessor accessor) {
    if (accessor.isInitialized) {
      if (accessor.drIdMap.containsKey(id)) {
        mpList = [];
        final gjmList = accessor.drIdMap[id];
        for (var i = 0; i < gjmList.length; i++) {
          addMemberProperty(gjm: gjmList[i]);
        }
      }
    }
  }

  void setKind(KindValue k) {
    kind = k;

    if (mpList.length < kind.num) {
      for (var i = 0; i < kind.num - mpList.length; i++) {
        mpList.add(MemberProperty());
      }
    }

    initDetailPointSetting();

    addButtonVisible = mpList.length < maxMemberNum;
    removeButtonVisible = mpList.length > kind.num;
    notifyListeners();
  }

  void setMpList(int index, int id) {
    final m = ref.read(memberAccessor).recodeMap[id];
    if (m == null) {
      return;
    }
    mpList[index].memberId = m.id;
    mpList[index].controller.text = m.name;
    notifyListeners();
  }

  void setInputType(InputTypeValue t) {
    inputType = t;
    notifyListeners();
  }

  void addMemberProperty({GameJoinMemberModelEx gjm}) {
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
    return ref.read(scoreAccessor).isThereScore(drId, mpList.length - 1);
  }

  Future<void> removeMemberProperty() async {
    // gjmに関連するデータを削除
    await ref.read(scoreAccessor).deleteNumber(drId, mpList.length - 1);
    await ref.read(chipScoreAccessor).deleteNumber(drId, mpList.length - 1);
    await ref.read(gameJoinMemberAccessor).deleteWithId(mpList.last.gjmId);
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

    final dr = await ref.read(dayRecodeAccessor).newInsert();
    drId = dr.id;

    return dr;
  }

  // ゲーム設定を保存
  void saveGameSetting() {
    final gs = GameSettingModel()
      ..drId = drId
      ..kind = kind.num
      ..rate = int.parse(rateController.text)
      ..chipRate = int.parse(chipRateController.text)
      ..originPoint = int.parse(originPointController.text)
      ..basePoint = int.parse(basePointController.text)
      ..firstPoint = int.parse(firstRankingPointController.text)
      ..secondPoint = int.parse(secondRankingPointController.text)
      ..thirdPoint = int.parse(thirdRankingPointController.text)
      ..fourthPoint = int.parse(fourthRankingPointController.text)
      ..koPoint = int.parse(koController.text)
      ..inputType = inputType.num;
    ref.read(gameSettingAccessor).upsert(gs);
  }

  // メンバーを保存
  Future<void> saveMember(DayRecodeModel dayRecode) async {
    var saveDrId = drId;
    var day = '';
    if (dayRecode == null) {
      // drがnullはすでにdrが存在する時なのでread(スコア画面から遷移した場合)
      final dra = ref.read(dayRecodeAccessor);
      day = dra.drMap[drId].day;
    } else {
      // 新規追加
      saveDrId = dayRecode.id;
      day = dayRecode.day;
    }

    final mAccessor = ref.read(memberAccessor);
    for (var i = 0; i < mpList.length; i++) {
      final m = mpList[i];
      if (m.controller.text == null || m.controller.text == '') {
        continue;
      }
      if (m.memberId == null) {
        // 名前がすでに存在するか確認して、あればそのIDを利用
        m.memberId = mAccessor.getId(m.controller.text);
      } else {
        //　名前が変わっている場合は、IDを変換する必要ある。
        if (m.readName != m.controller.text) {
          m.memberId = mAccessor.getId(m.controller.text);
        }
      }

      // メンバーを保存。新規追加の場合IDがほしいのでawaitで待つ
      final member = MemberModel.fromPara(m.memberId, m.controller.text, day);
      await mAccessor.upsert(member);

      // メンバー参加を保存
      // idは新規ならnull
      final gjmId = dayRecode == null ? m.gjmId : null;
      final gjm = GameJoinMemberModel.fromParam(gjmId, saveDrId, member.id, i);
      ref.read(gameJoinMemberAccessor).upsert(gjm);
    }
  }

  void copySetting(int id) {
    final gsa = ref.read(gameSettingAccessor);
    renewGameSetting(id, gsa);

    final gjm = ref.read(gameJoinMemberAccessor);
    renewMpList(id, gjm);

    notifyListeners();
  }
}

class MemberProperty {
  MemberProperty();
  MemberProperty.fromGjm(GameJoinMemberModelEx gjm) {
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

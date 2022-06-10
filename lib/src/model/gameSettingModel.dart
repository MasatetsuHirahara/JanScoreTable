// ゲーム設定
import '../common/const.dart';
import 'baseModel.dart';

enum KindValue { YONMA, SANMA }

extension KindValueExtension on KindValue {
  static final numbers = {
    KindValue.YONMA: 4,
    KindValue.SANMA: 3,
  };
  int get num => numbers[this];
  static KindValue fromInt(int target) {
    for (final v in KindValue.values) {
      if (target == v.num) {
        return v;
      }
    }
    return KindValue.YONMA;
  }

  static final gameNames = {
    KindValue.YONMA: '4麻',
    KindValue.SANMA: '3麻',
  };
  String get gameName => gameNames[this];
}

enum InputTypeValue { POINT, SOTEN }

extension InputTypeValueExtension on InputTypeValue {
  static final numbers = {
    InputTypeValue.POINT: 1,
    InputTypeValue.SOTEN: 2,
  };
  int get num => numbers[this];
  static InputTypeValue fromInt(int target) {
    for (final v in InputTypeValue.values) {
      if (target == v.num) {
        return v;
      }
    }
    return InputTypeValue.POINT;
  }

  static final gameNames = {
    InputTypeValue.POINT: 'ポイント',
    InputTypeValue.SOTEN: '素点',
  };
  String get gameName => gameNames[this];
}

class GameSettingModel extends BaseModel {
  GameSettingModel();
  GameSettingModel.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnId] as int;
    drId = map[columnDayRecodeId] as int;
    kind = map[columnKind] as int;
    rate = map[columnRate] as int;
    chipRate = map[columnChipRate] as int;
    _placeFee = map[columnPlaceFee] as int;
  }

  int drId;
  int kind; // 三麻四麻
  int rate;
  int chipRate;
  int _placeFee;
  int get placeFee => _placeFee != null ? _placeFee : 0;
  set placeFee(int fee) => _placeFee = fee;
  @override
  Map<String, Object> toMap() {
    final map = <String, Object>{
      columnId: id,
      columnDayRecodeId: drId,
      columnKind: kind,
      columnRate: rate,
      columnChipRate: chipRate,
      columnPlaceFee: placeFee,
    };
    return map;
  }
}

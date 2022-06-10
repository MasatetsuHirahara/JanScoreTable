// ゲーム設定
import '../common/const.dart';
import 'baseModel.dart';

const koPointDefault = 10;

// ignore: constant_identifier_names
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

  static final originPointDefault = {
    KindValue.YONMA: 25000,
    KindValue.SANMA: 35000,
  };
  int get originDefault => originPointDefault[this];
  static final basePointDefault = {
    KindValue.YONMA: 30000,
    KindValue.SANMA: 40000,
  };
  int get baseDefault => basePointDefault[this];
  static final firstPointDefault = {
    KindValue.YONMA: 20,
    KindValue.SANMA: 10,
  };
  int get firstDefault => firstPointDefault[this];
  static final secondPointDefault = {
    KindValue.YONMA: 10,
    KindValue.SANMA: 0,
  };
  int get secondDefault => secondPointDefault[this];
  static final thirdPointDefault = {
    KindValue.YONMA: -10,
    KindValue.SANMA: -10,
  };
  int get thirdDefault => thirdPointDefault[this];
  static final fourthPointDefault = {
    KindValue.YONMA: -20,
    KindValue.SANMA: 0,
  };
  int get fourthDefault => fourthPointDefault[this];

  static final gameNames = {
    KindValue.YONMA: '4麻',
    KindValue.SANMA: '3麻',
  };
  String get gameName => gameNames[this];
}

// ignore: constant_identifier_names
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
    _originPoint = map[columnOriginPoint] as int;
    _basePoint = map[columnBaasePoint] as int;
    _firstPoint = map[columnFirstPoint] as int;
    _originPoint = map[columnOriginPoint] as int;
    _secondPoint = map[columnSecondPoint] as int;
    _fourthPoint = map[columnFourthPoint] as int;
    _koPoint = map[columnKoPoint] as int;
    _fireBirdPoint = map[columnFireBirdPoint] as int;
    inputType = map[columnInputType] as int;
    _placeFee = map[columnPlaceFee] as int;
  }

  int drId;
  int kind; // 三麻四麻
  int rate;
  int chipRate;
  int _originPoint;
  int _basePoint;
  int _firstPoint;
  int _secondPoint;
  int _thirdPoint;
  int _fourthPoint;
  int _koPoint;
  int _fireBirdPoint;
  int inputType;
  int _placeFee;
  int get placeFee => getNullabelColumn(_placeFee);
  set placeFee(int fee) => _placeFee = fee;
  int get originPoint => getNullabelColumn(_originPoint);
  set originPoint(int p) => _originPoint = p;
  int get basePoint => getNullabelColumn(_basePoint);
  set basePoint(int p) => _basePoint = p;
  int get firstPoint => getNullabelColumn(_firstPoint);
  set firstPoint(int p) => _firstPoint = p;
  int get secondPoint => getNullabelColumn(_secondPoint);
  set secondPoint(int p) => _secondPoint = p;
  int get thirdPoint => getNullabelColumn(_thirdPoint);
  set thirdPoint(int p) => _thirdPoint = p;
  int get fourthPoint => getNullabelColumn(_fourthPoint);
  set fourthPoint(int p) => _fourthPoint = p;
  int get koPoint => getNullabelColumn(_koPoint);
  set koPoint(int p) => _koPoint = p;
  int get fireBirdPoint => getNullabelColumn(_fireBirdPoint);
  set fireBirdPoint(int p) => _fireBirdPoint = p;

  int getNullabelColumn(int src) {
    return src != null ? src : 0;
  }

  @override
  Map<String, Object> toMap() {
    final map = <String, Object>{
      columnId: id,
      columnDayRecodeId: drId,
      columnKind: kind,
      columnRate: rate,
      columnChipRate: chipRate,
      columnOriginPoint: _originPoint,
      columnBaasePoint: _basePoint,
      columnFirstPoint: _firstPoint,
      columnSecondPoint: _secondPoint,
      columnThirdPoint: _thirdPoint,
      columnFourthPoint: _fourthPoint,
      columnFireBirdPoint: _fireBirdPoint,
      columnInputType: inputType,
      columnPlaceFee: placeFee,
    };
    return map;
  }
}

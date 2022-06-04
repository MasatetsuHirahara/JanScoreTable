import '../common/const.dart';
import 'baseModel.dart';

class GameJoinMemberModel extends BaseModel {
  GameJoinMemberModel();
  GameJoinMemberModel.fromParam(int id, this.drId, this.mId, this.number) {
    this.id = id;
  }
  GameJoinMemberModel.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnId] as int;
    drId = map[columnDayRecodeId] as int;
    mId = map[columnMemberId] as int;
    number = map[columnNumber] as int;
  }
  int drId;
  int mId;
  int number; // スコア表の並び順

  @override
  Map<String, Object> toMap() {
    final map = <String, Object>{
      columnId: id,
      columnDayRecodeId: drId,
      columnMemberId: mId,
      columnNumber: number
    };
    return map;
  }
}

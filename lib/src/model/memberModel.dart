import '../common/const.dart';
import 'baseModel.dart';

class MemberModel extends BaseModel {
  MemberModel();
  MemberModel.fromPara(int id, this.name, this.lastJoin) {
    this.id = id;
  }
  MemberModel.fromMap(Map<dynamic, dynamic> map) {
    id = map[columnId] as int;
    name = map[columnName] as String;
    lastJoin = map[columnLastJoin] as String;
  }

  String name;
  String lastJoin;

  @override
  Map<String, Object> toMap() {
    final map = <String, Object>{
      columnId: id,
      columnName: name,
      columnLastJoin: lastJoin
    };
    return map;
  }
}

class MemberAccessor extends BaseTableAccessor {
  MemberAccessor() {
    tableName = tableMember;
  }
}

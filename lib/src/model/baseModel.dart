abstract class BaseTableAccessor {
  String tableName;
  String columnId = '_id';
}

abstract class BaseModel {
  int id;
  Map<String, Object> toMap() {}
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../common/const.dart';
import '../model/baseModel.dart';

final dbProvider = ChangeNotifierProvider(
  (ref) => DbModel(),
);

class DbModel extends ChangeNotifier {
  DbModel._internal() {
    open('exsample.db');
  }
  factory DbModel() {
    return _cache;
  }
  static final DbModel _cache = DbModel._internal();
  Database db;
  bool isOpen = false;

  Future open(String path) async {
    final p = getDatabasesPath();
    db = await openDatabase(join(await getDatabasesPath(), path),
        version: 1, onCreate: _onCreate, onConfigure: _onConfigure);

    // open待ちがいる可能性があるので通知
    isOpen = true;
    notifyListeners();
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
create table if not exists $tableDayRecode ( 
  _id integer primary key autoincrement, 
  $columnDay text not null);
''');

    await db.execute('''
create table if not exists $tableMember ( 
  _id integer primary key autoincrement, 
  $columnName text not null,
  $columnLastJoin text not null
  );
''');

    await db.execute('''
 create table if not exists $tableGameSetting (
  _id integer primary key autoincrement,
  $columnDayRecodeId integer,
  $columnKind integer,
  $columnRate integer,
  $columnChipRate integer,
  $columnPlaceFee integer,
  foreign key ($columnDayRecodeId) references $tableDayRecode(_id) on delete cascade
  );
''');

    await db.execute('''
 create table if not exists $tableGameJoinMember (
  _id integer primary key autoincrement, 
  $columnDayRecodeId integer,
  $columnMemberId integer,
  $columnNumber integer,
  foreign key ($columnDayRecodeId) references $tableDayRecode(_id) on delete cascade,
  foreign key ($columnMemberId) references $tableMember(_id),
  unique ($columnDayRecodeId, $columnNumber)
  );
''');

    await db.execute('''
 create table if not exists $tableScore (
 _id integer primary key autoincrement, 
  $columnDayRecodeId integer,
  $columnGameCount integer,
  $columnNumber integer,
  $columnScore integer,
  foreign key ($columnDayRecodeId) references $tableDayRecode(_id) on delete cascade,
  unique ($columnDayRecodeId, $columnGameCount, $columnNumber)
  );
''');

    await db.execute('''
 create table if not exists $tableChipScore (
 _id integer primary key autoincrement,
  $columnDayRecodeId integer,
  $columnNumber integer,
  $columnScore integer,
  foreign key ($columnDayRecodeId) references $tableDayRecode(_id) on delete cascade,
  unique ($columnDayRecodeId, $columnNumber)
  );
''');
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<BaseModel> insert(BaseTableAccessor bta, BaseModel bt) async {
    bt.id = await db.insert(bta.tableName, bt.toMap());
    return bt;
  }

  Future<BaseModel> upsert(BaseTableAccessor bta, BaseModel bt) async {
    bt.id = await db.insert(bta.tableName, bt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return bt;
  }

  Future<List<Map>> rawQuery(String sql) async {
    return db.rawQuery(sql);
  }

  Future<List<Map>> get(BaseTableAccessor bta,
      {List<String> columns,
      String where,
      List<Object> whereArgs,
      String orderBy}) async {
    return db.query(bta.tableName,
        columns: columns, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<int> delete(BaseTableAccessor bta, BaseModel bt) async {
    final column = bta.columnId;
    return db.delete(bta.tableName, where: '$column = ?', whereArgs: [bt.id]);
  }

  Future<int> deleteIds(BaseTableAccessor bta, List<int> ids) async {
    final column = bta.columnId;
    return db.delete(bta.tableName, where: '$column = ?', whereArgs: ids);
  }

  Future<int> rawDelete(String sql) async {
    return db.rawDelete(sql);
  }

  Future<int> update(BaseTableAccessor bta, BaseModel bt) async {
    final column = bta.columnId;
    return db.update(bta.tableName, bt.toMap(),
        where: '$column = ?', whereArgs: [bt.id]);
  }

  Future close() async => db.close();
}

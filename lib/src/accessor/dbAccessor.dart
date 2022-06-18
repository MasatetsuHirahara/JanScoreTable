import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../common/const.dart';
import '../model/baseModel.dart';

final dbAccessor = ChangeNotifierProvider(
  (ref) => DBAccessor(),
);

class DBAccessor extends ChangeNotifier {
  factory DBAccessor() => _cache;
  DBAccessor._internal() {
    open('jan_score_table.db');
  }
  static final DBAccessor _cache = DBAccessor._internal();

  Database db;
  bool isOpen = false;

  Future open(String path) async {
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
  $columnOriginPoint integer,
  $columnBasePoint integer,
  $columnFirstPoint integer,
  $columnSecondPoint integer,
  $columnThirdPoint integer,
  $columnFourthPoint integer,
  $columnKoPoint integer,
  $columnFireBirdPoint integer,
  $columnInputType integer,
  $columnRoundType integer,
  $columnSamePointType integer,
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
  $columnOriginScore integer,
  $columnRank integer,
  $columnRankRemark integer,
  $columnKo integer,
  $columnFireBird integer,
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

  Future<BaseModel> insert(String tableName, BaseModel bt) async {
    bt.id = await db.insert(tableName, bt.toMap());
    return bt;
  }

  Future<BaseModel> upsert(String tableName, BaseModel bt) async {
    bt.id = await db.insert(tableName, bt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return bt;
  }

  Future<List<Map>> rawQuery(String sql) async {
    return db.rawQuery(sql);
  }

  Future<List<Map>> get(String tableName,
      {List<String> columns,
      String where,
      List<Object> whereArgs,
      String orderBy}) async {
    return db.query(tableName,
        columns: columns, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<int> delete(String tableName, BaseModel bt) async {
    return db.delete(tableName, where: '$columnId = ?', whereArgs: [bt.id]);
  }

  Future<int> deleteIds(String tableName, List<int> ids) async {
    return db.delete(tableName, where: '$columnId = ?', whereArgs: ids);
  }

  Future<int> rawDelete(String sql) async {
    return db.rawDelete(sql);
  }

  Future<int> update(String tableName, BaseModel bt) async {
    return db.update(tableName, bt.toMap(),
        where: '$columnId = ?', whereArgs: [bt.id]);
  }

  Future close() async => db.close();
}

import 'package:flutter/material.dart';
import 'package:flutter_app/src/model/baseModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dbAccessor.dart';

abstract class BaseTableAccessor extends ChangeNotifier {
  Ref ref;
  String tableName;

  Future<void> get();

  Future<int> insert(BaseModel bm) async {
    final dbModel = ref.read(dbAccessor);
    await dbModel.insert(tableName, bm);
    await get();
    notifyListeners();
  }

  Future<int> upsert(BaseModel bm) async {
    final dbModel = ref.read(dbAccessor);
    await dbModel.upsert(tableName, bm);
    await get();
    notifyListeners();
  }

  Future<void> update(BaseModel bm) async {
    final dbModel = ref.read(dbAccessor);
    await dbModel.update(tableName, bm);
    await get();
    notifyListeners();
  }

  Future<int> delete(BaseModel bm) async {
    final dba = ref.read(dbAccessor);
    final ret = await dba.delete(tableName, bm);

    // 削除が終わったら同期
    get();

    return ret;
  }
}

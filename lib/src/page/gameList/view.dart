import 'package:flutter/material.dart';
import 'package:flutter_app/src/model/dayRecodeModel.dart';
import 'package:flutter_app/src/model/gameSettingModel.dart';
import 'package:flutter_app/src/page/score/view.dart';
import 'package:flutter_app/src/provider/dayRecodeProvider.dart';
import 'package:flutter_app/src/provider/gameJoinMemberProvider.dart';
import 'package:flutter_app/src/provider/gameSettingProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class abstractCard extends StatelessWidget {
  const abstractCard({this.property, this.onTap, this.onLongTap});
  final RowProperty property;
  final GestureTapCallback onTap;
  final GestureTapCallback onLongTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Dismissible(
        key: UniqueKey(),
        background: Container(
          padding: EdgeInsets.fromLTRB(0, 4, 10, 4),
          alignment: AlignmentDirectional.centerEnd,
          color: Colors.red,
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          onLongTap();
          print('onDismissed');
        },
        confirmDismiss: (direction) async {
          return showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('削除してよろしいですか？'),
                actions: <Widget>[
                  TextButton(
                    child: Text('いいえ'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: Text('はい'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            ListTile(
              trailing: Text('${property.kind}'),
              title: Text('${property.dr.day}'),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final name in property.nameList) Text('$name'),
                ],
              ),
              onTap: onTap,
              onLongPress: onLongTap,
            ),
          ],
        ),
      ),
    );
  }
}

class DrProperty {
  GameSettingModel gameSettingModel;
  List<GameJoinMemberView> memberList = [];
}

class RowProperty {
  RowProperty() {}
  DayRecodeModel dr;
  String kind;
  List<String> nameList = [];
}

final gameListViewProvider = ChangeNotifierProvider.autoDispose((ref) {
  return GameListViewModel(ref);
});

class GameListViewModel extends ChangeNotifier {
  GameListViewModel(this.ref) {
    listenDayRecode();
    listenGameSetting();
    listenGameJoinModel();
  }
  Ref ref;
  Map<int, DrProperty> drPropertyMap = {};
  List<DayRecodeModel> drList = [];

  void listenDayRecode() {
    localFunc(DayRecodeNotifier p) {
      if (p.isInitialized) {
        drList = p.drList;
        notifyListeners();
      }
    }

    final p = ref.watch(dayRecodeProvider);
    localFunc(p);
  }

  void listenGameSetting() {
    localFunc(GameSettingNotifier p) {
      if (p.isInitialized) {
        p.drIdMap.forEach((key, value) {
          if (drPropertyMap.containsKey(key)) {
            drPropertyMap[key].gameSettingModel = value;
          } else {
            drPropertyMap[key] = DrProperty()..gameSettingModel = value;
          }
        });
        notifyListeners();
      }
    }

    final p = ref.watch(gameSettingProvider);
    localFunc(p);
  }

  void listenGameJoinModel() {
    localFunc(GameJoinMemberNotifier p) {
      if (p.isInitialized) {
        p.drIdMap.forEach((key, value) {
          if (drPropertyMap.containsKey(key)) {
            drPropertyMap[key].memberList = value;
          } else {
            drPropertyMap[key] = DrProperty()..memberList = value;
          }
        });
        notifyListeners();
      }
    }

    final p = ref.watch(gameJoinMemberProvider);
    localFunc(p);
  }

  List<RowProperty> getProperty() {
    final ret = <RowProperty>[];

    // drListを基準に各要素をセットしていく
    for (final dr in drList) {
      final rProperty = RowProperty()..dr = dr;

      final dp = drPropertyMap[dr.id];
      if (dp == null) {
        continue;
      }

      if (dp.gameSettingModel != null) {
        final kind = KindValueExtension.fromInt(dp.gameSettingModel.kind);
        rProperty.kind = kind.gameName;
      }

      for (final m in dp.memberList) {
        rProperty.nameList.add(m.name);
      }

      ret.add(rProperty);
    }

    return ret;
  }

  void deleteDayRecode(int index) {
    if (drList.contains(index) == false) {
      return;
    }

    ref.read(dayRecodeProvider).delete(drList[index]);
  }
}

class GameListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(gameListViewProvider);

    final rowPropertyList = vm.getProperty();
    return Scaffold(
      appBar: AppBar(
        title: Text('home'),
      ),
      body: SafeArea(
        child: Center(
          child: ListView.builder(
              itemCount: rowPropertyList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 4, 8.0, 4),
                  child: abstractCard(
                      property: rowPropertyList[index],
                      onTap: () {
                        Navigator.of(context).push<dynamic>(ScorePage.route(
                            drId: rowPropertyList[index].dr.id));
                      },
                      onLongTap: () {
                        vm.deleteDayRecode(index);
                      }),
                );
              }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //drProvider.newInsert();
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

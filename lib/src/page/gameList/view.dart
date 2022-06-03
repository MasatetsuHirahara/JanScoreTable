import 'package:flutter/material.dart';
import 'package:flutter_app/src/page/gameList/viewModel.dart';
import 'package:flutter_app/src/page/score/view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(gameListViewProvider);

    final cardPropertyList = vm.getProperty();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ゲーム一覧'),
      ),
      body: SafeArea(
        child: Center(
          child: ListView.builder(
              itemCount: cardPropertyList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  child: DayRecodeCard(
                      property: cardPropertyList[index],
                      onTap: () {
                        Navigator.of(context).push<dynamic>(ScorePage.route(
                            drId: cardPropertyList[index].dr.id));
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
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class DayRecodeCard extends StatelessWidget {
  const DayRecodeCard({this.property, this.onTap, this.onLongTap});
  final CardProperty property;
  final GestureTapCallback onTap;
  final GestureTapCallback onLongTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Dismissible(
        key: UniqueKey(),
        background: Container(
          padding: const EdgeInsets.fromLTRB(0, 4, 10, 4),
          alignment: AlignmentDirectional.centerEnd,
          color: Colors.red,
          child: const Icon(
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
                title: const Text('削除してよろしいですか？'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('いいえ'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: const Text('はい'),
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

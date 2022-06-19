import 'package:flutter/material.dart';
import 'package:flutter_app/src/page/gameList/viewModel.dart';
import 'package:flutter_app/src/widget/text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widget/dialog.dart';
import '../base/baseBottomNavigationItemPage.dart';
import '../gameSetting/view.dart';
import '../score/view.dart';

final _viewModel = ChangeNotifierProvider.autoDispose((ref) {
  return GameListViewModel(ref);
});

class GameListPage extends BaseBottomNavigationItemPage {
  GameListPage() {
    title = '点数表一覧';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(_viewModel);

    final cardPropertyList = vm.getProperty();
    return SafeArea(
      child: Stack(
        children: [
          Center(
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
                        deleteAction: () async {
                          vm.deleteDayRecode(index);
                        }),
                  );
                }),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: () {
                  // まだdrはないので0を渡す
                  Navigator.of(context)
                      .push<dynamic>(GameSettingPage.route(drId: 0));
                },
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DayRecodeCard extends StatelessWidget {
  const DayRecodeCard({this.property, this.onTap, this.deleteAction});
  final CardProperty property;
  final GestureTapCallback onTap;
  final GestureTapCallback deleteAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.black,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
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
          deleteAction();
          print('onDismissed');
        },
        confirmDismiss: (direction) async {
          return showDialog(
            context: context,
            builder: (context) {
              return const DeleteDialog('削除してよろしいですか？');
            },
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            ListTile(
                trailing: NormalText('${property.kind}'),
                title: NormalText('${property.dr.day}'),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final name in property.nameList) Text('$name'),
                  ],
                ),
                onTap: onTap,
                onLongPress: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return const DeleteDialog('削除してよろしいですか？');
                    },
                  );
                  if (result) {
                    deleteAction();
                  }
                }),
          ],
        ),
      ),
    );
  }
}

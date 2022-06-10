import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/page/copySetting/viewModel.dart';
import 'package:flutter_app/src/widget/text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const buttonWidth = 150.0;

final _viewModel = ChangeNotifierProvider.autoDispose((ref) {
  return CopySettingViewModel(ref);
});

class CopySettingPage extends ConsumerWidget {
  static Route<dynamic> route() {
    return MaterialPageRoute<dynamic>(
        builder: (_) => CopySettingPage(),
        settings: const RouteSettings(),
        fullscreenDialog: true);
  }

  @override
  void dispose() {
    print('dispose !!!!!!!!');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(_viewModel);
    final cardPropertyList = vm.getProperty();
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('設定コピー'),
          leading: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
                        Navigator.of(context)
                            .pop(cardPropertyList[index].dr.id);
                      }),
                );
              },
            ),
          ),
        ));
  }
}

class DayRecodeCard extends StatelessWidget {
  const DayRecodeCard({this.property, this.onTap});
  final CardProperty property;
  final GestureTapCallback onTap;

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
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/page/searchName/viewModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _viewModel = ChangeNotifierProvider.autoDispose((ref) {
  return SearchNameViewModel(ref);
});

class SearchNamePage extends ConsumerWidget {
  static Route<dynamic> route() {
    return MaterialPageRoute<dynamic>(
        builder: (_) => SearchNamePage(),
        settings: const RouteSettings(),
        fullscreenDialog: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(_viewModel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('名前検索'),
        leading: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => Navigator.of(context).pop(0),
        ),
      ),
      body: SafeArea(
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InputCard(vm.inputProperty, (value) {
                vm.onChangeName();
              }),
              const SizedBox(
                height: 8,
              ),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: vm.resultPropertyList.length,
                  itemBuilder: (context, index) {
                    return ResultCard(
                      vm.resultPropertyList[index],
                      () {
                        Navigator.of(context)
                            .pop(vm.resultPropertyList[index].id);
                      },
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  const ResultCard(this.resultProperty, this.onTap);
  final ResultProperty resultProperty;
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
      child: ListTile(
        title: Text(resultProperty.name),
        trailing: Text(resultProperty.lastDay),
        onTap: onTap,
      ),
    );
  }
}

class InputCard extends StatelessWidget {
  const InputCard(this.property, this.valueChanged);
  final InputProperty property;
  final ValueChanged<String> valueChanged;

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: TextField(
          controller: property.controller,
          textAlign: TextAlign.left,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.singleLineFormatter,
          ],
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: valueChanged,
        ),
      ),
    );
  }
}

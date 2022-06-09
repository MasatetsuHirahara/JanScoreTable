import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/page/personalList/viewModel.dart';
import 'package:flutter_app/src/page/personalScore/view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../base/baseBottomNavigationItemPage.dart';

final _viewModel = ChangeNotifierProvider.autoDispose((ref) {
  return PersonalListViewModel(ref);
});

class PersonalListPage extends BaseBottomNavigationItemPage {
  PersonalListPage() {
    title = '個人成績一覧';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(_viewModel);

    return SafeArea(
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
            Expanded(
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: vm.resultPropertyList.length,
                  itemBuilder: (context, index) {
                    final result = vm.resultPropertyList[index];
                    return ResultCard(
                      result,
                      () {
                        Navigator.of(context).push<dynamic>(
                            PersonalScorePage.route(mId: result.id));
                      },
                    );
                  }),
            ),
          ],
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

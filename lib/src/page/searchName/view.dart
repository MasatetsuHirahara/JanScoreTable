import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/page/searchName/viewModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO
//　検索

class SearchNamePage extends ConsumerWidget {
  static Route<dynamic> route() {
    return MaterialPageRoute<dynamic>(
        builder: (_) => SearchNamePage(),
        settings: const RouteSettings(),
        fullscreenDialog: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 画面サイズ
    var _screenSize = MediaQuery.of(context).size;

    final vm = ref.watch(searchNameViewModel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('名前検索'),
        leading: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InputCard(vm.inputProperty, (value) {}),
              // Container(
              //   width: _screenSize.width,
              //   padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              //   alignment: Alignment.center,
              //   child: TextField(
              //     controller: nameController,
              //     inputFormatters: <TextInputFormatter>[
              //       FilteringTextInputFormatter.singleLineFormatter,
              //     ],
              //     decoration: InputDecoration(
              //       prefixIcon: Icon(Icons.search),
              //     ),
              //   ),
              // ),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: vm.resultPropertyList.length,
                  itemBuilder: (context, index) {
                    return ResultCard(vm.resultPropertyList[index]);
                  }),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  ResultCard(this.resultProperty);

  ResultProperty resultProperty;

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
      child: TextField(
        controller: property.controller,
        textAlign: TextAlign.center,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.singleLineFormatter,
        ],
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
        ),
        onSubmitted: valueChanged,
      ),
    );
  }
}

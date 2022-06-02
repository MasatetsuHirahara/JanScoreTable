import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/provider/memberProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO
//　検索

final _pageProvider = ChangeNotifierProvider.autoDispose((ref) {
  return PageModel();
});

class PageModel extends ChangeNotifier {}

class SearchNamePage extends ConsumerWidget {
  static Route<dynamic> route() {
    return MaterialPageRoute<dynamic>(
        builder: (_) => SearchNamePage(),
        settings: RouteSettings(),
        fullscreenDialog: true);
  }

  final nameController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 画面サイズ
    var _screenSize = MediaQuery.of(context).size;

    // provider
    final mProvider = ref.watch(memberProvider);

    final List<int> searchResult = [];
    for (final m in mProvider.recodeList) {
      searchResult.add(m.id);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('名前検索'),
        leading: IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: _screenSize.width,
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                alignment: Alignment.center,
                child: TextField(
                  controller: nameController,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.singleLineFormatter,
                  ],
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchResult.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title:
                          Text(mProvider.recodeMap[searchResult[index]].name),
                      onTap: () {
                        Navigator.of(context).pop(searchResult[index]);
                      },
                    );
                  }),
            ]),
      ),
    );
  }
}

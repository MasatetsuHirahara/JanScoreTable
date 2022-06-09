import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/page/home/viewModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final viewModel = ChangeNotifierProvider.autoDispose((ref) {
  return HomePageViewModel();
});

class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(viewModel);

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.getTitle()),
      ),
      body: vm.getPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: '点数表',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: '個人成績',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_support_outlined),
            label: 'アプリについて',
          ),
        ],
        currentIndex: vm.index,
        onTap: (index) {
          vm.setIndex(index);
        },
      ),
    );
  }
}

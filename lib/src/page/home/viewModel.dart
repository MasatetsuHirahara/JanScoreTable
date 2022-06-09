import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/page/personalList/view.dart';

import '../base/baseBottomNavigationItemPage.dart';
import '../gameList/view.dart';

class HomePageViewModel extends ChangeNotifier {
  HomePageViewModel() {
    pageList = [
      GameListPage(),
      PersonalListPage(),
      GameListPage(),
    ];
  }

  List<BaseBottomNavigationItemPage> pageList;
  int index = 0;

  void setIndex(int index) {
    this.index = index;
    notifyListeners();
  }

  BaseBottomNavigationItemPage getPage() {
    if (pageList.length <= index) {
      return null;
    }
    return pageList[index];
  }

  String getTitle() {
    if (pageList.length <= index) {
      return '';
    }

    return pageList[index].title;
  }
}

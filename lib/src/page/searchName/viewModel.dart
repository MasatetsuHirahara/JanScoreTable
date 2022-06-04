import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/accessor/recentyMember.dart';
import 'package:flutter_app/src/model/memberModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const recentlyMemberNum = 8;

final _recentlyMember =
    ChangeNotifierProvider.family<RecentlyMemberAccessor, int>((ref, limit) {
  return RecentlyMemberAccessor(ref, limit);
});

final searchNameViewModel = ChangeNotifierProvider.autoDispose((ref) {
  return SearchNameViewModel(ref);
});

class SearchNameViewModel extends ChangeNotifier {
  SearchNameViewModel(this.ref) {
    watchRecentlyMember();
  }

  Ref ref;
  InputProperty inputProperty = InputProperty();
  List<ResultProperty> resultPropertyList = [];

  void watchRecentlyMember() {
    final accessor = ref.watch(_recentlyMember(recentlyMemberNum));

    resultPropertyList = [];
    for (final m in accessor.memberList) {
      resultPropertyList.add(ResultProperty.fromMember(m));
    }

    notifyListeners();
  }
}

class InputProperty {
  InputProperty();
  TextEditingController controller = TextEditingController();
}

class ResultProperty {
  ResultProperty();
  ResultProperty.fromMember(MemberModel member) {
    name = member.name;
    lastDay = member.lastJoin;
  }

  String name;
  String lastDay;
}

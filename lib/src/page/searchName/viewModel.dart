import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/accessor/searchMember.dart';
import 'package:flutter_app/src/model/memberModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const recentlyMemberNum = 8;

final _searchMember =
    ChangeNotifierProvider.family<SearchMemberAccessor, int>((ref, limit) {
  return SearchMemberAccessor(ref);
});

class SearchNameViewModel extends ChangeNotifier {
  SearchNameViewModel(this.ref) {
    getMember();
  }

  Ref ref;
  InputProperty inputProperty = InputProperty();
  List<ResultProperty> resultPropertyList = [];

  Future<void> getMember() async {
    final memberList = await ref
        .read(_searchMember(recentlyMemberNum))
        .get(inputProperty.controller.text, recentlyMemberNum);

    resultPropertyList = [];
    for (final m in memberList) {
      resultPropertyList.add(ResultProperty.fromMember(m));
    }

    notifyListeners();
  }

  void onChangeName() {
    getMember();
  }
}

class InputProperty {
  InputProperty();
  TextEditingController controller = TextEditingController()..text = '';
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

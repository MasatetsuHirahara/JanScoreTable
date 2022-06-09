import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/accessor/searchMember.dart';
import 'package:flutter_app/src/model/memberModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _searchMember = ChangeNotifierProvider.autoDispose((ref) {
  return SearchMemberAccessor(ref);
});

class PersonalListViewModel extends ChangeNotifier {
  PersonalListViewModel(this.ref) {
    getMember();
  }

  Ref ref;
  InputProperty inputProperty = InputProperty();
  List<ResultProperty> resultPropertyList = [];

  Future<void> getMember() async {
    final memberList =
        await ref.read(_searchMember).get(inputProperty.controller.text);

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
    id = member.id;
    name = member.name;
    lastDay = member.lastJoin;
  }
  int id;
  String name;
  String lastDay;
}

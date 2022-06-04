import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchNameViewModel = ChangeNotifierProvider.autoDispose((ref) {
  return SearchNameViewModel();
});

class SearchNameViewModel extends ChangeNotifier {
  InputProperty inputProperty = InputProperty();
  List<ResultProperty> resultPropertyList = [];
}

class InputProperty {
  InputProperty();
  TextEditingController controller = TextEditingController();
}

class ResultProperty {
  String name;
  String lastDay;
}

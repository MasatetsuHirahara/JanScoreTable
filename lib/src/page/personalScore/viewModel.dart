import 'package:flutter/cupertino.dart';
import 'package:flutter_app/src/accessor/personalScore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/gameSettingModel.dart';

final _personalScoreAccessor = ChangeNotifierProvider.autoDispose
    .family<PersonalScoreAccessor, int>((ref, mId) {
  return PersonalScoreAccessor(ref, mId);
});

class ResultProperty {
  ResultProperty();
  int firstCnt = 0;
  int secondCnt = 0;
  int thirdCnt = 0;
  int fourthCnt = 0;
  int joinCnt = 0;
  int totalScore = 0;
  int totalValue = 0;

  double averageRation() {
    if (joinCnt == 0) {
      return 0;
    }

    var total = firstCnt * 1;
    total += secondCnt * 2;
    total += thirdCnt * 3;
    total += fourthCnt * 4;

    return total / joinCnt;
  }

  double rentaiRation() {
    if (joinCnt == 0) {
      return 0;
    }
    return (firstCnt + secondCnt) / joinCnt * 100;
  }

  double firstRation() {
    if (joinCnt == 0) {
      return 0;
    }
    return firstCnt / joinCnt * 100;
  }

  double secondRation() {
    if (joinCnt == 0) {
      return 0;
    }
    return secondCnt / joinCnt * 100;
  }

  double thirdRation() {
    if (joinCnt == 0) {
      return 0;
    }
    return thirdCnt / joinCnt * 100;
  }

  double fourthRation() {
    if (joinCnt == 0) {
      return 0;
    }
    return fourthCnt / joinCnt * 100;
  }

  void cntUp(int rank) {
    joinCnt++;

    switch (rank) {
      case 1:
        firstCnt++;
        break;
      case 2:
        secondCnt++;
        break;
      case 3:
        thirdCnt++;
        break;
      case 4:
        fourthCnt++;
        break;
      default:
        break;
    }
  }
}

class PersonalScoreViewModel extends ChangeNotifier {
  PersonalScoreViewModel(this.ref, this.mId) {
    get();
  }

  Ref ref;
  int mId;
  double maxX = 0;
  double maxY = 0;
  double minY = 0;

  ResultProperty result3 = ResultProperty();
  ResultProperty result4 = ResultProperty();
  String name;

  Future<void> get() async {
    final scoreList = await ref.read(_personalScoreAccessor(mId)).get();

    result3 = ResultProperty();
    result4 = ResultProperty();
    for (final s in scoreList) {
      print('R4 ${result4.totalScore}');
      name = s.name;

      var result = result4;
      if (s.kind == KindValue.SANMA.num) {
        result = result3;
      } else {
        print('s score: ${s.score}');
      }

      // スコア表のセルが空欄にされているケースはスルー
      if (s.score == null || s.rate == null) {
        continue;
      }
      result
        ..cntUp(s.rank)
        ..totalScore += s.score
        ..totalValue += s.score * s.rate;
    }
    print('END ${result4.totalScore}');
    notifyListeners();
  }
}

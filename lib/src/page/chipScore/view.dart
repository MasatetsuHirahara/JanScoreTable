import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/page/chipScore/viewModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../widget/text.dart';

final _viewModel = ChangeNotifierProvider.autoDispose
    .family<ChipScoreViewModel, int>((ref, drId) {
  return ChipScoreViewModel(ref, drId);
});

const cellHeight = 50.0;

// ignore: must_be_immutable
class ChipScorePage extends ConsumerWidget {
  static Route<dynamic> route({
    @required int drId,
  }) {
    return MaterialPageRoute<dynamic>(
        builder: (_) => ChipScorePage(),
        settings: RouteSettings(arguments: drId),
        fullscreenDialog: true);
  }

  int drId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 引数処理
    drId = ModalRoute.of(context).settings.arguments as int;
    final provider = ref.watch(_viewModel(drId));
    final isInvalid = provider.getTotal() != 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('チップ入力'),
        leading: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: cellHeight.h * provider.chipRowList.length,
                  child: ListView.builder(
                    itemCount: provider.chipRowList.length,
                    itemBuilder: (context, index) {
                      return chipRowWidget(index, provider);
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    child: const ButtonText('保存'),
                    onPressed: isInvalid
                        ? null
                        : () async {
                            await provider.saveScore();
                            Navigator.of(context).pop();
                          },
                  ),
                ),
                isInvalid
                    ? ErrorText('${provider.getTotal()}枚ずれています')
                    : const Text(''),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget chipRowWidget(int index, ChipScoreViewModel viewModel) {
  final rowProperty = viewModel.chipRowList[index];
  return Container(
    child: Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              child: NormalText('${rowProperty.chipScoreView.name}'),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 0, 0),
              child: SizedBox(
                width: 100.w,
                height: 50.h,
                child: TextField(
                  style: TextStyle(
                    color: rowProperty.chipScoreView.score >= 0
                        ? Colors.black
                        : Colors.red,
                  ),
                  controller: rowProperty.controller,
                  focusNode: rowProperty.focusNode,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9]')),
                    FilteringTextInputFormatter.singleLineFormatter,
                  ],
                  onTap: () {
                    final currentFocus = viewModel.getFocusIndex();

                    // フォーカスがなければスルー
                    if (currentFocus < 0) {
                      return;
                    }

                    // フォーカス中に他のフィールドをタップしたので、afterを呼ぶ
                    if (index != currentFocus) {
                      viewModel.afterInput(currentFocus);
                    }
                  },
                  onSubmitted: (src) {
                    viewModel.afterInput(index);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/src/page/adjustment/viewModel.dart';
import 'package:flutter_app/src/widget/text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final _viewModel = ChangeNotifierProvider.autoDispose
    .family<AdjustmentViewModel, int>((ref, drId) {
  return AdjustmentViewModel(ref, drId);
});

const cellHeight = 50.0;

class PlaceFeeCard extends StatelessWidget {
  const PlaceFeeCard(this.controller, this.onSubmitted);

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

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
        title: HeadingText('場代'),
        trailing: SizedBox(
          width: 100.w,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              FilteringTextInputFormatter.singleLineFormatter,
            ],
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }
}

class PointCard extends StatelessWidget {
  const PointCard(this.property);

  final PointProperty property;

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
      child: ExpansionTile(
        title: HeadingText(property.name),
        trailing: ScoreText(
          property.totalPoint,
          trailing: 'G',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('スコア  '),
                ScoreText(
                  property.point,
                  trailing: 'G',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('チップ代  '),
                ScoreText(
                  property.chipPoint,
                  trailing: 'G',
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8.0,
          )
        ],
      ),
    );
  }
}

class AdjustmentPage extends ConsumerWidget {
  static Route<dynamic> route({
    @required int drId,
  }) {
    return MaterialPageRoute<dynamic>(
        builder: (_) => AdjustmentPage(),
        settings: RouteSettings(arguments: drId),
        fullscreenDialog: true);
  }

  int drId;

  @override
  void dispose() {
    print('dispose !!!!!!!!');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 引数処理
    drId = ModalRoute.of(context).settings.arguments as int;

    // provider処理
    final provider = ref.watch(_viewModel(drId));

    return Scaffold(
        appBar: AppBar(
          title: const Text('精算'),
          leading: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  for (final p in provider.pointList) PointCard(p),
                  const SizedBox(
                    height: 16,
                  ),
                  PlaceFeeCard(provider.placeFeeController, (String value) {
                    provider.setPointPropertyList();
                  }),
                ],
              ),
            ),
          ),
        ));
  }
}

Widget scoreRowWidget(int index, AdjustmentViewModel viewModel) {
  final rowProperty = viewModel.pointList[index];
  return Container(
    child: Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Text('${rowProperty.name}'),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 0, 0, 0),
              child: Text(
                '${rowProperty.point}',
                style: TextStyle(
                  backgroundColor: Colors.red,
                  color: rowProperty.point >= 0 ? Colors.black : Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

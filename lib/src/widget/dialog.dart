import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget {
  const DeleteDialog(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final text = Text(title);
    final actions = <Widget>[
      TextButton(
        child: const Text('いいえ'),
        onPressed: () => Navigator.of(context).pop(false),
      ),
      TextButton(
        child: const Text('はい'),
        onPressed: () {
          Navigator.of(context).pop(true);
        },
      ),
    ];

    return Platform.isAndroid
        ? AlertDialog(title: text, actions: actions)
        : CupertinoAlertDialog(title: text, actions: actions);
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget {
  const DeleteDialog(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      actions: <Widget>[
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
      ],
    );
  }
}

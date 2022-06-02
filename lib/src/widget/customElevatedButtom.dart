import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SaveButton extends CustomElevatedButton {
  SaveButton(Key key, VoidCallback onPressed) : super(key, '保存する', onPressed);
}

class CustomElevatedButton extends StatelessWidget {
  CustomElevatedButton(Key key, this.text, this.onPressed) : super(key: key);
  String text;
  VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      //color: Theme.of(context).primaryColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              onPrimary: Colors.black,
              side: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 3,
              ),
              textStyle: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            child: Text('$text'),
            onPressed: this.onPressed,
          ),
        ),
      ),
    );
  }
}

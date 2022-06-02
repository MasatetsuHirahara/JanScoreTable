import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HeadingText extends StatelessWidget {
  HeadingText(this.text, {this.color = Colors.black});
  String text;
  Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$text',
      style: TextStyle(
        color: color,
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class NormalText extends StatelessWidget {
  NormalText(this.text, {this.color = Colors.black});
  String text;
  Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$text',
      style: TextStyle(
        color: color,
        fontSize: 16.sp,
      ),
    );
  }
}

class ButtonText extends StatelessWidget {
  ButtonText(this.text);
  String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      '$text',
      style: TextStyle(
        fontSize: 16.sp,
      ),
    );
  }
}

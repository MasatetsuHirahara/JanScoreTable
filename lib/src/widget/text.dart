import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HeadingText extends StatelessWidget {
  const HeadingText(this.text, {this.color = Colors.black});
  final String text;
  final Color color;

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
  const NormalText(this.text, {this.color = Colors.black});
  final String text;
  final Color color;

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

class ErrorText extends StatelessWidget {
  const ErrorText(this.text, {this.color = Colors.red});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$text',
      style: TextStyle(
        color: color,
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class ButtonText extends StatelessWidget {
  const ButtonText(this.text);
  final String text;
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

class ScoreText extends StatelessWidget {
  const ScoreText(this.score, {this.trailing});
  final String trailing;
  final int score;
  @override
  Widget build(BuildContext context) {
    var text = score.toString();
    if (trailing != null) {
      text += ' $trailing';
    }
    return Text(
      text,
      style: TextStyle(
        color: score >= 0 ? Colors.black : Colors.red,
        fontSize: 16.sp,
      ),
    );
  }
}

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

class CaptionText extends StatelessWidget {
  const CaptionText(this.text, {this.color = Colors.black});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$text',
      style: TextStyle(
        color: color,
        fontSize: 12.sp,
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
  const ScoreText(this.score,
      {this.trailing, this.fontSize = 16, this.forceColor = null});
  final String trailing;
  final int score;
  final double fontSize;
  final Color forceColor;
  @override
  Widget build(BuildContext context) {
    var text = score != null ? score.toString() : '';
    if (trailing != null) {
      text += ' $trailing';
    }
    var color = (score != null && score >= 0) ? Colors.black : Colors.red;
    if (forceColor != null) {
      color = forceColor;
    }
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize.sp,
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';

class SpeechBubble extends ShapeBorder {
  const SpeechBubble({this.usePadding = true});

  final bool usePadding;
  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(bottom: usePadding ? 12 : 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) => null;

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    final r =
        Rect.fromPoints(rect.topLeft, rect.bottomRight - const Offset(0, 12));
    return Path()
      ..addRRect(RRect.fromRectAndRadius(r, Radius.circular(8)))
      ..moveTo(r.bottomCenter.dx - 10, r.bottomCenter.dy)
      ..relativeLineTo(10, 12)
      ..relativeLineTo(10, -12)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

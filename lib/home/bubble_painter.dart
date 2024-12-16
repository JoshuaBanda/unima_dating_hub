import 'package:flutter/material.dart';

class BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.green.shade100;
    Path bubblePath = Path();

    // Draw bubble body
    bubblePath.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(0, 0, size.width, size.height), const Radius.circular(15)));

    // Bottom pointer
    bubblePath.moveTo(size.width / 2 - 10, size.height);
    bubblePath.lineTo(size.width / 2, size.height + 10);
    bubblePath.lineTo(size.width / 2 + 10, size.height);

    // Top pointer
    bubblePath.moveTo(size.width / 2 - 10, 0);
    bubblePath.lineTo(size.width / 2, -10);
    bubblePath.lineTo(size.width / 2 + 10, 0);

    canvas.drawPath(bubblePath, paint);

    // Droplets
    canvas.drawCircle(Offset(size.width / 4, size.height + 20), 5, paint);
    canvas.drawCircle(Offset(size.width * 3 / 4, size.height + 15), 5, paint);
    canvas.drawCircle(Offset(size.width / 4, -20), 5, paint);
    canvas.drawCircle(Offset(size.width * 3 / 4, -15), 5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

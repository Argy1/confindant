import 'package:flutter/material.dart';

enum AppLineIconKind { wallet, trend, pie, shield }

class AppLineIcon extends StatelessWidget {
  const AppLineIcon({
    super.key,
    required this.kind,
    required this.color,
    this.size = 48,
    this.strokeWidth = 4,
  });

  final AppLineIconKind kind;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppLineIconPainter(
          kind: kind,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _AppLineIconPainter extends CustomPainter {
  _AppLineIconPainter({
    required this.kind,
    required this.color,
    required this.strokeWidth,
  });

  final AppLineIconKind kind;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (kind) {
      case AppLineIconKind.wallet:
        _drawWallet(canvas, size, p);
        break;
      case AppLineIconKind.trend:
        _drawTrend(canvas, size, p);
        break;
      case AppLineIconKind.pie:
        _drawPie(canvas, size, p);
        break;
      case AppLineIconKind.shield:
        _drawShield(canvas, size, p);
        break;
    }
  }

  void _drawWallet(Canvas canvas, Size size, Paint p) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.62, h * 0.56),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(body, p);

    final pocket = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.56, h * 0.38, w * 0.30, h * 0.26),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(pocket, p);
    canvas.drawCircle(Offset(w * 0.74, h * 0.51), w * 0.03, p);
  }

  void _drawTrend(Canvas canvas, Size size, Paint p) {
    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.66)
      ..lineTo(size.width * 0.40, size.height * 0.40)
      ..lineTo(size.width * 0.56, size.height * 0.56)
      ..lineTo(size.width * 0.82, size.height * 0.30);
    canvas.drawPath(path, p);
    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.30),
      Offset(size.width * 0.66, size.height * 0.30),
      p,
    );
    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.30),
      Offset(size.width * 0.82, size.height * 0.46),
      p,
    );
  }

  void _drawPie(Canvas canvas, Size size, Paint p) {
    final r = size.width * 0.30;
    final c = Offset(size.width * 0.50, size.height * 0.55);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), 0.8, 4.4, false, p);

    final slice = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(c.dx, c.dy - r)
      ..arcTo(Rect.fromCircle(center: c, radius: r), -1.57, 1.57, false)
      ..close();
    canvas.drawPath(slice, p);
  }

  void _drawShield(Canvas canvas, Size size, Paint p) {
    final path = Path()
      ..moveTo(size.width * 0.50, size.height * 0.14)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.22,
        size.width * 0.28,
        size.height * 0.24,
        size.width * 0.24,
        size.height * 0.28,
      )
      ..lineTo(size.width * 0.24, size.height * 0.48)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.67,
        size.width * 0.36,
        size.height * 0.80,
        size.width * 0.50,
        size.height * 0.88,
      )
      ..cubicTo(
        size.width * 0.64,
        size.height * 0.80,
        size.width * 0.76,
        size.height * 0.67,
        size.width * 0.76,
        size.height * 0.48,
      )
      ..lineTo(size.width * 0.76, size.height * 0.28)
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.24,
        size.width * 0.62,
        size.height * 0.22,
        size.width * 0.50,
        size.height * 0.14,
      )
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _AppLineIconPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

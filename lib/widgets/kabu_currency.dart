import 'package:flutter/material.dart';

class KabuMark extends StatelessWidget {
  const KabuMark({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _KabuMarkPainter(
      leafColor: color ?? const Color(0xFF3C8A62),
      rootColor: color ?? const Color(0xFFD68A72),
    ),
  );
}

class KabuCurrencyText extends StatelessWidget {
  const KabuCurrencyText({
    super.key,
    required this.text,
    this.style,
    this.markSize = 18,
    this.markColor,
    this.gap = 5,
  });

  final String text;
  final TextStyle? style;
  final double markSize;
  final Color? markColor;
  final double gap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      KabuMark(size: markSize, color: markColor),
      SizedBox(width: gap),
      Text(text, style: style),
    ],
  );
}

class _KabuMarkPainter extends CustomPainter {
  const _KabuMarkPainter({required this.leafColor, required this.rootColor});

  final Color leafColor;
  final Color rootColor;

  @override
  void paint(Canvas canvas, Size size) {
    final leaf = Paint()..color = leafColor;
    final root = Paint()..color = rootColor;
    final outline = Paint()
      ..color = Colors.black.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .055;

    final leaves = Path()
      ..moveTo(size.width * .48, size.height * .34)
      ..quadraticBezierTo(
        size.width * .18,
        size.height * .22,
        size.width * .16,
        size.height * .04,
      )
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .04,
        size.width * .58,
        size.height * .27,
      )
      ..close();
    canvas.drawPath(leaves, leaf);
    canvas.drawPath(leaves, outline);

    final secondLeaf = Path()
      ..moveTo(size.width * .48, size.height * .33)
      ..quadraticBezierTo(
        size.width * .56,
        size.height * .05,
        size.width * .88,
        size.height * .08,
      )
      ..quadraticBezierTo(
        size.width * .82,
        size.height * .32,
        size.width * .54,
        size.height * .4,
      )
      ..close();
    canvas.drawPath(secondLeaf, leaf);
    canvas.drawPath(secondLeaf, outline);

    final body = Path()
      ..moveTo(size.width * .22, size.height * .36)
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .27,
        size.width * .78,
        size.height * .38,
      )
      ..quadraticBezierTo(
        size.width * .8,
        size.height * .7,
        size.width * .5,
        size.height * .94,
      )
      ..quadraticBezierTo(
        size.width * .2,
        size.height * .7,
        size.width * .22,
        size.height * .36,
      )
      ..close();
    canvas.drawPath(body, root);
    canvas.drawPath(body, outline);
  }

  @override
  bool shouldRepaint(covariant _KabuMarkPainter oldDelegate) =>
      oldDelegate.leafColor != leafColor || oldDelegate.rootColor != rootColor;
}

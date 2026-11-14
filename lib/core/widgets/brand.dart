import 'package:flutter/material.dart';

const ink = Color(0xFF173E38);
const paper = Color(0xFFF8F8F2);
const mutedInk = Color(0xFF62736D);
const lime = Color(0xFFD9ED92);

class BrandMark extends StatelessWidget {
  final bool inverse;
  const BrandMark({super.key, this.inverse = false});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: inverse ? lime : ink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.home_repair_service_rounded,
          size: 20,
          color: inverse ? ink : lime,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'fixflow',
        style: TextStyle(
          fontSize: 25,
          letterSpacing: -1,
          fontWeight: FontWeight.w700,
          color: inverse ? Colors.white : ink,
        ),
      ),
    ],
  );
}

class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = mutedInk});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
      color: color,
    ),
  );
}

Color serviceTint(String category) => switch (category) {
  'cat-plumbing' => const Color(0xFFDFECE8),
  'cat-electrical' => const Color(0xFFF3E6C9),
  _ => const Color(0xFFE6E6F1),
};

IconData serviceIcon(String category) => switch (category) {
  'cat-plumbing' => Icons.water_drop_outlined,
  'cat-electrical' => Icons.bolt_rounded,
  _ => Icons.cleaning_services_outlined,
};

/// Original local vector artwork; no remote images or runtime downloads.
class ServiceArtwork extends StatelessWidget {
  final String categoryId;
  final bool room;
  const ServiceArtwork({
    super.key,
    this.categoryId = 'cat-cleaning',
    this.room = false,
  });
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ColoredBox(
      color: room ? const Color(0xFFECEEE0) : serviceTint(categoryId),
      child: CustomPaint(
        painter: _RoomPainter(categoryId, room),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _RoomPainter extends CustomPainter {
  final String category;
  final bool room;
  const _RoomPainter(this.category, this.room);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final scale = (size.width / 440 < size.height / 310
        ? size.width / 440
        : size.height / 310);
    canvas.scale(scale);
    canvas.translate(-220, -155);
    void rect(
      double x,
      double y,
      double w,
      double h,
      Color color, [
      double r = 0,
    ]) => canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      Paint()..color = color,
    );
    void line(Offset a, Offset b, Color color, [double width = 2]) =>
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = color
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round,
        );
    void circle(double x, double y, double r, Color color) =>
        canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
    const green = Color(0xFF3A6A57);
    const light = Color(0xFFF9F9EF);
    rect(224, 31, 132, 142, const Color(0xFFCBD8C6), 65);
    rect(232, 38, 116, 129, light, 58);
    rect(238, 44, 104, 117, const Color(0xFFDAE9E0), 52);
    circle(305, 79, 22, const Color(0xFFE8BD71));
    line(
      const Offset(290, 44),
      const Offset(290, 163),
      const Color(0xFFB7C8B9),
      4,
    );
    line(
      const Offset(238, 109),
      const Offset(342, 109),
      const Color(0xFFB7C8B9),
      4,
    );
    rect(220, 166, 140, 7, green, 3);
    canvas.drawOval(
      const Rect.fromLTWH(48, 248, 346, 34),
      Paint()..color = const Color(0xFFD4D9C7),
    );
    if (room || category == 'cat-cleaning') {
      rect(86, 147, 153, 87, green, 24);
      rect(75, 198, 174, 45, const Color(0xFF285443), 15);
      rect(92, 180, 144, 46, const Color(0xFF5E8969), 14);
      rect(107, 157, 47, 45, const Color(0xFFE6C088), 10);
      rect(164, 158, 51, 43, const Color(0xFFBBCD9D), 10);
      line(const Offset(92, 242), const Offset(88, 263), ink, 6);
      line(const Offset(231, 242), const Offset(235, 263), ink, 6);
      rect(270, 223, 78, 9, const Color(0xFFBB845F), 4);
      line(const Offset(280, 233), const Offset(276, 266), ink, 4);
      line(const Offset(336, 233), const Offset(341, 266), ink, 4);
      rect(296, 195, 24, 28, const Color(0xFFC78264), 7);
      line(const Offset(308, 196), const Offset(304, 174), green, 3);
      canvas.drawOval(
        const Rect.fromLTWH(288, 171, 19, 10),
        Paint()..color = green,
      );
      canvas.drawOval(
        const Rect.fromLTWH(305, 164, 17, 13),
        Paint()..color = green,
      );
    } else if (category == 'cat-plumbing') {
      rect(100, 180, 158, 78, green, 10);
      rect(90, 169, 178, 20, light, 9);
      line(
        const Offset(180, 195),
        const Offset(180, 247),
        const Color(0xFF719681),
      );
      circle(169, 211, 3, lime);
      circle(191, 211, 3, lime);
      rect(165, 131, 10, 39, const Color(0xFFBC855A), 4);
      rect(165, 130, 40, 10, const Color(0xFFBC855A), 4);
      rect(198, 133, 8, 17, const Color(0xFFBC855A), 4);
      circle(202, 160, 4, const Color(0xFF93BDB7));
      rect(111, 256, 8, 12, ink, 2);
      rect(241, 256, 8, 12, ink, 2);
    } else {
      line(const Offset(143, 25), const Offset(143, 100), ink, 3);
      final shade = Path()
        ..moveTo(143, 92)
        ..lineTo(98, 148)
        ..quadraticBezierTo(143, 166, 188, 148)
        ..close();
      canvas.drawPath(shade, Paint()..color = const Color(0xFFC58756));
      circle(143, 150, 9, const Color(0xFFFFF1BD));
      rect(90, 211, 166, 14, green, 5);
      rect(99, 225, 7, 42, ink, 2);
      rect(239, 225, 7, 42, ink, 2);
      rect(175, 179, 36, 32, const Color(0xFFE4D4AA), 5);
      rect(182, 174, 25, 7, const Color(0xFFB29A75), 2);
    }
    line(const Offset(365, 232), const Offset(365, 172), green, 4);
    canvas.drawOval(
      const Rect.fromLTWH(337, 176, 28, 13),
      Paint()..color = green,
    );
    canvas.drawOval(
      const Rect.fromLTWH(365, 160, 27, 15),
      Paint()..color = green,
    );
    canvas.drawOval(
      const Rect.fromLTWH(345, 145, 21, 28),
      Paint()..color = const Color(0xFF72956A),
    );
    rect(347, 222, 38, 43, const Color(0xFFC69476), 7);
    final star = Path()
      ..moveTo(62, 76)
      ..lineTo(66, 88)
      ..lineTo(78, 92)
      ..lineTo(66, 96)
      ..lineTo(62, 108)
      ..lineTo(58, 96)
      ..lineTo(46, 92)
      ..lineTo(58, 88)
      ..close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFBA8F4C));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoomPainter oldDelegate) =>
      oldDelegate.category != category || oldDelegate.room != room;
}

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// "FC" logo kutusu
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Text(
        'FC',
        style: TextStyle(
          color: AppColors.brandBlue,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

/// Mavi zemin üzerine ince ızgara deseni (giriş ekranı, ana sayfa üst alanı)
class GridPattern extends StatelessWidget {
  final Widget child;
  final Color color;
  const GridPattern({
    super.key,
    required this.child,
    this.color = AppColors.brandBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: CustomPaint(painter: _GridPainter(), child: child),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Uygulama açılırken gösterilen ekran
class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GridPattern(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandMark(size: 72),
              SizedBox(height: 18),
              Text(
                'Finans Cepte',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 28),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

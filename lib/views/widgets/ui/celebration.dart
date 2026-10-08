import 'dart:math';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Hedef tamamlanınca gösterilen kutlama penceresi (konfeti animasyonlu)
Future<void> showGoalCelebration(BuildContext context, String goalName) {
  return showDialog(
    context: context,
    builder: (ctx) => _CelebrationDialog(goalName: goalName),
  );
}

class _CelebrationDialog extends StatefulWidget {
  final String goalName;
  const _CelebrationDialog({required this.goalName});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();
  final _pieces = List.generate(40, (i) => _Piece(Random(i)));

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(_pieces, _anim.value),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.incomeSoft,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(Icons.emoji_events_outlined, color: c.income, size: 38),
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  'Tebrikler!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '"${widget.goalName}" hedefine ulaştın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textMuted),
                ),
                const SizedBox(height: AppSpace.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Harika!'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Piece {
  final double x, speed, size, spin, drift;
  final Color color;
  _Piece(Random r)
      : x = r.nextDouble(),
        speed = 0.6 + r.nextDouble() * 0.8,
        size = 5 + r.nextDouble() * 6,
        spin = r.nextDouble() * 6,
        drift = (r.nextDouble() - 0.5) * 0.2,
        color = const [
          Color(0xFF0B5CD5),
          Color(0xFF12805C),
          Color(0xFFCB5A17),
          Color(0xFFC0306A),
          Color(0xFFA86A00),
          Color(0xFF6A43C9),
        ][r.nextInt(6)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t;
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final y = (t * p.speed * 1.4 - 0.2) * size.height;
      if (y < -20 || y > size.height) continue;
      final x = (p.x + p.drift * t) * size.width;
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t * 6);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

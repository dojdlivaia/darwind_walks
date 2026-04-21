// lib/widgets/creature_blueprint.dart

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import '../models/jurassic.dart';

class CreatureBlueprint extends StatefulWidget {
  final JurassicNode node;
  final VoidCallback? onClose;

  const CreatureBlueprint({
    super.key,
    required this.node,
    this.onClose,
  });

  @override
  State<CreatureBlueprint> createState() => _CreatureBlueprintState();
}

class _CreatureBlueprintState extends State<CreatureBlueprint>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _filmLoadAnim;
  late Animation<double> _outlineGlowAnim;
  late Animation<double> _arrowsAnim;
  
  final GlobalKey _imageKey = GlobalKey();
  double _imageWidth = 0;
  double _imageHeight = 0;

  // 🎨 Цветовая палитра
  static const Color _bgDark = Color(0xFF061B14);
  static const Color _bgMedium = Color(0xFF2E3A05);
  static const Color _accent = Color(0xFF4B5E09);
  static const Color _textBright = Color(0xFFEEF8CC);

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _filmLoadAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _outlineGlowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    _arrowsAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateImageSize();
      _mainController.forward();
    });
  }

  void _updateImageSize() {
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _imageWidth = renderBox.size.width;
        _imageHeight = renderBox.size.height;
      });
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  // 🔹 Вспомогательный метод для безопасной прозрачности
  double _safeOpacity(double value) => value.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _bgDark,
                _bgMedium.withOpacity(0.9),
                _bgDark,
              ],
            ),
          ),
          child: Stack(
            children: [
              _buildFilmOverlay(),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        opacity: _safeOpacity(_filmLoadAnim.value),
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          widget.node.species.toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textBright.withOpacity(_safeOpacity(_filmLoadAnim.value)),
                            letterSpacing: 2,
                            fontFamily: 'Monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 280,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(
                                sigmaX: 1.5 * (1 - _safeOpacity(_filmLoadAnim.value)),
                                sigmaY: 1.5 * (1 - _safeOpacity(_filmLoadAnim.value)),
                              ),
                              child: Image.asset(
                                widget.node.imageUrl,
                                key: _imageKey,
                                fit: BoxFit.contain,
                                color: _textBright.withOpacity(
                                  _safeOpacity(0.3 + 0.4 * _filmLoadAnim.value),
                                ),
                                colorBlendMode: BlendMode.srcIn,
                              ),
                            ),
                            if (_imageWidth > 0)
                              CustomPaint(
                                size: Size(_imageWidth, _imageHeight),
                                painter: _GlowOutlinePainter(
                                  progress: _safeOpacity(_outlineGlowAnim.value),
                                  glowIntensity: _safeOpacity(_outlineGlowAnim.value),
                                  glowColor: _textBright,
                                ),
                              ),
                            if (_imageWidth > 0 && _arrowsAnim.value > 0)
                              CustomPaint(
                                size: Size(_imageWidth, _imageHeight),
                                painter: _BlueprintArrowsPainter(
                                  progress: _safeOpacity(_arrowsAnim.value),
                                  node: widget.node,
                                  imageWidth: _imageWidth,
                                  imageHeight: _imageHeight,
                                  textColor: _textBright,
                                  arrowColor: _textBright,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedOpacity(
                        opacity: _safeOpacity(_arrowsAnim.value),
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _accent.withOpacity(0.6),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatItem('Длина', widget.node.lengthText),
                              if (widget.node.heightM != null) ...[
                                const SizedBox(width: 16),
                                _buildStatItem('Высота', widget.node.heightText),
                              ],
                              const SizedBox(width: 16),
                              _buildStatItem('Вес', widget.node.weightText),
                              if (widget.node.wingspanM != null) ...[
                                const SizedBox(width: 16),
                                _buildStatItem('Размах', widget.node.wingspanText),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _safeOpacity(_filmLoadAnim.value),
                  duration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: widget.onClose ?? () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _textBright.withOpacity(0.7)),
                      ),
                      child: Icon(
                        Icons.close,
                        color: _textBright.withOpacity(0.9),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textBright,
            fontFamily: 'Monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            color: _textBright.withOpacity(0.7),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildFilmOverlay() {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _safeOpacity(_filmLoadAnim.value * 0.4),
        duration: const Duration(milliseconds: 500),
        child: CustomPaint(
          size: Size.infinite,
          painter: _FilmGrainPainter(
            progress: _safeOpacity(_filmLoadAnim.value),
            seed: widget.node.species.hashCode,
            textColor: _textBright,
          ),
        ),
      ),
    );
  }
}

// 🔆 Художник для светящейся обводки
class _GlowOutlinePainter extends CustomPainter {
  final double progress;
  final double glowIntensity;
  final Color glowColor;

  _GlowOutlinePainter({
    required this.progress,
    required this.glowIntensity,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.01) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.95;

    // 🔆 Внешнее свечение
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          glowColor.withOpacity((0.6 * glowIntensity).clamp(0.0, 1.0)),
          glowColor.withOpacity((0.2 * glowIntensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius * (1 + 0.15 * glowIntensity), glowPaint);

    // ✏️ Чёткая обводка
    final outlinePaint = Paint()
      ..color = glowColor.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + glowIntensity
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawOval(
      Rect.fromCircle(center: center, radius: radius * progress),
      outlinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowOutlinePainter old) =>
      old.progress != progress || old.glowIntensity != glowIntensity;
}

// 📐 Художник для анимированных выносок
class _BlueprintArrowsPainter extends CustomPainter {
  final double progress;
  final JurassicNode node;
  final double imageWidth;
  final double imageHeight;
  final Color textColor;
  final Color arrowColor;

  _BlueprintArrowsPainter({
    required this.progress,
    required this.node,
    required this.imageWidth,
    required this.imageHeight,
    required this.textColor,
    required this.arrowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.01) return;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    _drawDimensionArrow(
      canvas,
      start: Offset(size.width * 0.15, size.height + 8),
      end: Offset(size.width * 0.85, size.height + 8),
      label: '${node.lengthText} длина',
      progress: progress,
      delay: 0.0,
      textPainter: textPainter,
      vertical: false,
    );

    if (node.heightM != null && progress > 0.3) {
      _drawDimensionArrow(
        canvas,
        start: Offset(-8, size.height * 0.2),
        end: Offset(-8, size.height * 0.8),
        label: '${node.heightText} высота',
        progress: progress,
        delay: 0.2,
        textPainter: textPainter,
        vertical: true,
      );
    }

    if (node.wingspanM != null && progress > 0.5) {
      _drawDimensionArrow(
        canvas,
        start: Offset(size.width * 0.2, -20),
        end: Offset(size.width * 0.8, -20),
        label: '${node.wingspanText} размах',
        progress: progress,
        delay: 0.4,
        textPainter: textPainter,
        vertical: false,
      );
    }
  }

  void _drawDimensionArrow(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required String label,
    required double progress,
    required double delay,
    required TextPainter textPainter,
    required bool vertical,
  }) {
    final animProgress = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
    if (animProgress <= 0) return;

    final paint = Paint()
      ..color = arrowColor.withOpacity((0.9 * animProgress).clamp(0.0, 1.0))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final currentEnd = Offset.lerp(start, end, animProgress)!;
    canvas.drawLine(start, currentEnd, paint);

    _drawArrowhead(canvas, start, end, paint, animProgress, vertical: vertical);
    if (animProgress > 0.5) {
      _drawArrowhead(canvas, end, start, paint, animProgress, vertical: vertical);
    }

    if (animProgress > 0.7) {
      final mid = Offset.lerp(start, end, 0.5)!;
      final textOffset = vertical
          ? Offset(mid.dx - 45, mid.dy)
          : Offset(mid.dx, mid.dy - 18);

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: textColor.withOpacity(animProgress.clamp(0.0, 1.0)),
          fontSize: 10,
          fontFamily: 'Monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, textOffset);
    }
  }

  void _drawArrowhead(
    Canvas canvas,
    Offset base,
    Offset direction,
    Paint paint,
    double progress, {
    required bool vertical,
  }) {
    if (progress < 0.3) return;

    final arrowSize = 6 * progress;
    final angle = vertical ? -math.pi / 2 : 0;
    final dir = (direction - base);
    final dirAngle = math.atan2(dir.dy, dir.dx) + angle;

    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..lineTo(
        base.dx + math.cos(dirAngle - 0.5) * arrowSize,
        base.dy + math.sin(dirAngle - 0.5) * arrowSize,
      )
      ..moveTo(base.dx, base.dy)
      ..lineTo(
        base.dx + math.cos(dirAngle + 0.5) * arrowSize,
        base.dy + math.sin(dirAngle + 0.5) * arrowSize,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlueprintArrowsPainter old) =>
      old.progress != progress ||
      old.node != node ||
      old.imageWidth != imageWidth ||
      old.imageHeight != imageHeight;
}

// 🎞️ Художник для эффекта старой плёнки
class _FilmGrainPainter extends CustomPainter {
  final double progress;
  final int seed;
  final Color textColor;

  _FilmGrainPainter({
    required this.progress,
    required this.seed,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity((0.4 * progress).clamp(0.0, 1.0)),
          Colors.black.withOpacity((0.7 * progress).clamp(0.0, 1.0)),
        ],
        stops: const [0.4, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);

    if (progress > 0.1) {
      final grainPaint = Paint();
      for (var i = 0; i < 200 * progress; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final alpha = (random.nextDouble() * 0.15 * progress).clamp(0.0, 1.0);
        
        grainPaint.color = Colors.white.withOpacity(alpha);
        canvas.drawCircle(Offset(x, y), 0.8, grainPaint);
      }
    }

    if (progress < 1.0) {
      final scanlinePaint = Paint()
        ..color = Colors.black.withOpacity((0.1 * (1 - progress)).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (var y = 0.0; y < size.height; y += 4) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter old) =>
      old.progress != progress || old.seed != seed;
}
// lib/widgets/sprite_sheet_widget.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class SpriteSheetAnimation extends StatefulWidget {
  final String imagePath;
  final int columns;
  final int rows;
  final Duration totalDuration;
  final double scale; // масштаб относительно размера кадра

  const SpriteSheetAnimation({
    super.key,
    required this.imagePath,
    required this.columns,
    required this.rows,
    this.totalDuration = const Duration(seconds: 1),
    this.scale = 1.0,
  });

  @override
  State<SpriteSheetAnimation> createState() => _SpriteSheetAnimationState();
}

class _SpriteSheetAnimationState extends State<SpriteSheetAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.Image? _spriteImage;

  int get _frameCount => widget.columns * widget.rows;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.totalDuration,
    )..repeat();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load(widget.imagePath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    setState(() {
      _spriteImage = frame.image;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _spriteImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_spriteImage == null) {
      return const SizedBox.shrink();
    }

    // Реальный размер одного кадра в пикселях
    final frameWidth =
        _spriteImage!.width / widget.columns; // 1024 / 2 = 512 [file:2]
    final frameHeight =
        _spriteImage!.height / widget.rows; // 1536 / 5 ≈ 307.2 [file:2]

    // Оборачиваем в SizedBox по размеру кадра (с масштабом), чтобы ничего не растягивать
    return SizedBox(
      width: frameWidth * widget.scale,
      height: frameHeight * widget.scale,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final frameIndex =
              (_controller.value * _frameCount).floor() % _frameCount;
          return CustomPaint(
            painter: _SpritePainter(
              image: _spriteImage!,
              frameIndex: frameIndex,
              columns: widget.columns,
              rows: widget.rows,
            ),
          );
        },
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final int frameIndex;
  final int columns;
  final int rows;

  _SpritePainter({
    required this.image,
    required this.frameIndex,
    required this.columns,
    required this.rows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = image.width / columns;
    final frameHeight = image.height / rows;

    final col = frameIndex % columns;
    final row = frameIndex ~/ columns;

    final src = Rect.fromLTWH(
      col * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );

    // Просто рисуем кадр во всю доступную область без изменения пропорций.
    // Size у нас точно такой же, как кадр * scale, так что деформации не будет.
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) {
    return oldDelegate.frameIndex != frameIndex ||
        oldDelegate.image != image ||
        oldDelegate.columns != columns ||
        oldDelegate.rows != rows;
  }
}

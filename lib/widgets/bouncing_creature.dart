import 'dart:math' as math;
import 'package:flutter/material.dart';

class BouncingCreature extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;
  final bool showShadow;
  final double shadowOffset;

  const BouncingCreature({
    super.key,
    required this.child,
    this.amplitude = 12.0,
    this.duration = const Duration(seconds: 3),
    this.showShadow = true,
    this.shadowOffset = 24.0,
  });

  @override
  State<BouncingCreature> createState() => _BouncingCreatureState();
}

class _BouncingCreatureState extends State<BouncingCreature>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  
  // ✅ Реальное соотношение сторон загруженного изображения
  double? _imageAspectRatio;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    
    // ✅ Пытаемся извлечь размеры из Image.asset
    _extractImageSize();
  }

  void _extractImageSize() {
    if (widget.child is Image) {
      final image = widget.child as Image;
      final key = image.image;
      
      // Создаем временный ImageStream для получения размеров без отображения
      final stream = key.resolve(ImageConfiguration.empty);
      stream.addListener(
        ImageStreamListener((info, _) {
          if (mounted && info.image.width > 0) {
            setState(() {
              _imageAspectRatio = info.image.width / info.image.height;
            });
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        final rawSin = math.sin(t);
        // normalizedHeight: 0.0 (на полу) -> 1.0 (в пике)
        final normalizedHeight = (rawSin + 1) / 2;

        // Параметры тени реагируют на высоту прыжка
        final shadowScaleY = 0.12; // Фиксированная плоскость
        final shadowOpacity = 0.5 - (normalizedHeight * 0.35);
        final shadowBlur = 8.0 + (normalizedHeight * 24.0);
        
        // ✅ Масштаб по X зависит от высоты: когда высоко - тень уже
        // Но базовая ширина берется от РЕАЛЬНОГО размера картинки (ниже)
        final shadowScaleXAnim = 1.0 - (normalizedHeight * 0.3);

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;

            // Размеры контейнера для картинки
            final containerWidth = maxWidth * 0.9;
            final containerHeight = containerWidth * 0.85;

            // ✅ ВЫЧИСЛЕНИЕ РЕАЛЬНОЙ ШИРИНЫ КАРТИНКИ
            // Если aspectRatio известен, считаем точно. Иначе fallback на containerWidth
            double actualImageWidth = containerWidth;
            
            if (_imageAspectRatio != null) {
              final imgAR = _imageAspectRatio!;
              final containerAR = containerWidth / containerHeight;
              
              if (imgAR > containerAR) {
                // Горизонтальная картинка (крокодил): упирается в ширину
                actualImageWidth = containerWidth;
              } else {
                // Вертикальная картинка (человек): упирается в высоту
                actualImageWidth = containerHeight * imgAR;
              }
            }

            // Ширина тени = реальная ширина картинки * анимационное сжатие
            final shadowWidth = actualImageWidth * shadowScaleXAnim;

            return Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: containerWidth,
                height: containerHeight + widget.amplitude * 2 + widget.shadowOffset,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. ТЕНЬ — НЕПОДВИЖНА, ширина = реальной ширине спрайта
                    if (widget.showShadow)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Transform.scale(
                            scaleX: 2.3, // Масштаб уже учтен в shadowWidth
                            scaleY: shadowScaleY,
                            child: Container(
                              width: shadowWidth,
                              height: shadowWidth * 0.3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:
                                      shadowOpacity.clamp(0.0, 1.0),
                                    ),
                                    blurRadius: shadowBlur,
                                    spreadRadius: -shadowBlur * 0.2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 2. КАРТИНКА — прыгает, размер контейнера фиксирован
                    // FittedBox внутри сам масштабирует картинку по BoxFit.contain
                    Positioned(
                      bottom: widget.shadowOffset + (normalizedHeight * widget.amplitude * 2),
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        width: containerWidth,
                        height: containerHeight,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: child!,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: widget.child,
    );
  }
}
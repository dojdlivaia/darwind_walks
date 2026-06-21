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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
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
        // dy: отрицательное значение = вверх (стандартная система координат для прыжка)
        // Но в Flutter Y растёт вниз, поэтому для прыжка ВВЕРХ нужно вычитать.
        // sin(t) даёт -1..1. Умножаем на -amplitude чтобы -1 было внизу, +1 вверху? 
        // Нет, проще: пусть dy = -sin(t) * amplitude. Тогда при t=pi/2 dy=-amp (вверх).
        final dy = -math.sin(t) * widget.amplitude; 
        
        // normalizedHeight: 0.0 (на полу) -> 1.0 (в пике прыжка)
        // Когда sin(t)=1 (пик), dy = -amplitude. normalizedHeight должен быть 1.
        // Когда sin(t)=-1 (низ), dy = +amplitude... Стоп.
        // Давайте упростим: sin(t) колеблется -1..1.
        // Пусть "пол" это sin(t) = -1. "Пик" это sin(t) = 1.
        final rawSin = math.sin(t);
        final normalizedHeight = (rawSin + 1) / 2; // 0 (низ) -> 1 (верх)

        // ✅ ПАРАМЕТРЫ ТЕНИ (зависят от высоты, но позиция НЕ зависит)
        // Низко (0): большая, тёмная, чёткая
        // Высоко (1): маленькая, прозрачная, размытая
        final shadowScale = 1.0 - (normalizedHeight * 0.4);   // 1.0 -> 0.6
        final shadowOpacity = 0.5 - (normalizedHeight * 0.35); // 0.5 -> 0.15
        final shadowBlur = 8.0 + (normalizedHeight * 24.0);    // 8 -> 32

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;

            final creatureWidth = maxWidth * 0.9;
            final creatureHeight = creatureWidth * 0.85;

            // ✅ КЛЮЧЕВОЕ ИЗМЕНЕНИЕ:
            // Весь контейнер прижат к низу родителя через Align.
            // Внутри Stack: тень НЕПОДВИЖНА на дне, картинка прыгает ОТ дна.
            return Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: creatureWidth,
                // Высота = размер зверя + запас на прыжок + зона тени
                height: creatureHeight + widget.amplitude * 2 + widget.shadowOffset,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. ТЕНЬ — НЕПОДВИЖНА, всегда на дне Stack
                    // Рисуется ПЕРВОЙ = ЗА картинкой
                    if (widget.showShadow)
                      Positioned(
                        bottom: 0, // ✅ Всегда на самом дне!
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Transform.scale(
                            scaleX: shadowScale,
                            scaleY: 0.12, // Плоский эллипс
                            child: Container(
                              width: creatureWidth,
                              height: creatureWidth * 0.3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
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

                    // 2. КАРТИНКА — прыгает ОТ дна Stack
                    // Рисуется ВТОРОЙ = ПЕРЕД тенью
                    // bottom = shadowOffset + смещение прыжка
                    // Когда normalizedHeight=0 (низ): bottom = shadowOffset (стоит над тенью)
                    // Когда normalizedHeight=1 (верх): bottom = shadowOffset + amplitude*2
                    Positioned(
                      bottom: widget.shadowOffset + (normalizedHeight * widget.amplitude * 2),
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        width: creatureWidth,
                        height: creatureHeight,
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
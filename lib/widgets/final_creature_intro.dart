import 'package:flutter/material.dart';

/// Однократная анимация появления:
/// кит выезжает снизу, чуть увеличивается и проявляется по альфе.
class FinalCreatureIntro extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool play; // если false — сразу показываем без анимации

  const FinalCreatureIntro({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
    this.play = true,
  });

  @override
  State<FinalCreatureIntro> createState() => _FinalCreatureIntroState();
}

class _FinalCreatureIntroState extends State<FinalCreatureIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.3), // немного снизу
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scale = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    if (widget.play) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant FinalCreatureIntro oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _controller
        ..value = 0
        ..forward();
    } else if (!widget.play && oldWidget.play) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

// lib/widgets/mammal_timeline_point.dart

import 'package:flutter/material.dart';
import '../models/mammal_node.dart';

/// Точка на таймлайне — отпечаток лапы с состоянием
class MammalTimelinePoint extends StatelessWidget {
  final MammalNode node;
  final bool isUnlocked;
  final bool isCurrent;
  final VoidCallback? onTap;

  const MammalTimelinePoint({
    super.key,
    required this.node,
    required this.isUnlocked,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFuture = !isUnlocked && !isCurrent;

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🔹 Основная иконка — отпечаток лапы
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCurrent ? 56 : 44,
            height: isCurrent ? 56 : 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getColor(isUnlocked, isCurrent),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: _getColor(isUnlocked, isCurrent).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.pets,
              color: Colors.white.withOpacity(isFuture ? 0.3 : 1.0),
              size: isCurrent ? 28 : 22,
            ),
          ),

          // 🔹 Пульсация для текущего узла
          if (isCurrent) _buildPulseAnimation(),

          // 🔹 Замок для заблокированных
          if (isFuture) _buildLockOverlay(),
        ],
      ),
    );
  }

  // ============================================================
  // 🔹 Вспомогательные методы
  // ============================================================

  Color _getColor(bool unlocked, bool current) {
    if (current) {
      return const Color(0xFF4B5E09); // акцентный зелёный
    }
    if (unlocked) {
      return const Color(0xFF2E5A2E); // пройденный — тёмно-зелёный
    }
    return const Color(0xFF2A2A2A); // заблокированный — серый
  }

  Widget _buildPulseAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4B5E09).withOpacity(0.6),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockOverlay() {
    return const Icon(
      Icons.lock_outline,
      color: Colors.white38,
      size: 14,
    );
  }
}
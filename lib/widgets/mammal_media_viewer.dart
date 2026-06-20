// lib/widgets/mammal_media_viewer.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mammal_node.dart';

/// Полноэкранный просмотрщик медиа для узла млекопитающего
class MammalMediaViewer extends StatefulWidget {
  final MammalNode node;
  final VoidCallback? onClose;

  const MammalMediaViewer({
    super.key,
    required this.node,
    this.onClose,
  });

  @override
  State<MammalMediaViewer> createState() => _MammalMediaViewerState();
}

class _MammalMediaViewerState extends State<MammalMediaViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentImageIndex = 0;
  bool _isGalleryMode = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MediaItem> get _allMedia {
    final list = <MediaItem>[];
    list.add(widget.node.media.primary);
    list.addAll(widget.node.media.gallery);
    return list;
  }

  MediaItem get _currentMedia => _allMedia[_currentImageIndex];

  bool get _hasGallery => widget.node.media.gallery.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 🔹 Фон с затемнением
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF061B14).withOpacity(0.95),
                  const Color(0xFF0A2A1E).withOpacity(0.95),
                  const Color(0xFF000000).withOpacity(0.98),
                ],
              ),
            ),
          ),

          // 🔹 Основной контент с анимацией
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Column(
                  children: [
                    // 🔹 Верхняя панель
                    _buildTopBar(),

                    // 🔹 Изображение
                    Expanded(
                      child: _buildImageArea(),
                    ),

                    // 🔹 Нижняя панель с информацией
                    _buildBottomPanel(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔹 Верхняя панель
  // ============================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Кнопка закрытия
          GestureDetector(
            onTap: () {
              _controller.reverse().then((_) {
                widget.onClose?.call();
                Navigator.pop(context);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEEF8CC).withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFFEEF8CC),
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Название вида
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.node.species,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEEF8CC),
                    letterSpacing: 0.5,
                    fontFamily: 'Monospace',
                  ),
                ),
                Text(
                  widget.node.formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFEEF8CC).withOpacity(0.6),
                    fontFamily: 'Monospace',
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Индикатор количества изображений
          if (_allMedia.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4B5E09).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4B5E09).withOpacity(0.3),
                ),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${_allMedia.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEEF8CC),
                  fontFamily: 'Monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔹 Область изображения
  // ============================================================

  Widget _buildImageArea() {
    return GestureDetector(
      onTap: _isGalleryMode ? null : _toggleFullscreen,
      onDoubleTap: _hasGallery ? _nextImage : null,
      onHorizontalDragEnd: _hasGallery ? _onHorizontalDragEnd : null,
      child: Stack(
        children: [
          // Основное изображение
          Center(
            child: Hero(
              tag: 'mammal_image_${widget.node.species}_$_currentImageIndex',
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _currentMedia.url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF1A2F22),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: const Color(0xFFEEF8CC).withOpacity(0.3),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Изображение не найдено',
                                style: TextStyle(
                                  color: const Color(0xFFEEF8CC).withOpacity(0.3),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Левая и правая стрелки навигации (если галерея)
          if (_hasGallery) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: _buildNavArrow(
                icon: Icons.chevron_left,
                onTap: _previousImage,
                enabled: _currentImageIndex > 0,
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: _buildNavArrow(
                icon: Icons.chevron_right,
                onTap: _nextImage,
                enabled: _currentImageIndex < _allMedia.length - 1,
              ),
            ),
          ],

          // 🔹 Тип изображения (badge)
          Positioned(
            top: 24,
            right: 24,
            child: _buildTypeBadge(_currentMedia.type),
          ),
        ],
      ),
    );
  }

  Widget _buildNavArrow({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return Center(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          opacity: enabled ? 0.7 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.5),
              border: Border.all(
                color: const Color(0xFFEEF8CC).withOpacity(0.2),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFEEF8CC),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final labels = {
      'ct_scan': 'КТ-томография',
      'fossil': 'Окаменелость',
      'microscope': 'Микрофотография',
      'reconstruction': 'Реконструкция',
      'xray': 'Рентген',
      'museum': 'Музейный экспонат',
      'field': 'Место раскопок',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4B5E09).withOpacity(0.5),
        ),
      ),
      child: Text(
        labels[type] ?? type,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFFEEF8CC),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          fontFamily: 'Monospace',
        ),
      ),
    );
  }

  // ============================================================
  // 🔹 Нижняя панель с информацией
  // ============================================================

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Подпись к изображению
          _buildCaption(),

          const SizedBox(height: 12),

          // 🔹 Параметры (размеры, вес)
          _buildStats(),

          const SizedBox(height: 12),

          // 🔹 Интересный факт
          _buildFunFact(),

          const SizedBox(height: 16),

          // 🔹 Кнопка "Показать полное описание" (аккордеон)
          _buildExpandButton(),
        ],
      ),
    );
  }

  Widget _buildCaption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentMedia.caption,
          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
            color: Color(0xFFEEF8CC),
            fontFamily: 'Monospace',
          ),
        ),
        if (_currentMedia.credit.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '📷 ${_currentMedia.credit}',
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFFEEF8CC).withOpacity(0.5),
              fontFamily: 'Monospace',
            ),
          ),
        ],
        if (_currentMedia.license != null) ...[
          const SizedBox(height: 2),
          Text(
            '🔓 ${_currentMedia.license}',
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFFEEF8CC).withOpacity(0.3),
              fontFamily: 'Monospace',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStats() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildStatChip('📏 Длина', widget.node.lengthText),
        if (widget.node.heightM != null)
          _buildStatChip('📐 Высота', widget.node.heightText),
        _buildStatChip('⚖️ Вес', widget.node.weightText),
        if (widget.node.wingspanM != null)
          _buildStatChip('🦅 Размах', widget.node.wingspanText),
        _buildStatChip('⏳ Возраст', widget.node.formattedTime),
      ],
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4B5E09).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4B5E09).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFFEEF8CC).withOpacity(0.5),
              fontFamily: 'Monospace',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEEF8CC),
              fontFamily: 'Monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunFact() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4B5E09).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4B5E09).withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 ',
            style: TextStyle(fontSize: 16),
          ),
          Expanded(
            child: Text(
              widget.node.funfact,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFFEEF8CC),
                fontFamily: 'Monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandButton() {
    return GestureDetector(
      onTap: _toggleFullDescription,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4B5E09).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF4B5E09).withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isGalleryMode ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFFEEF8CC).withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isGalleryMode ? 'Скрыть описание' : 'Показать полное описание',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFEEF8CC).withOpacity(0.7),
                fontFamily: 'Monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔹 Логика навигации
  // ============================================================

  void _nextImage() {
    if (_currentImageIndex < _allMedia.length - 1) {
      setState(() {
        _currentImageIndex++;
      });
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    if (details.primaryVelocity! < -100) {
      _nextImage();
    } else if (details.primaryVelocity! > 100) {
      _previousImage();
    }
  }

  void _toggleFullscreen() {
    // В полноэкранный режим — можно использовать SystemChrome
    // или просто скрыть панели
  }

  void _toggleFullDescription() {
    setState(() {
      _isGalleryMode = !_isGalleryMode;
    });
  }

  // ============================================================
  // 🔹 Полное описание (аккордеон)
  // ============================================================

  Widget _buildFullDescription() {
    if (!_isGalleryMode) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2F22).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4B5E09).withOpacity(0.2),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📖 ПОЛНОЕ ОПИСАНИЕ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5E09),
                letterSpacing: 1,
                fontFamily: 'Monospace',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.node.text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.8,
                color: Color(0xFFEEF8CC),
                fontFamily: 'Monospace',
              ),
            ),
            const SizedBox(height: 12),

            // 🔹 Галерея миниатюр (если есть дополнительные изображения)
            if (widget.node.media.gallery.isNotEmpty) ...[
              const Text(
                '🖼️ ДРУГИЕ ИЗОБРАЖЕНИЯ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B5E09),
                  letterSpacing: 1,
                  fontFamily: 'Monospace',
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.node.media.gallery.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = widget.node.media.gallery[index];
                    final isActive = index + 1 == _currentImageIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentImageIndex = index + 1;
                        });
                      },
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF4B5E09)
                                : const Color(0xFF4B5E09).withOpacity(0.2),
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            item.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1A2F22),
                              child: const Icon(
                                Icons.image,
                                color: Color(0xFFEEF8CC),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
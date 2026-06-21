// lib/widgets/mammal_media_viewer.dart

import 'package:flutter/material.dart';
import '../models/mammal_node.dart';

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
  bool _isDescriptionExpanded = false;

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF061B14).withValues(alpha:0.95),
              const Color(0xFF0A2A1E).withValues(alpha:0.95),
              const Color(0xFF000000).withValues(alpha:0.98),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  // Изображение с фиксированной высотой
                  Expanded(
                    flex: 4,
                    child: _buildImageArea(),
                  ),
                  // Нижняя панель с прокруткой
                  Expanded(
                    flex: _isDescriptionExpanded ? 5 : 3,
                    child: _buildBottomPanel(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
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
                  color: const Color(0xFFEEF8CC).withValues(alpha:0.3),
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
                  ),
                ),
                Text(
                  widget.node.formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFEEF8CC).withValues(alpha:0.6),
                  ),
                ),
              ],
            ),
          ),
          if (_allMedia.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4B5E09).withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4B5E09).withValues(alpha:0.3),
                ),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${_allMedia.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEEF8CC),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return GestureDetector(
      onTap: _toggleFullscreen,
      onDoubleTap: _hasGallery ? _nextImage : null,
      onHorizontalDragEnd: _hasGallery ? _onHorizontalDragEnd : null,
      child: Stack(
        children: [
          Center(
            child: Hero(
              tag: 'mammal_image_${widget.node.species}_$_currentImageIndex',
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.5),
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
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Color(0xFFEEF8CC),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (_hasGallery) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _currentImageIndex > 0 ? _previousImage : null,
                  child: AnimatedOpacity(
                    opacity: _currentImageIndex > 0 ? 0.7 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha:0.5),
                        border: Border.all(
                          color: const Color(0xFFEEF8CC).withValues(alpha:0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFFEEF8CC),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _currentImageIndex < _allMedia.length - 1
                      ? _nextImage
                      : null,
                  child: AnimatedOpacity(
                    opacity: _currentImageIndex < _allMedia.length - 1
                        ? 0.7
                        : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha:0.5),
                        border: Border.all(
                          color: const Color(0xFFEEF8CC).withValues(alpha:0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFFEEF8CC),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          Positioned(
            top: 24,
            right: 24,
            child: _buildTypeBadge(_currentMedia.type),
          ),
        ],
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
        color: Colors.black.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4B5E09).withValues(alpha:0.5),
        ),
      ),
      child: Text(
        labels[type] ?? type,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFFEEF8CC),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha:0.6),
            Colors.black.withValues(alpha:0.85),
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCaption(),
            const SizedBox(height: 10),
            _buildStats(),
            const SizedBox(height: 10),
            _buildFunFact(),
            const SizedBox(height: 10),
            _buildExpandButton(),
            if (_isDescriptionExpanded) ...[
              const SizedBox(height: 10),
              _buildFullDescription(),
            ],
          ],
        ),
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
            height: 1.5,
            color: Color(0xFFEEF8CC),
          ),
        ),
        if (_currentMedia.credit.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '📷 ${_currentMedia.credit}',
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFFEEF8CC).withValues(alpha:0.5),
            ),
          ),
        ],
        if (_currentMedia.license != null) ...[
          const SizedBox(height: 2),
          Text(
            '🔓 ${_currentMedia.license}',
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFFEEF8CC).withValues(alpha:0.3),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStats() {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _buildStatChip('📏', widget.node.lengthText),
        if (widget.node.heightM != null)
          _buildStatChip('📐', widget.node.heightText),
        _buildStatChip('⚖️', widget.node.weightText),
        if (widget.node.wingspanM != null)
          _buildStatChip('🦅', widget.node.wingspanText),
        _buildStatChip('⏳', widget.node.formattedTime),
      ],
    );
  }

  Widget _buildStatChip(String icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4B5E09).withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4B5E09).withValues(alpha:0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEEF8CC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunFact() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF4B5E09).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4B5E09).withValues(alpha:0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 ',
            style: TextStyle(fontSize: 14),
          ),
          Expanded(
            child: Text(
              widget.node.funfact,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFFEEF8CC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandButton() {
    return GestureDetector(
      onTap: _toggleDescription,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF4B5E09).withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF4B5E09).withValues(alpha:0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isDescriptionExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFFEEF8CC).withValues(alpha:0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isDescriptionExpanded ? 'Скрыть описание' : 'Показать полное описание',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFEEF8CC).withValues(alpha:0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullDescription() {
    final description = widget.node.text;
    
    if (description.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2F22).withValues(alpha:0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF4B5E09).withValues(alpha:0.2),
          ),
        ),
        child: const Center(
          child: Text(
            'Нет дополнительного описания',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFEEF8CC),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2F22).withValues(alpha:0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4B5E09).withValues(alpha:0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📖 ПОЛНОЕ ОПИСАНИЕ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5E09),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFFEEF8CC),
            ),
          ),
          if (widget.node.media.gallery.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              '🖼️ ДРУГИЕ ИЗОБРАЖЕНИЯ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5E09),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.node.media.gallery.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF4B5E09)
                              : const Color(0xFF4B5E09).withValues(alpha:0.2),
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          item.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
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
    );
  }

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

  void _toggleFullscreen() {}

  void _toggleDescription() {
    setState(() {
      _isDescriptionExpanded = !_isDescriptionExpanded;
    });
  }
}
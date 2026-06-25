import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/features/home/data/models/home_models.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Offer> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with TickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentIndex;
  late AnimationController _progressController;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initAnimationController();
  }

  void _initAnimationController() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _progressController.addListener(() {
      setState(() {});
    });
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });
    _progressController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _progressController.reset();
    _progressController.forward();
  }

  void _handleTap(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;
    if (tapX < screenWidth * 0.3) {
      _prevStory();
    } else {
      _nextStory();
    }
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset += details.delta.dy;
      });
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset > 100.0 || details.velocity.pixelsPerSecond.dy > 300.0) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  void _handleLinkTapped(String? link) {
    if (link == null || link.isEmpty) return;

    final uri = Uri.parse(link);
    final pathSegments = uri.pathSegments;

    String? productSlug;
    for (int i = 0; i < pathSegments.length - 1; i++) {
      if (pathSegments[i] == 'products') {
        productSlug = pathSegments[i + 1];
        break;
      }
    }

    if (productSlug != null) {
      context.push('/products/$productSlug');
      Navigator.of(context).pop();
    } else {
      if (link.startsWith('/')) {
        context.push(link);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: _handleVerticalDragUpdate,
          onVerticalDragEnd: _handleVerticalDragEnd,
          child: Transform.translate(
            offset: Offset(0.0, _dragOffset),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_dragOffset > 0 ? 16 : 0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // PageView for swiping
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.stories.length,
                    onPageChanged: _onPageChanged,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final s = widget.stories[index];
                      return _buildStoryItem(s);
                    },
                  ),

                  // Dark gradient overlay at the bottom so text is readable
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 280,
                    child: IgnorePointer(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black45,
                              Colors.black87,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // GestureDetector for Tap Navigation (transparent layer behind details but over image)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => _progressController.stop(),
                      onTapCancel: () => _progressController.forward(),
                      onTapUp: (details) {
                        _progressController.forward();
                        _handleTap(details);
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // Progress Bars at top
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: Row(
                      children: List.generate(widget.stories.length, (i) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.white30,
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                double widthFactor = 0.0;
                                if (i < _currentIndex) {
                                  widthFactor = 1.0;
                                } else if (i == _currentIndex) {
                                  widthFactor = _progressController.value;
                                }
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: constraints.maxWidth * widthFactor,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Close button
                  Positioned(
                    top: 20,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Info overlay & Link at bottom
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          story.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              )
                            ],
                          ),
                        ),
                        if (story.description != null && story.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            story.description!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                          ),
                        ],
                        if (story.link != null && story.link!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => _handleLinkTapped(story.link),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  story.buttonText ?? 'Shop Now',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryItem(Offer story) {
    if (story.image != null && story.image!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: story.image!,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => _storyBackground(story),
      );
    }
    return _storyBackground(story);
  }

  Widget _storyBackground(Offer story) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            story.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

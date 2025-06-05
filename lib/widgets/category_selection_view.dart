import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../providers/timeline_provider.dart';

class CategorySelectionView extends StatefulWidget {
  const CategorySelectionView({super.key});

  @override
  State<CategorySelectionView> createState() => _CategorySelectionViewState();
}

class _CategorySelectionViewState extends State<CategorySelectionView>
    with TickerProviderStateMixin {
  String? _selectedCategory1;
  String? _selectedCategory2;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _particlesController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Slower animation for particles
    _particlesController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _ = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Consumer<TimelineProvider>(
      builder: (context, provider, child) {
        final categories = _getAvailableCategories(provider);

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E27),
          body: Stack(
            children: [
              // Animated background
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.5),
                    radius: 2,
                    colors: [
                      const Color(0xFF1A1F3A),
                      const Color(0xFF0A0E27),
                      const Color(0xFF050714),
                    ],
                  ),
                ),
              ),

              // Animated particles background
              CustomPaint(
                size: MediaQuery.of(context).size,
                painter: ParticlesPainter(animation: _particlesController),
              ),

              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Content area
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: isMobile ? 16.0 : 20.0,
                            right: isMobile ? 16.0 : 20.0,
                            top:
                                MediaQuery.of(context).padding.top +
                                (isMobile ? 16 : 20),
                            bottom: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header (smaller on mobile)
                              _buildHeader(context, isMobile),
                              SizedBox(height: isMobile ? 24 : 40),

                              // Category Selection
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  bool isNarrowScreen =
                                      constraints.maxWidth < 700;

                                  if (isNarrowScreen) {
                                    return Column(
                                      children: [
                                        _buildCategorySelector(
                                          context,
                                          'First Timeline',
                                          _selectedCategory1,
                                          categories,
                                          (category) => setState(
                                            () => _selectedCategory1 = category,
                                          ),
                                          Colors.cyanAccent,
                                          Icons.timeline,
                                          isNarrowScreen,
                                          true,
                                          isMobile,
                                        ),
                                        SizedBox(height: isMobile ? 20 : 30),
                                        _buildVsIndicator(context, isMobile),
                                        SizedBox(height: isMobile ? 20 : 30),
                                        _buildCategorySelector(
                                          context,
                                          'Second Timeline',
                                          _selectedCategory2,
                                          categories,
                                          (category) => setState(
                                            () => _selectedCategory2 = category,
                                          ),
                                          Colors.purpleAccent,
                                          Icons.compare_arrows,
                                          isNarrowScreen,
                                          false,
                                          isMobile,
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Flexible(
                                          child: _buildCategorySelector(
                                            context,
                                            'First Timeline',
                                            _selectedCategory1,
                                            categories,
                                            (category) => setState(
                                              () =>
                                                  _selectedCategory1 = category,
                                            ),
                                            Colors.cyanAccent,
                                            Icons.timeline,
                                            isNarrowScreen,
                                            true,
                                            isMobile,
                                          ),
                                        ),
                                        const SizedBox(width: 30),
                                        _buildVsIndicator(context, isMobile),
                                        const SizedBox(width: 30),
                                        Flexible(
                                          child: _buildCategorySelector(
                                            context,
                                            'Second Timeline',
                                            _selectedCategory2,
                                            categories,
                                            (category) => setState(
                                              () =>
                                                  _selectedCategory2 = category,
                                            ),
                                            Colors.purpleAccent,
                                            Icons.compare_arrows,
                                            isNarrowScreen,
                                            false,
                                            isMobile,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                              // Add extra padding at bottom to ensure content is above button
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Compare button - full width on mobile
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0A0E27),
                            const Color(0xFF0A0E27),
                          ],
                          stops: [0.0, 0.3, 1.0],
                        ),
                      ),
                      padding: EdgeInsets.only(
                        left: isMobile ? 16 : 20,
                        right: isMobile ? 16 : 20,
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                        top: 16,
                      ),
                      child: _buildCompareButton(context, provider, isMobile),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      children: [
        // Animated logo (smaller on mobile)
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: isMobile ? 80 : 120,
                height: isMobile ? 80 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.cyanAccent.withOpacity(0.3),
                      Colors.purpleAccent.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.timeline,
                    size: isMobile ? 40 : 60,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: isMobile ? 20 : 30),

        // Title with glow effect (smaller on mobile)
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.cyanAccent, Colors.purpleAccent],
          ).createShader(bounds),
          child: Text(
            'ChronoHistory',
            style: TextStyle(
              fontSize: isMobile ? 28 : 40,
              fontWeight: FontWeight.w200,
              letterSpacing: isMobile ? 4 : 6,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),

        Text(
          'Timeline Comparison Engine',
          style: TextStyle(
            fontSize: isMobile ? 14 : 18,
            fontWeight: FontWeight.w300,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: isMobile ? 1 : 2,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(
            'Select two categories to explore their parallel histories',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: isMobile ? 12 : 14,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
    String title,
    String? selectedCategory,
    List<String> categories,
    ValueChanged<String> onSelected,
    Color accentColor,
    IconData icon,
    bool isNarrowScreen,
    bool isFirst,
    bool isMobile,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: isNarrowScreen && selectedCategory == null
                ? (isMobile ? 400 : 500)
                : double.infinity,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.1),
                accentColor.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: selectedCategory != null
                  ? accentColor.withOpacity(0.5)
                  : accentColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.3),
                            accentColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: accentColor,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w300,
                              color: accentColor,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            isFirst
                                ? 'Primary Timeline'
                                : 'Comparison Timeline',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 16 : 24),

                // Selected category or grid
                if (selectedCategory != null) ...[
                  _buildSelectedCategoryDisplay(
                    context,
                    selectedCategory,
                    accentColor,
                    () => setState(() {
                      if (isFirst) {
                        _selectedCategory1 = null;
                      } else {
                        _selectedCategory2 = null;
                      }
                    }),
                    isMobile,
                  ),
                ] else ...[
                  _buildCategoryGrid(
                    context,
                    categories,
                    accentColor,
                    isFirst,
                    onSelected,
                    isMobile,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCategoryDisplay(
    BuildContext context,
    String category,
    Color accentColor,
    VoidCallback onClear,
    bool isMobile,
  ) {
    return Consumer<TimelineProvider>(
      builder: (context, provider, child) {
        final events = provider.eventsByCategory[category] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected category card
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.2),
                    accentColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: accentColor,
                    size: isMobile ? 28 : 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${events.length} events',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClear,
                    icon: Icon(Icons.close, color: accentColor),
                    style: IconButton.styleFrom(
                      backgroundColor: accentColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Timeline preview
            Text(
              'Timeline Preview',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w300,
                color: accentColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),

            // Preview events (show only 2 on mobile to save space)
            ...events
                .take(isMobile ? 2 : 3)
                .map(
                  (event) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: isMobile ? 32 : 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                accentColor.withOpacity(0.8),
                                accentColor.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                  fontSize: isMobile ? 13 : 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${event.startDate.year}',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: isMobile ? 11 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            if (events.length > (isMobile ? 2 : 3))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${events.length - (isMobile ? 2 : 3)} more events',
                  style: TextStyle(
                    color: accentColor.withOpacity(0.7),
                    fontSize: isMobile ? 11 : 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    List<String> categories,
    Color accentColor,
    bool isFirst,
    ValueChanged<String> onSelected,
    bool isMobile,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 250 ? 1 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: crossAxisCount == 1
                ? 3.5
                : (isMobile ? 1.8 : 1.5),
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isDisabled =
                (isFirst && category == _selectedCategory2) ||
                (!isFirst && category == _selectedCategory1);

            return _buildCategoryCard(
              context,
              category,
              accentColor,
              isDisabled,
              () => onSelected(category),
              isMobile,
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String category,
    Color accentColor,
    bool isDisabled,
    VoidCallback onTap,
    bool isMobile,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDisabled
                  ? [
                      Colors.grey.withOpacity(0.1),
                      Colors.grey.withOpacity(0.05),
                    ]
                  : [
                      accentColor.withOpacity(0.1),
                      accentColor.withOpacity(0.05),
                    ],
            ),
            border: Border.all(
              color: isDisabled
                  ? Colors.grey.withOpacity(0.2)
                  : accentColor.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Stack(
            children: [
              if (!isDisabled)
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: isDisabled
                          ? Colors.grey.withOpacity(0.5)
                          : accentColor,
                      size: isMobile ? 20 : 24,
                    ),
                    SizedBox(height: isMobile ? 4 : 8),
                    Text(
                      category,
                      style: TextStyle(
                        color: isDisabled
                            ? Colors.grey.withOpacity(0.5)
                            : Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w300,
                        fontSize: isMobile ? 11 : 12,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVsIndicator(BuildContext context, bool isMobile) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: isMobile ? 60 : 80,
            height: isMobile ? 60 : 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.cyanAccent.withOpacity(0.3),
                  Colors.purpleAccent.withOpacity(0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(5, 0),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'VS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w200,
                  fontSize: isMobile ? 20 : 24,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompareButton(
    BuildContext context,
    TimelineProvider provider,
    bool isMobile,
  ) {
    final canCompare =
        _selectedCategory1 != null &&
        _selectedCategory2 != null &&
        _selectedCategory1 != _selectedCategory2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canCompare
              ? () {
                  provider.setComparisonCategories(
                    _selectedCategory1!,
                    _selectedCategory2!,
                  );
                  provider.setCurrentView('chrono_comparison');
                }
              : null,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: double.infinity, // Full width
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 40,
              vertical: isMobile ? 14 : 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: canCompare
                    ? [Colors.cyanAccent, Colors.purpleAccent]
                    : [
                        Colors.grey.withOpacity(0.3),
                        Colors.grey.withOpacity(0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: canCompare
                  ? [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(-5, 5),
                      ),
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(5, 5),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.compare_arrows,
                  color: canCompare
                      ? Colors.white
                      : Colors.grey.withOpacity(0.5),
                  size: isMobile ? 22 : 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Compare Timelines',
                  style: TextStyle(
                    color: canCompare
                        ? Colors.white
                        : Colors.grey.withOpacity(0.5),
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w300,
                    letterSpacing: isMobile ? 1.5 : 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getAvailableCategories(TimelineProvider provider) {
    return provider.eventsByCategory.keys.toList()..sort();
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'War': Icons.military_tech,
      'Politics': Icons.account_balance,
      'Science': Icons.science,
      'Technology': Icons.computer,
      'Culture': Icons.palette,
      'Economy': Icons.monetization_on,
      'Discovery': Icons.explore,
      'Religion': Icons.temple_buddhist,
      'Art': Icons.brush,
      'Medicine': Icons.medical_services,
    };
    return icons[category] ?? Icons.event;
  }
}

// Animated particles painter for background effect
class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final random = math.Random();
  final List<Particle> particles = [];

  ParticlesPainter({required this.animation}) : super(repaint: animation) {
    // Initialize particles with random positions
    for (int i = 0; i < 30; i++) {
      particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 2 + 1,
          speed: random.nextDouble() * 0.2 + 0.1, // Slower speed
        ),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      // Update particle position based on animation
      final y = (particle.y - animation.value * particle.speed) % 1.0;
      final adjustedY = y < 0 ? y + 1 : y;

      // Calculate opacity based on vertical position
      final opacity = math.sin(adjustedY * math.pi) * 0.3;

      paint.color = Colors.cyanAccent.withOpacity(opacity);
      canvas.drawCircle(
        Offset(particle.x * size.width, adjustedY * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

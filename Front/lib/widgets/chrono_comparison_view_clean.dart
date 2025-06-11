import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../providers/timeline_provider.dart';
import '../models/timeline_event.dart';

class ChronoComparisonView extends StatefulWidget {
  const ChronoComparisonView({super.key});

  @override
  State<ChronoComparisonView> createState() => _ChronoComparisonViewState();
}

class _ChronoComparisonViewState extends State<ChronoComparisonView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  TimelineEvent? _selectedEvent;
  double _scrollOffset = 0;
  final double _yearHeight = 120.0; // Increased height for better spacing

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Enhanced wheel effect with depth perception
  Map<String, double> _calculateDepthEffects(
    double itemPosition,
    double screenHeight,
  ) {
    final screenCenter = _scrollOffset + screenHeight / 2;
    final distanceFromCenter = itemPosition - screenCenter;
    final absDistance = distanceFromCenter.abs();
    final maxDistance = screenHeight / 2;
    final normalizedDistance = (absDistance / maxDistance).clamp(0.0, 1.0);

    // Create a more pronounced curve for depth effect
    final depthCurve = 1.0 - (normalizedDistance * normalizedDistance);

    // Calculate various effects
    final scale = 0.4 + (depthCurve * 0.6); // Scale from 0.4 to 1.0
    final opacity = 0.3 + (depthCurve * 0.7); // Opacity from 0.3 to 1.0
    final blur = normalizedDistance * 8.0; // Blur from 0 to 8

    // Horizontal offset for 3D cylinder effect
    final horizontalOffset = distanceFromCenter * 0.15;

    return {
      'scale': scale,
      'opacity': opacity,
      'blur': blur,
      'horizontalOffset': horizontalOffset,
      'zIndex': depthCurve,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimelineProvider>(
      builder: (context, provider, child) {
        final category1 = provider.comparisonCategory1;
        final category2 = provider.comparisonCategory2;

        if (category1 == null || category2 == null) {
          return const Scaffold(
            body: Center(child: Text('No categories selected for comparison')),
          );
        }

        final events1 = provider.eventsByCategory[category1] ?? [];
        final events2 = provider.eventsByCategory[category2] ?? [];

        // Calculate timeline bounds
        final allEvents = [...events1, ...events2];
        if (allEvents.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(context, provider, category1, category2),
            body: const Center(child: Text('No events to display')),
          );
        }

        final earliestYear =
            allEvents.map((e) => e.date.year).reduce((a, b) => a < b ? a : b) -
            5;
        final latestYear =
            allEvents.map((e) => e.date.year).reduce((a, b) => a > b ? a : b) +
            5;
        final totalHeight = (latestYear - earliestYear) * _yearHeight;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E27),
          appBar: _buildAppBar(context, provider, category1, category2),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;
                final screenWidth = constraints.maxWidth;

                return Stack(
                  children: [
                    // Animated background gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.3),
                          radius: 1.5,
                          colors: [
                            const Color(0xFF1A1F3A),
                            const Color(0xFF0A0E27),
                            const Color(0xFF050714),
                          ],
                        ),
                      ),
                    ),

                    // Subtle grid pattern
                    CustomPaint(
                      size: Size(screenWidth, screenHeight),
                      painter: GridPainter(scrollOffset: _scrollOffset),
                    ),

                    // Center focus line with glow
                    Positioned(
                      top: screenHeight / 2 - 1,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.cyanAccent.withOpacity(0.5),
                              Colors.purpleAccent.withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Timeline content
                    SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        height: totalHeight + screenHeight * 2,
                        child: _buildTimelineContent(
                          context,
                          category1,
                          category2,
                          events1,
                          events2,
                          earliestYear,
                          latestYear,
                          screenWidth,
                          screenHeight,
                        ),
                      ),
                    ),

                    // Event detail overlay
                    if (_selectedEvent != null)
                      _buildEventDetailOverlay(context),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TimelineProvider provider,
    String category1,
    String category2,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF0A0E27).withOpacity(0.8),
      toolbarHeight: 80,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1F3A),
              const Color(0xFF0A0E27).withOpacity(0.8),
            ],
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Timeline Comparison',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w300,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCategoryChip(category1, Colors.cyanAccent),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.sync_alt,
                  size: 20,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              _buildCategoryChip(category2, Colors.purpleAccent),
            ],
          ),
        ],
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => provider.setCurrentView('category_selection'),
      ),
    );
  }

  Widget _buildCategoryChip(String category, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTimelineContent(
    BuildContext context,
    String category1,
    String category2,
    List<TimelineEvent> events1,
    List<TimelineEvent> events2,
    int earliestYear,
    int latestYear,
    double screenWidth,
    double screenHeight,
  ) {
    // Sort all events by year for proper layering
    final allEventsWithSide =
        [
          ...events1.map((e) => {'event': e, 'isLeft': true}),
          ...events2.map((e) => {'event': e, 'isLeft': false}),
        ]..sort((a, b) {
          final eventA = a['event'] as TimelineEvent;
          final eventB = b['event'] as TimelineEvent;
          return eventA.date.compareTo(eventB.date);
        });

    return Stack(
      children: [
        // Year markers in the center
        _buildYearMarkers(
          context,
          earliestYear,
          latestYear,
          screenHeight,
          screenWidth,
        ),

        // Events with depth sorting
        ...allEventsWithSide.map((data) {
          final event = data['event'] as TimelineEvent;
          final isLeft = data['isLeft'] as bool;
          final eventY =
              screenHeight + ((event.date.year - earliestYear) * _yearHeight);
          final effects = _calculateDepthEffects(eventY, screenHeight);

          return _buildEventCard(
            context,
            event,
            eventY,
            effects,
            isLeft,
            screenWidth,
            isLeft ? Colors.cyanAccent : Colors.purpleAccent,
          );
        }),
      ],
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    TimelineEvent event,
    double eventY,
    Map<String, double> effects,
    bool isLeft,
    double screenWidth,
    Color accentColor,
  ) {
    final blur = effects['blur']!;
    final scale = effects['scale']!;
    final opacity = effects['opacity']!;
    final horizontalOffset = effects['horizontalOffset']!;

    return Positioned(
      top: eventY - 60,
      left: isLeft ? 20 : screenWidth / 2 + 20,
      right: isLeft ? screenWidth / 2 + 20 : 20,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(horizontalOffset, 0)
          ..scale(scale),
        alignment: Alignment.center,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: opacity,
          child: GestureDetector(
            onTap: () => setState(() => _selectedEvent = event),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isLeft
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      end: isLeft
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      colors: [
                        accentColor.withOpacity(0.1),
                        accentColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withOpacity(0.3 * opacity),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.2 * opacity),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Image section
                      if (event.imageUrl != null)
                        Container(
                          width: 100,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            image: DecorationImage(
                              image: NetworkImage(event.imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withOpacity(0.3),
                                accentColor.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.image_outlined,
                            color: accentColor,
                            size: 40,
                          ),
                        ),
                      // Content section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                event.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${event.date.year}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearMarkers(
    BuildContext context,
    int earliestYear,
    int latestYear,
    double screenHeight,
    double screenWidth,
  ) {
    return Stack(
      children: [
        for (int year = earliestYear; year <= latestYear; year += 5)
          Positioned(
            top: screenHeight + ((year - earliestYear) * _yearHeight) - 15,
            left: screenWidth / 2 - 40,
            width: 80,
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                final position =
                    screenHeight + ((year - earliestYear) * _yearHeight);
                final effects = _calculateDepthEffects(position, screenHeight);

                return Transform.scale(
                  scale: effects['scale']!,
                  child: Opacity(
                    opacity: effects['opacity']!,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F3A).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 1,
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
    );
  }

  Widget _buildEventDetailOverlay(BuildContext context) {
    final event = _selectedEvent!;
    final category = event.category;
    final accentColor =
        category == context.read<TimelineProvider>().comparisonCategory1
        ? Colors.cyanAccent
        : Colors.purpleAccent;

    return GestureDetector(
      onTap: () => setState(() => _selectedEvent = null),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping the modal
              child: Container(
                margin: const EdgeInsets.all(20),
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 700,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF1A1F3A), const Color(0xFF0A0E27)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image header
                      if (event.imageUrl != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(event.imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category and date
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accentColor.withOpacity(0.3),
                                          accentColor.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: accentColor.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      event.category,
                                      style: TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${event.date.day}/${event.date.month}/${event.date.year}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Description
                              Text(
                                event.description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                              ),

                              // Additional details
                              if (event.details != null &&
                                  event.details!.isNotEmpty) ...[
                                const SizedBox(height: 30),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Additional Information',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.9),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...event.details!.entries.map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.arrow_right,
                                                size: 20,
                                                color: accentColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                      fontSize: 14,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: '${entry.key}: ',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: entry.value,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Close button
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _selectedEvent = null),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            backgroundColor: accentColor.withOpacity(0.2),
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for background grid
class GridPainter extends CustomPainter {
  final double scrollOffset;

  GridPainter({required this.scrollOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final gridSize = 50.0;
    final offsetY = scrollOffset % gridSize;

    // Draw horizontal lines
    for (double y = -offsetY; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines with perspective
    for (double x = 0; x < size.width; x += gridSize) {
      final distanceFromCenter = (x - size.width / 2).abs();
      final perspective = 1 - (distanceFromCenter / (size.width / 2)) * 0.3;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint..color = Colors.white.withOpacity(0.03 * perspective),
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}

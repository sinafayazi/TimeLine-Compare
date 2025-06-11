import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
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

  // Zoom and LOD properties
  double _zoomLevel = 1.0;
  final double _minZoom = 0.5;
  final double _maxZoom = 5.0;
  double _baseYearHeight = 120.0;

  // Pinch zoom properties
  double _startZoom = 1.0;

  // Focus node for keyboard shortcuts
  final FocusNode _focusNode = FocusNode();

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

    // Request focus for keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Get current year height based on zoom
  double get _yearHeight => _baseYearHeight * _zoomLevel;

  // Calculate perspective effects with proper cylindrical transformation
  Map<String, double> _calculatePerspectiveEffects(
    double itemY,
    double screenHeight,
    bool isLeftSide,
  ) {
    final screenCenter = _scrollOffset + screenHeight / 2;
    final distanceFromCenter = itemY - screenCenter;
    final normalizedPosition = distanceFromCenter / (screenHeight / 2);

    // Calculate vertical position (0 = top, 1 = bottom of visible area)
    final verticalPosition = ((itemY - _scrollOffset) / screenHeight).clamp(
      0.0,
      1.0,
    );

    // Cylindrical perspective calculations
    final angle = normalizedPosition * math.pi / 3; // Max 60 degrees rotation
    final depth = math.cos(angle.clamp(-math.pi / 2, math.pi / 2));

    // Scale based on depth
    final scale = 0.5 + (depth * 0.5);

    // Opacity with fade at top and bottom
    double opacity = depth;
    if (verticalPosition < 0.2) {
      opacity *= verticalPosition / 0.2;
    } else if (verticalPosition > 0.8) {
      opacity *= (1.0 - verticalPosition) / 0.2;
    }
    opacity = opacity.clamp(0.0, 1.0);

    // Blur increases with distance from center
    final blur = (1.0 - depth) * 8.0;

    // Horizontal offset for cylindrical effect
    double horizontalOffset;
    if (isLeftSide) {
      // Left side: start from right, curve to left
      horizontalOffset = math.sin(angle) * 100;
    } else {
      // Right side: start from left, curve to right
      horizontalOffset = -math.sin(angle) * 100;
    }

    return {
      'scale': scale,
      'opacity': opacity,
      'blur': blur,
      'horizontalOffset': horizontalOffset,
      'depth': depth,
      'angle': angle,
    };
  }

  // Handle keyboard shortcuts for zoom
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.isControlPressed) {
        if (event.logicalKey == LogicalKeyboardKey.equal ||
            event.logicalKey == LogicalKeyboardKey.add) {
          _updateZoom(_zoomLevel * 1.2);
        } else if (event.logicalKey == LogicalKeyboardKey.minus) {
          _updateZoom(_zoomLevel / 1.2);
        } else if (event.logicalKey == LogicalKeyboardKey.digit0) {
          _updateZoom(1.0);
        }
      }
    }
  }

  void _updateZoom(double newZoom) {
    setState(() {
      final oldZoom = _zoomLevel;
      _zoomLevel = newZoom.clamp(_minZoom, _maxZoom);

      // Adjust scroll position to maintain center
      if (_scrollController.hasClients) {
        final viewportCenter =
            _scrollController.offset +
            _scrollController.position.viewportDimension / 2;
        final zoomRatio = _zoomLevel / oldZoom;
        final newOffset =
            viewportCenter * zoomRatio -
            _scrollController.position.viewportDimension / 2;
        _scrollController.jumpTo(
          newOffset.clamp(0, _scrollController.position.maxScrollExtent),
        );
      }
    });
  }

  // Get appropriate time unit based on zoom level
  String _getTimeUnit() {
    if (_zoomLevel < 0.8) return 'decade';
    if (_zoomLevel < 1.5) return 'year';
    if (_zoomLevel < 3.0) return 'month';
    return 'day';
  }

  // Get time markers based on zoom level
  List<TimeMarker> _getTimeMarkers(int startYear, int endYear) {
    final markers = <TimeMarker>[];
    final unit = _getTimeUnit();

    switch (unit) {
      case 'decade':
        final startDecade = (startYear ~/ 10) * 10;
        for (int year = startDecade; year <= endYear; year += 10) {
          markers.add(
            TimeMarker(
              label: '${year}s',
              position: (year - startYear) * _yearHeight,
            ),
          );
        }
        break;
      case 'year':
        for (int year = startYear; year <= endYear; year += 1) {
          markers.add(
            TimeMarker(
              label: year.toString(),
              position: (year - startYear) * _yearHeight,
            ),
          );
        }
        break;
      case 'month':
        for (int year = startYear; year <= endYear; year++) {
          for (int month = 1; month <= 12; month += 3) {
            final monthNames = ['Jan', 'Apr', 'Jul', 'Oct'];
            markers.add(
              TimeMarker(
                label: '${monthNames[(month - 1) ~/ 3]} $year',
                position: (year - startYear + (month - 1) / 12) * _yearHeight,
              ),
            );
          }
        }
        break;
      case 'day':
        // Show monthly markers when zoomed in
        for (int year = startYear; year <= endYear; year++) {
          for (int month = 1; month <= 12; month++) {
            final monthNames = [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ];
            markers.add(
              TimeMarker(
                label: '${monthNames[month - 1]} $year',
                position: (year - startYear + (month - 1) / 12) * _yearHeight,
              ),
            );
          }
        }
        break;
    }

    return markers;
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
            allEvents
                .map((e) => e.endDate?.year ?? e.date.year)
                .reduce((a, b) => a > b ? a : b) +
            5;
        final totalHeight = (latestYear - earliestYear) * _yearHeight;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E27),
          appBar: _buildAppBar(context, provider, category1, category2),
          body: RawKeyboardListener(
            focusNode: _focusNode,
            onKey: _handleKeyEvent,
            child: GestureDetector(
              onScaleStart: (details) {
                _startZoom = _zoomLevel;
              },
              onScaleUpdate: (details) {
                _updateZoom(_startZoom * details.scale);
              },
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenHeight = constraints.maxHeight;
                    final screenWidth = constraints.maxWidth;

                    return Stack(
                      children: [
                        // Animated background
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

                        // Timeline content
                        SingleChildScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          child: Container(
                            height: totalHeight + screenHeight * 2,
                            child: Stack(
                              children: [
                                // Time markers (horizontal lines)
                                ..._buildTimeMarkers(
                                  context,
                                  earliestYear,
                                  latestYear,
                                  screenHeight,
                                  screenWidth,
                                ),

                                // Events
                                _buildTimelineEvents(
                                  context,
                                  category1,
                                  category2,
                                  events1,
                                  events2,
                                  earliestYear,
                                  screenHeight,
                                  screenWidth,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Zoom indicator
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: _buildZoomIndicator(),
                        ),

                        // Event detail overlay
                        if (_selectedEvent != null)
                          _buildEventDetailOverlay(context),
                      ],
                    );
                  },
                ),
              ),
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
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () => _showZoomHelp(context),
        ),
      ],
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

  List<Widget> _buildTimeMarkers(
    BuildContext context,
    int earliestYear,
    int latestYear,
    double screenHeight,
    double screenWidth,
  ) {
    final markers = _getTimeMarkers(earliestYear, latestYear);

    return markers.map((marker) {
      final markerY = screenHeight + marker.position;

      return Positioned(
        top: markerY,
        left: 20,
        right: 20,
        child: AnimatedBuilder(
          animation: _scrollController,
          builder: (context, child) {
            final effects = _calculatePerspectiveEffects(
              markerY,
              screenHeight,
              true,
            );

            return Opacity(
              opacity: effects['opacity']! * 0.5,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F3A).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        marker.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildTimelineEvents(
    BuildContext context,
    String category1,
    String category2,
    List<TimelineEvent> events1,
    List<TimelineEvent> events2,
    int earliestYear,
    double screenHeight,
    double screenWidth,
  ) {
    final leftEvents = _prepareEvents(
      events1,
      earliestYear,
      true,
      screenHeight,
      screenWidth,
    );
    final rightEvents = _prepareEvents(
      events2,
      earliestYear,
      false,
      screenHeight,
      screenWidth,
    );

    return Stack(
      children: [
        // Left side events
        ...leftEvents.map(
          (eventData) => _buildEventWithSubEvents(
            context,
            eventData,
            screenHeight,
            screenWidth / 2,
            true,
            Colors.cyanAccent,
          ),
        ),

        // Right side events
        ...rightEvents.map(
          (eventData) => _buildEventWithSubEvents(
            context,
            eventData,
            screenHeight,
            screenWidth / 2,
            false,
            Colors.purpleAccent,
          ),
        ),
      ],
    );
  }

  List<EventData> _prepareEvents(
    List<TimelineEvent> events,
    int earliestYear,
    bool isLeftSide,
    double screenHeight,
    double screenWidth,
  ) {
    return events.map((event) {
      final startY =
          screenHeight + ((event.date.year - earliestYear) * _yearHeight);
      final endY = event.endDate != null
          ? screenHeight + ((event.endDate!.year - earliestYear) * _yearHeight)
          : startY;

      return EventData(
        event: event,
        startY: startY,
        endY: endY,
        isLeftSide: isLeftSide,
      );
    }).toList();
  }

  Widget _buildEventWithSubEvents(
    BuildContext context,
    EventData eventData,
    double screenHeight,
    double containerWidth,
    bool isLeftSide,
    Color accentColor,
  ) {
    final showSubEvents =
        _zoomLevel > 2.0 &&
        eventData.event.subEvents != null &&
        eventData.event.subEvents!.isNotEmpty;

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final effects = _calculatePerspectiveEffects(
          eventData.startY,
          screenHeight,
          isLeftSide,
        );

        return Positioned(
          top: eventData.startY,
          left: isLeftSide ? 0 : containerWidth,
          width: containerWidth,
          height: eventData.endY - eventData.startY + 100,
          child: Transform(
            transform: Matrix4.identity()
              ..translate(
                isLeftSide
                    ? effects['horizontalOffset']!
                    : -effects['horizontalOffset']!,
                0,
              )
              ..scale(effects['scale']!),
            alignment: isLeftSide
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Stack(
              children: [
                // Main event
                _buildEventCard(
                  context,
                  eventData.event,
                  effects,
                  isLeftSide,
                  accentColor,
                  containerWidth,
                  isMainEvent: true,
                ),

                // Sub-events (if zoomed in)
                if (showSubEvents)
                  ...eventData.event.subEvents!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final subEvent = entry.value;
                    final subEventY =
                        eventData.startY +
                        ((subEvent.date.year - eventData.event.date.year) *
                            _yearHeight) +
                        (subEvent.date.month / 12 * _yearHeight);

                    return Positioned(
                      top: subEventY - eventData.startY + 40,
                      left: isLeftSide ? 40 : 20,
                      right: isLeftSide ? 20 : 40,
                      child: _buildEventCard(
                        context,
                        subEvent,
                        effects,
                        isLeftSide,
                        accentColor.withOpacity(0.7),
                        containerWidth - 60,
                        isMainEvent: false,
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    TimelineEvent event,
    Map<String, double> effects,
    bool isLeftSide,
    Color accentColor,
    double maxWidth, {
    bool isMainEvent = true,
  }) {
    final blur = effects['blur']!;
    final opacity = effects['opacity']!;

    return GestureDetector(
      onTap: () => setState(() => _selectedEvent = event),
      child: Container(
        margin: EdgeInsets.only(
          left: isLeftSide ? 20 : 10,
          right: isLeftSide ? 10 : 20,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMainEvent ? 16 : 12),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: opacity,
              child: Container(
                height: isMainEvent ? 100 : 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: isLeftSide
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    end: isLeftSide
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    colors: [
                      accentColor.withOpacity(0.2),
                      accentColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isMainEvent ? 16 : 12),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: isMainEvent ? 1 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    if (event.imageUrl != null && isMainEvent)
                      Container(
                        width: 80,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(event.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(isMainEvent ? 12 : 8),
                        child: Column(
                          crossAxisAlignment: isLeftSide
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              event.title,
                              style: TextStyle(
                                fontSize: isMainEvent ? 14 : 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: isMainEvent ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: isLeftSide
                                  ? TextAlign.right
                                  : TextAlign.left,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatEventDate(event),
                              style: TextStyle(
                                fontSize: isMainEvent ? 11 : 10,
                                color: accentColor,
                              ),
                              textAlign: isLeftSide
                                  ? TextAlign.right
                                  : TextAlign.left,
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
    );
  }

  String _formatEventDate(TimelineEvent event) {
    final startDate =
        '${event.date.day}/${event.date.month}/${event.date.year}';
    if (event.endDate != null) {
      final endDate =
          '${event.endDate!.day}/${event.endDate!.month}/${event.endDate!.year}';
      return '$startDate - $endDate';
    }
    return startDate;
  }

  Widget _buildZoomIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white, size: 16),
            onPressed: () => _updateZoom(_zoomLevel / 1.2),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          Text(
            '${(_zoomLevel * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 16),
            onPressed: () => _updateZoom(_zoomLevel * 1.2),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  void _showZoomHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Navigation Help',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Pinch to zoom or use:\n'
          '• Ctrl + Plus: Zoom in\n'
          '• Ctrl + Minus: Zoom out\n'
          '• Ctrl + 0: Reset zoom\n\n'
          'Zoom in to see sub-events!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailOverlay(BuildContext context) {
    // Implementation remains the same as before
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
              onTap: () {},
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
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                          ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      event.category,
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatEventDate(event),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                event.description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                              ),
                              if (event.subEvents != null &&
                                  event.subEvents!.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Sub-events',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...event.subEvents!.map(
                                  (subEvent) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subEvent.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatEventDate(subEvent),
                                          style: TextStyle(
                                            color: accentColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Padding(
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
      ),
    );
  }
}

// Helper classes
class TimeMarker {
  final String label;
  final double position;

  TimeMarker({required this.label, required this.position});
}

class EventData {
  final TimelineEvent event;
  final double startY;
  final double endY;
  final bool isLeftSide;

  EventData({
    required this.event,
    required this.startY,
    required this.endY,
    required this.isLeftSide,
  });
}

// Extension to support sub-events (add to your TimelineEvent model)
extension TimelineEventExtension on TimelineEvent {
  DateTime? get endDate => null; // Override in your model
  List<TimelineEvent>? get subEvents => null; // Override in your model
}

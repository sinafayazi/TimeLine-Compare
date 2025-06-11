import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimelineProvider>(
      builder: (context, provider, child) {
        final categories = _getAvailableCategories(provider);

        return Scaffold(
          // Background that extends to all edges for shadows and gradients
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Main content area with manual safe area positioning
                  Expanded(
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 20.0,
                          right: 20.0,
                          top: MediaQuery.of(context).padding.top,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 20),
                              // Header
                              _buildHeader(context),
                              const SizedBox(height: 40),

                              // Category Selection Cards
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  bool isNarrowScreen =
                                      constraints.maxWidth < 600;
                                  if (isNarrowScreen) {
                                    // Narrow screen: Use a Column
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildCategorySelector(
                                          context,
                                          'First Timeline Category',
                                          _selectedCategory1,
                                          categories,
                                          (category) => setState(
                                            () => _selectedCategory1 = category,
                                          ),
                                          Theme.of(context).colorScheme.primary,
                                          Icons.timeline,
                                          isNarrowScreen,
                                        ),
                                        const SizedBox(height: 20),
                                        _buildVsIndicator(context),
                                        const SizedBox(height: 20),
                                        _buildCategorySelector(
                                          context,
                                          'Second Timeline Category',
                                          _selectedCategory2,
                                          categories,
                                          (category) => setState(
                                            () => _selectedCategory2 = category,
                                          ),
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                          Icons.compare_arrows,
                                          isNarrowScreen,
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Wide screen: Use a Row
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Flexible(
                                          child: _buildCategorySelector(
                                            context,
                                            'First Timeline Category',
                                            _selectedCategory1,
                                            categories,
                                            (category) => setState(
                                              () =>
                                                  _selectedCategory1 = category,
                                            ),
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            Icons.timeline,
                                            isNarrowScreen,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        _buildVsIndicator(context),
                                        const SizedBox(width: 20),
                                        Flexible(
                                          child: _buildCategorySelector(
                                            context,
                                            'Second Timeline Category',
                                            _selectedCategory2,
                                            categories,
                                            (category) => setState(
                                              () =>
                                                  _selectedCategory2 = category,
                                            ),
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                            Icons.compare_arrows,
                                            isNarrowScreen,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),

                              // Add some bottom padding for better scrolling
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Fixed Compare Button at bottom
                  SafeArea(
                    top: false,
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 20,
                      ),
                      child: _buildCompareButton(context, provider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // App logo/title with animated effect
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Opacity(
                opacity: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.timeline,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'ChronoHistory',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Compare Historical Categories',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Select two categories to explore their timelines in an immersive 3D chronological view with dynamic zoom and rotation',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
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
    bool isNarrowScreen, // Added parameter
  ) {
    return Container(
      // Added height constraints for narrow screens to prevent unbounded growth in Column
      height: isNarrowScreen && selectedCategory == null
          ? 450
          : null, // Adjust height as needed, only when grid is visible
      constraints: isNarrowScreen && selectedCategory == null
          ? const BoxConstraints(maxHeight: 500)
          : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: selectedCategory != null
              ? accentColor.withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize
              .min, // Added to make the card shrink vertically to content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Selected Category Display
            if (selectedCategory != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(selectedCategory),
                      color: accentColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedCategory,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        if (title.contains('First')) {
                          _selectedCategory1 = null;
                        } else {
                          _selectedCategory2 = null;
                        }
                      }),
                      icon: Icon(Icons.clear, color: accentColor, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Category Grid
            // Removed Expanded here. The GridView and _buildSelectedCategoryInfo will determine their own height.
            selectedCategory == null
                ? LayoutBuilder(
                    // Added LayoutBuilder for responsive GridView
                    builder: (context, constraints) {
                      bool useSingleColumnGrid = constraints.maxWidth < 300;
                      int crossAxisCount = useSingleColumnGrid ? 1 : 2;
                      double childAspectRatio = useSingleColumnGrid
                          ? 2.8
                          : 1.2; // Adjusted for single column

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount, // Responsive
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: childAspectRatio, // Responsive
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isDisabled =
                              (title.contains('First') &&
                                  category == _selectedCategory2) ||
                              (title.contains('Second') &&
                                  category == _selectedCategory1);

                          return _buildCategoryCard(
                            context,
                            category,
                            accentColor,
                            isDisabled,
                            () => onSelected(category),
                          );
                        },
                      );
                    },
                  )
                : _buildSelectedCategoryInfo(
                    context,
                    selectedCategory,
                    accentColor,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String category,
    Color accentColor,
    bool isDisabled,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(
            8,
          ), // Added padding to give content some space
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDisabled
                ? Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3)
                : accentColor.withOpacity(0.05),
            border: Border.all(
              color: isDisabled
                  ? Colors.transparent
                  : accentColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(category),
                color: isDisabled
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                    : accentColor,
                size: 20, // Reduced icon size slightly
              ),
              const SizedBox(height: 4), // Reduced spacing
              Text(
                category,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDisabled
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                      : accentColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 10, // Reduced font size slightly
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Allow text to wrap to a second line
                overflow:
                    TextOverflow.ellipsis, // Add ellipsis if it still overflows
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCategoryInfo(
    BuildContext context,
    String category,
    Color accentColor,
  ) {
    return Consumer<TimelineProvider>(
      builder: (context, provider, child) {
        final categoryEvents = provider.eventsByCategory[category] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:
              MainAxisSize.min, // Added to ensure Column takes minimum space
          children: [
            Text(
              'Timeline Preview',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Removed Expanded here. ListView will determine its own height with shrinkWrap.
            ListView.builder(
              shrinkWrap: true, // Added
              physics: const NeverScrollableScrollPhysics(), // Added
              itemCount: categoryEvents.take(3).length,
              itemBuilder: (context, index) {
                final event = categoryEvents[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${event.date.year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: accentColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (categoryEvents.length > 3)
              Text(
                '+${categoryEvents.length - 3} more events',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: accentColor.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVsIndicator(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompareButton(BuildContext context, TimelineProvider provider) {
    bool canCompare =
        _selectedCategory1 != null &&
        _selectedCategory2 != null &&
        _selectedCategory1 != _selectedCategory2;

    return ElevatedButton.icon(
      icon: const Icon(Icons.compare_arrows, size: 28),
      label: const Text('Compare Timelines', style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        backgroundColor: canCompare
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.withOpacity(0.5),
        foregroundColor: canCompare
            ? Theme.of(context).colorScheme.onPrimary
            : Colors.white.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: canCompare ? 5 : 0,
      ),
      onPressed: canCompare
          ? () {
              if (_selectedCategory1 != null && _selectedCategory2 != null) {
                provider.setComparisonCategories(
                  _selectedCategory1!,
                  _selectedCategory2!,
                );
                provider.setCurrentView('chrono_comparison');
              }
            }
          : null, // Disable button if conditions are not met
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

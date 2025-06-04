import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timeline_provider.dart';
import '../widgets/timeline_view.dart';
import '../widgets/comparison_view.dart';
import '../widgets/category_view.dart';
import '../widgets/category_selection_view.dart';
import '../widgets/chrono_comparison_view.dart';
import 'timeline_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimelineProvider>(
      builder: (context, provider, child) {
        // If we're on category selection or chrono comparison, show full screen
        if (provider.currentView == 'category_selection' || 
            provider.currentView == 'chrono_comparison') {
          return _buildCurrentView(provider);
        }
        
        // Otherwise show the regular scaffold with app bar
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'ChronoHistory',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.timeline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TimelineManagementScreen(),
                    ),
                  );
                },
                tooltip: 'Manage Timelines',
              ),
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  provider.setCurrentView('category_selection');
                },
                tooltip: 'Home',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: provider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onChanged: provider.setSearchQuery,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // View selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        _ViewChip(
                          label: 'Chronological',
                          value: 'chronological',
                          isSelected: provider.currentView == 'chronological',
                          onSelected: () => provider.setCurrentView('chronological'),
                        ),
                        const SizedBox(width: 8),
                        _ViewChip(
                          label: 'Comparison',
                          value: 'comparison',
                          isSelected: provider.currentView == 'comparison',
                          onSelected: () => provider.setCurrentView('comparison'),
                        ),
                        const SizedBox(width: 8),
                        _ViewChip(
                          label: 'By Category',
                          value: 'category',
                          isSelected: provider.currentView == 'category',
                          onSelected: () => provider.setCurrentView('category'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          body: _buildCurrentView(provider),
          floatingActionButton: provider.selectedTimelines.isEmpty
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TimelineManagementScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.timeline),
                  label: const Text('Select Timelines'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildCurrentView(TimelineProvider provider) {
    switch (provider.currentView) {
      case 'category_selection':
        return const CategorySelectionView();
      case 'chrono_comparison':
        return const ChronoComparisonView();
      case 'chronological':
        return provider.selectedTimelines.isEmpty
            ? const CategorySelectionView()
            : const TimelineView();
      case 'comparison':
        return provider.selectedTimelines.isEmpty
            ? const CategorySelectionView()
            : const ComparisonView();
      case 'category':
        return provider.selectedTimelines.isEmpty
            ? const CategorySelectionView()
            : const CategoryView();
      default:
        return const CategorySelectionView();
    }
  }
}

class _ViewChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onSelected;

  const _ViewChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }
}

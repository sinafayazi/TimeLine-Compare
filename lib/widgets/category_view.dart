import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/timeline_provider.dart';
import '../models/timeline_event.dart';

class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimelineProvider>(
      builder: (context, provider, child) {
        final eventsByCategory = provider.eventsByCategory;

        if (eventsByCategory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No events found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or selecting different timelines',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: eventsByCategory.length,
          itemBuilder: (context, index) {
            final category = eventsByCategory.keys.elementAt(index);
            final events = eventsByCategory[category]!;

            return _CategorySection(category: category, events: events);
          },
        );
      },
    );
  }
}

class _CategorySection extends StatefulWidget {
  final String category;
  final List<TimelineEvent> events;

  const _CategorySection({required this.category, required this.events});

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.category, context);
    final categoryIcon = _getCategoryIcon(widget.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(categoryIcon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: categoryColor,
                              ),
                        ),
                        Text(
                          '${widget.events.length} event${widget.events.length != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: categoryColor,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: widget.events
                    .map(
                      (event) => _CategoryEventCard(
                        event: event,
                        categoryColor: categoryColor,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category, BuildContext context) {
    final colors = {
      'War': Colors.red,
      'Politics': Colors.blue,
      'Science': Colors.green,
      'Technology': Colors.purple,
      'Culture': Colors.orange,
      'Economy': Colors.teal,
      'Discovery': Colors.indigo,
      'Religion': Colors.brown,
      'Art': Colors.pink,
      'Medicine': Colors.cyan,
    };
    return colors[category] ?? Theme.of(context).colorScheme.primary;
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

class _CategoryEventCard extends StatelessWidget {
  final TimelineEvent event;
  final Color categoryColor;

  const _CategoryEventCard({required this.event, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: event.isImportant ? categoryColor : null,
                  ),
                ),
              ),
              if (event.isImportant)
                Icon(Icons.star, color: categoryColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, y').format(event.startDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: categoryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (event.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: event.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: categoryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: categoryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

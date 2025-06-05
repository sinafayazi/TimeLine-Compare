import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/timeline_provider.dart';
import '../models/timeline_event.dart';

class ComparisonView extends StatelessWidget {
  const ComparisonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimelineProvider>(
      builder: (context, provider, child) {
        final timelines = provider.selectedTimelines;

        if (timelines.length < 2) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.compare_arrows,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select at least 2 timelines',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Comparison view requires multiple timelines to show side-by-side events',
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

        // Group events by time periods for comparison
        final groupedEvents = _groupEventsByPeriod(provider.filteredEvents);

        if (groupedEvents.isEmpty) {
          return const Center(child: Text('No events to compare'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedEvents.length,
          itemBuilder: (context, index) {
            final period = groupedEvents.keys.elementAt(index);
            final events = groupedEvents[period]!;

            return _ComparisonSection(
              period: period,
              events: events,
              timelines: timelines,
            );
          },
        );
      },
    );
  }

  Map<String, List<TimelineEvent>> _groupEventsByPeriod(
    List<TimelineEvent> events,
  ) {
    final Map<String, List<TimelineEvent>> grouped = {};

    for (final event in events) {
      // Group by decade
      final decade = (event.startDate.year ~/ 10) * 10;
      final periodKey = '${decade}s';

      if (grouped[periodKey] == null) {
        grouped[periodKey] = [];
      }
      grouped[periodKey]!.add(event);
    }

    // Sort events within each period
    for (final eventList in grouped.values) {
      eventList.sort((a, b) => a.startDate.compareTo(b.startDate));
    }

    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  final String period;
  final List<TimelineEvent> events;
  final List<Timeline> timelines;

  const _ComparisonSection({
    required this.period,
    required this.events,
    required this.timelines,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: timelines.map((timeline) {
                final timelineEvents = events.where((event) {
                  return timeline.events.any((e) => e.id == event.id);
                }).toList();

                return Expanded(
                  child: _TimelineColumn(
                    timeline: timeline,
                    events: timelineEvents,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineColumn extends StatelessWidget {
  final Timeline timeline;
  final List<TimelineEvent> events;

  const _TimelineColumn({required this.timeline, required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              timeline.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'No events in this period',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...events.map((event) => _ComparisonEventCard(event: event)),
        ],
      ),
    );
  }
}

class _ComparisonEventCard extends StatelessWidget {
  final TimelineEvent event;

  const _ComparisonEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (event.isImportant)
                Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, y').format(event.startDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.description,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              event.category,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

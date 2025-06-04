import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/timeline_event.dart';

class TimelineProvider with ChangeNotifier {
  List<Timeline> _timelines = [];
  List<Timeline> _selectedTimelines = [];
  String _currentView = 'category_selection'; // Start with category selection
  String _searchQuery = '';

  // Comparison categories
  String? _comparisonCategory1;
  String? _comparisonCategory2;

  List<Timeline> get timelines => _timelines;
  List<Timeline> get selectedTimelines => _selectedTimelines;
  String get currentView => _currentView;
  String get searchQuery => _searchQuery;
  String? get comparisonCategory1 => _comparisonCategory1;
  String? get comparisonCategory2 => _comparisonCategory2;

  // Get all events from selected timelines, sorted by date
  List<TimelineEvent> get allEvents {
    List<TimelineEvent> events = [];
    for (var timeline in _selectedTimelines) {
      events.addAll(timeline.events);
    }
    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  // Get filtered events based on search query
  List<TimelineEvent> get filteredEvents {
    if (_searchQuery.isEmpty) return allEvents;
    return allEvents.where((event) {
      return event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  // Get events grouped by category
  Map<String, List<TimelineEvent>> get eventsByCategory {
    Map<String, List<TimelineEvent>> grouped = {};
    for (var event in filteredEvents) {
      if (grouped[event.category] == null) {
        grouped[event.category] = [];
      }
      grouped[event.category]!.add(event);
    }
    return grouped;
  }

  // Get events for first comparison category
  List<TimelineEvent> get category1Events {
    if (_comparisonCategory1 == null) return [];
    return eventsByCategory[_comparisonCategory1] ?? [];
  }

  // Get events for second comparison category
  List<TimelineEvent> get category2Events {
    if (_comparisonCategory2 == null) return [];
    return eventsByCategory[_comparisonCategory2] ?? [];
  }

  TimelineProvider() {
    _loadData();
    _loadSampleData();
  }

  void setCurrentView(String view) {
    _currentView = view;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setComparisonCategories(String category1, String category2) {
    _comparisonCategory1 = category1;
    _comparisonCategory2 = category2;
    notifyListeners();
  }

  void clearComparisonCategories() {
    _comparisonCategory1 = null;
    _comparisonCategory2 = null;
    notifyListeners();
  }

  void addTimeline(Timeline timeline) {
    _timelines.add(timeline);
    _saveData();
    notifyListeners();
  }

  void updateTimeline(Timeline timeline) {
    final index = _timelines.indexWhere((t) => t.id == timeline.id);
    if (index != -1) {
      _timelines[index] = timeline;
      _saveData();
      notifyListeners();
    }
  }

  void deleteTimeline(String timelineId) {
    _timelines.removeWhere((t) => t.id == timelineId);
    _selectedTimelines.removeWhere((t) => t.id == timelineId);
    _saveData();
    notifyListeners();
  }

  void toggleTimelineSelection(Timeline timeline) {
    if (_selectedTimelines.contains(timeline)) {
      _selectedTimelines.remove(timeline);
    } else {
      _selectedTimelines.add(timeline);
    }
    notifyListeners();
  }

  void selectAllTimelines() {
    _selectedTimelines = List.from(_timelines);
    notifyListeners();
  }

  void clearSelection() {
    _selectedTimelines.clear();
    notifyListeners();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timelinesJson = prefs.getString('timelines');
      if (timelinesJson != null) {
        final List<dynamic> decoded = json.decode(timelinesJson);
        _timelines = decoded.map((t) => Timeline.fromJson(t)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading timelines: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timelinesJson = json.encode(_timelines.map((t) => t.toJson()).toList());
      await prefs.setString('timelines', timelinesJson);
    } catch (e) {
      debugPrint('Error saving timelines: $e');
    }
  }

  void _loadSampleData() {
    if (_timelines.isEmpty) {
      final sampleTimelines = [
        Timeline(
          id: '1',
          name: 'World Wars',
          description: 'Major events of World War I and II',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          events: [
            TimelineEvent(
              id: '1',
              title: 'World War I Begins',
              description: 'The assassination of Archduke Franz Ferdinand triggers the start of World War I',
              date: DateTime(1914, 6, 28),
              category: 'War',
              isImportant: true,
              tags: ['WWI', 'assassination', 'Austria-Hungary'],
            ),
            TimelineEvent(
              id: '2',
              title: 'Treaty of Versailles',
              description: 'The peace treaty that ended World War I between Germany and the Allied Powers',
              date: DateTime(1919, 6, 28),
              category: 'Politics',
              isImportant: true,
              tags: ['WWI', 'treaty', 'peace'],
            ),
            TimelineEvent(
              id: '3',
              title: 'World War II Begins',
              description: 'Germany invades Poland, marking the beginning of World War II',
              date: DateTime(1939, 9, 1),
              category: 'War',
              isImportant: true,
              tags: ['WWII', 'invasion', 'Germany', 'Poland'],
            ),
            TimelineEvent(
              id: '4',
              title: 'D-Day Normandy Landings',
              description: 'Allied forces land in Normandy, opening the Western Front in Europe',
              date: DateTime(1944, 6, 6),
              category: 'War',
              isImportant: true,
              tags: ['WWII', 'D-Day', 'Normandy', 'Allied'],
            ),
          ],
        ),
        Timeline(
          id: '2',
          name: 'Space Exploration',
          description: 'Key milestones in space exploration',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          events: [
            TimelineEvent(
              id: '5',
              title: 'Sputnik 1 Launch',
              description: 'Soviet Union launches the first artificial satellite',
              date: DateTime(1957, 10, 4),
              category: 'Science',
              isImportant: true,
              tags: ['space', 'satellite', 'Soviet Union'],
            ),
            TimelineEvent(
              id: '6',
              title: 'First Human in Space',
              description: 'Yuri Gagarin becomes the first human to travel to space',
              date: DateTime(1961, 4, 12),
              category: 'Science',
              isImportant: true,
              tags: ['space', 'human', 'Gagarin', 'Soviet Union'],
            ),
            TimelineEvent(
              id: '7',
              title: 'Moon Landing',
              description: 'Apollo 11 mission successfully lands the first humans on the Moon',
              date: DateTime(1969, 7, 20),
              category: 'Science',
              isImportant: true,
              tags: ['space', 'moon', 'Apollo', 'NASA'],
            ),
          ],
        ),
      ];

      _timelines = sampleTimelines;
      _selectedTimelines = [sampleTimelines[0]]; // Select first timeline by default
      _saveData();
      notifyListeners();
    }
  }
}

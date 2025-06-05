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
    events.sort((a, b) => a.startDate.compareTo(b.startDate));
    return events;
  }

  // Get filtered events based on search query
  List<TimelineEvent> get filteredEvents {
    if (_searchQuery.isEmpty) return allEvents;
    return allEvents.where((event) {
      return event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          event.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.tags.any(
            (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
          );
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
      final timelinesJson = json.encode(
        _timelines.map((t) => t.toJson()).toList(),
      );
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
              title: 'World War I',
              description:
                  'The Great War that began with the assassination of Archduke Franz Ferdinand and involved major world powers',
              startDate: DateTime(1914, 7, 28),
              endDate: DateTime(1918, 11, 11),
              category: 'War',
              isImportant: true,
              tags: ['WWI', 'Great War', 'global conflict', 'Austria-Hungary'],
            ),
            TimelineEvent(
              id: '2',
              title: 'Battle of Verdun',
              description:
                  'One of the longest and most devastating battles of WWI between French and German forces',
              startDate: DateTime(1916, 2, 21),
              endDate: DateTime(1916, 12, 18),
              category: 'War',
              isImportant: true,
              tags: ['WWI', 'battle', 'France', 'Germany', 'Verdun'],
            ),
            TimelineEvent(
              id: '3',
              title: 'Treaty of Versailles',
              description:
                  'The peace treaty that officially ended World War I between Germany and the Allied Powers',
              startDate: DateTime(1919, 6, 28),
              category: 'Politics',
              isImportant: true,
              tags: ['WWI', 'treaty', 'peace', 'Germany', 'reparations'],
            ),
            TimelineEvent(
              id: '4',
              title: 'World War II',
              description:
                  'Global war that began with Germany\'s invasion of Poland and ended with Allied victory',
              startDate: DateTime(1939, 9, 1),
              endDate: DateTime(1945, 9, 2),
              category: 'War',
              isImportant: true,
              tags: ['WWII', 'global war', 'Holocaust', 'Allied Powers'],
            ),
            TimelineEvent(
              id: '5',
              title: 'Pearl Harbor Attack',
              description:
                  'Surprise military strike by Japan against the US naval base, bringing America into WWII',
              startDate: DateTime(1941, 12, 7),
              category: 'War',
              isImportant: true,
              tags: ['WWII', 'Pearl Harbor', 'Japan', 'USA', 'Pacific War'],
            ),
            TimelineEvent(
              id: '6',
              title: 'D-Day Normandy Landings',
              description:
                  'Allied invasion of Nazi-occupied Western Europe, opening the Western Front',
              startDate: DateTime(1944, 6, 6),
              endDate: DateTime(1944, 8, 30),
              category: 'War',
              isImportant: true,
              tags: ['WWII', 'D-Day', 'Normandy', 'Allied', 'invasion'],
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
              id: '7',
              title: 'Sputnik 1 Launch',
              description:
                  'Soviet Union launches the first artificial satellite, beginning the Space Age',
              startDate: DateTime(1957, 10, 4),
              category: 'Science',
              isImportant: true,
              tags: ['space', 'satellite', 'Soviet Union', 'Space Age'],
            ),
            TimelineEvent(
              id: '8',
              title: 'First Human in Space',
              description:
                  'Yuri Gagarin becomes the first human to travel to space aboard Vostok 1',
              startDate: DateTime(1961, 4, 12),
              category: 'Science',
              isImportant: true,
              tags: ['space', 'human spaceflight', 'Gagarin', 'Vostok', 'Soviet Union'],
            ),
            TimelineEvent(
              id: '9',
              title: 'Apollo 11 Moon Landing',
              description:
                  'First successful crewed mission to land on the Moon with Neil Armstrong and Buzz Aldrin',
              startDate: DateTime(1969, 7, 16),
              endDate: DateTime(1969, 7, 24),
              category: 'Science',
              isImportant: true,
              tags: ['space', 'moon landing', 'Apollo', 'NASA', 'Armstrong', 'Aldrin'],
            ),
            TimelineEvent(
              id: '10',
              title: 'Space Shuttle Program',
              description:
                  'NASA\'s reusable spacecraft program that operated for 30 years',
              startDate: DateTime(1981, 4, 12),
              endDate: DateTime(2011, 7, 21),
              category: 'Science',
              isImportant: true,
              tags: ['space shuttle', 'NASA', 'reusable spacecraft', 'ISS'],
            ),
            TimelineEvent(
              id: '11',
              title: 'International Space Station',
              description:
                  'Multi-national collaborative project and habitable artificial satellite in low Earth orbit',
              startDate: DateTime(1998, 11, 20),
              endDate: DateTime(2031, 1, 1), // Planned end date
              category: 'Science',
              isImportant: true,
              tags: ['ISS', 'space station', 'international cooperation', 'orbital laboratory'],
            ),
          ],
        ),
        Timeline(
          id: '3',
          name: 'Technology Revolution',
          description: 'Major technological breakthroughs that changed the world',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          events: [
            TimelineEvent(
              id: '12',
              title: 'Internet Creation',
              description:
                  'ARPANET, the precursor to the modern internet, was established connecting universities and research institutions',
              startDate: DateTime(1969, 10, 29),
              category: 'Technology',
              isImportant: true,
              tags: ['internet', 'ARPANET', 'networking', 'communication'],
            ),
            TimelineEvent(
              id: '13',
              title: 'Personal Computer Revolution',
              description:
                  'Apple II launch marked the beginning of personal computing for everyday users',
              startDate: DateTime(1977, 4, 16),
              category: 'Technology',
              isImportant: true,
              tags: ['personal computer', 'Apple II', 'computing', 'microprocessor'],
            ),
            TimelineEvent(
              id: '14',
              title: 'World Wide Web',
              description:
                  'Tim Berners-Lee created the first web browser and web server, making the internet accessible to everyone',
              startDate: DateTime(1990, 12, 20),
              category: 'Technology',
              isImportant: true,
              tags: ['WWW', 'web browser', 'Tim Berners-Lee', 'hypertext'],
            ),
            TimelineEvent(
              id: '15',
              title: 'Smartphone Era',
              description:
                  'Apple iPhone launch revolutionized mobile computing and communication',
              startDate: DateTime(2007, 1, 9),
              category: 'Technology',
              isImportant: true,
              tags: ['smartphone', 'iPhone', 'mobile computing', 'touchscreen'],
            ),
            TimelineEvent(
              id: '16',
              title: 'AI and Machine Learning Boom',
              description:
                  'ChatGPT and other large language models brought AI to mainstream use',
              startDate: DateTime(2022, 11, 30),
              category: 'Technology',
              isImportant: true,
              tags: ['AI', 'machine learning', 'ChatGPT', 'LLM', 'OpenAI'],
            ),
          ],
        ),
        Timeline(
          id: '4',
          name: 'Medical Breakthroughs',
          description: 'Revolutionary discoveries and treatments in medicine',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          events: [
            TimelineEvent(
              id: '17',
              title: 'Discovery of Penicillin',
              description:
                  'Alexander Fleming discovered the first true antibiotic, revolutionizing treatment of bacterial infections',
              startDate: DateTime(1928, 9, 3),
              category: 'Medicine',
              isImportant: true,
              tags: ['penicillin', 'antibiotic', 'Fleming', 'bacteria', 'infection'],
            ),
            TimelineEvent(
              id: '18',
              title: 'First Polio Vaccine',
              description:
                  'Jonas Salk developed the first successful polio vaccine, leading to near-eradication of the disease',
              startDate: DateTime(1955, 4, 12),
              category: 'Medicine',
              isImportant: true,
              tags: ['polio vaccine', 'Salk', 'immunization', 'public health'],
            ),
            TimelineEvent(
              id: '19',
              title: 'First Heart Transplant',
              description:
                  'Christiaan Barnard performed the first successful human-to-human heart transplant in South Africa',
              startDate: DateTime(1967, 12, 3),
              category: 'Medicine',
              isImportant: true,
              tags: ['heart transplant', 'Barnard', 'surgery', 'organ transplant'],
            ),
            TimelineEvent(
              id: '20',
              title: 'Human Genome Project',
              description:
                  'International effort to sequence and map all human genes, revolutionizing personalized medicine',
              startDate: DateTime(1990, 10, 1),
              endDate: DateTime(2003, 4, 14),
              category: 'Medicine',
              isImportant: true,
              tags: ['genome', 'DNA sequencing', 'genetics', 'personalized medicine'],
            ),
            TimelineEvent(
              id: '21',
              title: 'COVID-19 mRNA Vaccines',
              description:
                  'Rapid development of mRNA vaccines demonstrated new possibilities in vaccine technology',
              startDate: DateTime(2020, 12, 11),
              category: 'Medicine',
              isImportant: true,
              tags: ['COVID-19', 'mRNA vaccine', 'Pfizer', 'Moderna', 'pandemic'],
            ),
          ],
        ),
      ];

      _timelines = sampleTimelines;
      _selectedTimelines = [
        sampleTimelines[0],
      ]; // Select first timeline by default
      _saveData();
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/category_selection_view.dart';
import 'providers/timeline_provider.dart';
import 'widgets/chrono_comparison_view.dart'; // Added import

void main() {
  runApp(const ChronoHistoryApp());
}

class ChronoHistoryApp extends StatelessWidget {
  const ChronoHistoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TimelineProvider(),
      child: MaterialApp(
        title: 'ChronoHistory',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        home: Consumer<TimelineProvider>(
          builder: (context, provider, child) {
            if (provider.currentView == 'chrono_comparison') {
              return const ChronoComparisonView();
            } else {
              return const CategorySelectionView();
            }
          },
        ),
      ),
    );
  }
}

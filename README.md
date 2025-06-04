# ChronoHistory: A Timeline Comparison App

## Description

ChronoHistory is a Flutter application designed to allow users to select various historical or thematic categories and visually compare their timelines. The app aims to provide an engaging and informative way to explore how different sets of events overlap and relate to each other over time.

## Features

* **Category Selection:** Users can browse and select from a list of available categories (e.g., "Ancient Civilizations," "Scientific Discoveries," "World Wars").
* **Timeline Comparison View:** Selected categories are displayed as timelines, allowing users to see concurrent events.
* **Interactive Timeline:** Users can interact with the timeline (zoom, pan - though scrolling is currently under active redesign).
* **Event Details:** Tapping on an event on the timeline can show more detailed information (functionality partially implemented).
* **Responsive UI:** The application is designed to adapt to different screen sizes, particularly for mobile devices.

## Tech Stack

* **Framework:** Flutter
* **Language:** Dart
* **State Management:** Provider package

## Getting Started

This project is a Flutter application. To get started:

1. **Ensure Flutter is installed:** Follow the [official Flutter installation guide](https://docs.flutter.dev/get-started/install).

2. **Clone the repository:**

   ```bash
   git clone <repository-url>
   cd chrono_history
   ```

3. **Install dependencies:**

   ```bash
   flutter pub get
   ```

4. **Run the application:**

   ```bash
   flutter run
   ```

## Current Status & Known Issues

The application is currently under active development. Key areas of focus include:

* **Redesign of `ChronoComparisonView`:** The current "orbiting circles" metaphor for timelines in `chrono_comparison_view.dart` has been found to be confusing. This view, along with its `TimelineCylinderPainter`, is being actively refactored to display timelines in a clearer, linear, and vertically scrollable manner.
* **Scrolling Implementation:** Implementing intuitive and effective scrolling for the timelines is a high priority.
* **UI/UX Refinements:** Continuous improvements are being made to the user interface and experience across the app.

## Project Structure (Key Components)

* `lib/main.dart`: Entry point of the application, handles basic navigation.
* `lib/widgets/category_selection_view.dart`: UI for selecting categories to compare.
* `lib/widgets/chrono_comparison_view.dart`: UI for displaying and comparing timelines (currently undergoing major redesign).
* `lib/providers/timeline_provider.dart`: Manages the state for selected timelines and events.
* `lib/models/timeline_event.dart`: Data model for timeline events.

## Future Scope (Potential Enhancements)

* More detailed event information and multimedia content.
* Advanced filtering and search capabilities within timelines.
* User accounts and saved timeline comparisons.
* Wider range of historical categories and data sources.

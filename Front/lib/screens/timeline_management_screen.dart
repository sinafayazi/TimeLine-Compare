import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timeline_provider.dart';
import '../models/timeline_event.dart';

class TimelineManagementScreen extends StatelessWidget {
  const TimelineManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
	return Scaffold(
	  appBar: AppBar(
		title: const Text('Timeline Management'),
		actions: [
		  IconButton(
			icon: const Icon(Icons.add),
			onPressed: () => _showCreateTimelineDialog(context),
			tooltip: 'Create Timeline',
		  ),
		],
	  ),
	  body: Consumer<TimelineProvider>(
		builder: (context, provider, child) {
		  return Column(
			children: [
			  // Selection controls
			  Container(
				padding: const EdgeInsets.all(16),
				child: Row(
				  children: [
					Text(
					  'Select timelines to compare:',
					  style: Theme.of(context).textTheme.titleMedium,
					),
					const Spacer(),
					TextButton(
					  onPressed: provider.timelines.isEmpty
						  ? null
						  : () => provider.selectAllTimelines(),
					  child: const Text('Select All'),
					),
					TextButton(
					  onPressed: provider.selectedTimelines.isEmpty
						  ? null
						  : () => provider.clearSelection(),
					  child: const Text('Clear'),
					),
				  ],
				),
			  ),
			  // Timeline list
			  Expanded(
				child: provider.timelines.isEmpty
					? const Center(
						child: Text('No timelines created yet'),
					  )
					: ListView.builder(
						itemCount: provider.timelines.length,
						itemBuilder: (context, index) {
						  final timeline = provider.timelines[index];
						  final isSelected = provider.selectedTimelines.contains(timeline);
						  
						  return Card(
							margin: const EdgeInsets.symmetric(
							  horizontal: 16,
							  vertical: 4,
							),
							child: CheckboxListTile(
							  value: isSelected,
							  onChanged: (_) => provider.toggleTimelineSelection(timeline),
							  title: Text(
								timeline.name,
								style: const TextStyle(fontWeight: FontWeight.bold),
							  ),
							  subtitle: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
								  Text(timeline.description),
								  const SizedBox(height: 4),
								  Text(
									'${timeline.events.length} events',
									style: Theme.of(context).textTheme.bodySmall,
								  ),
								],
							  ),
							  secondary: PopupMenuButton(
								itemBuilder: (context) => [
								  const PopupMenuItem(
									value: 'edit',
									child: Text('Edit'),
								  ),
								  const PopupMenuItem(
									value: 'delete',
									child: Text('Delete'),
								  ),
								],
								onSelected: (value) {
								  if (value == 'edit') {
									_showEditTimelineDialog(context, timeline);
								  } else if (value == 'delete') {
									_showDeleteConfirmation(context, provider, timeline);
								  }
								},
							  ),
							),
						  );
						},
					  ),
			  ),
			],
		  );
		},
	  ),
	);
  }

  void _showCreateTimelineDialog(BuildContext context) {
	final nameController = TextEditingController();
	final descriptionController = TextEditingController();

	showDialog(
	  context: context,
	  builder: (context) => AlertDialog(
		title: const Text('Create Timeline'),
		content: Column(
		  mainAxisSize: MainAxisSize.min,
		  children: [
			TextField(
			  controller: nameController,
			  decoration: const InputDecoration(
				labelText: 'Timeline Name',
				border: OutlineInputBorder(),
			  ),
			),
			const SizedBox(height: 16),
			TextField(
			  controller: descriptionController,
			  decoration: const InputDecoration(
				labelText: 'Description',
				border: OutlineInputBorder(),
			  ),
			  maxLines: 3,
			),
		  ],
		),
		actions: [
		  TextButton(
			onPressed: () => Navigator.pop(context),
			child: const Text('Cancel'),
		  ),
		  ElevatedButton(
			onPressed: () {
			  if (nameController.text.isNotEmpty) {
				final timeline = Timeline(
				  id: DateTime.now().millisecondsSinceEpoch.toString(),
				  name: nameController.text,
				  description: descriptionController.text,
				  events: [],
				  createdAt: DateTime.now(),
				  updatedAt: DateTime.now(),
				);
				
				context.read<TimelineProvider>().addTimeline(timeline);
				Navigator.pop(context);
			  }
			},
			child: const Text('Create'),
		  ),
		],
	  ),
	);
  }

  void _showEditTimelineDialog(BuildContext context, Timeline timeline) {
	final nameController = TextEditingController(text: timeline.name);
	final descriptionController = TextEditingController(text: timeline.description);

	showDialog(
	  context: context,
	  builder: (context) => AlertDialog(
		title: const Text('Edit Timeline'),
		content: Column(
		  mainAxisSize: MainAxisSize.min,
		  children: [
			TextField(
			  controller: nameController,
			  decoration: const InputDecoration(
				labelText: 'Timeline Name',
				border: OutlineInputBorder(),
			  ),
			),
			const SizedBox(height: 16),
			TextField(
			  controller: descriptionController,
			  decoration: const InputDecoration(
				labelText: 'Description',
				border: OutlineInputBorder(),
			  ),
			  maxLines: 3,
			),
		  ],
		),
		actions: [
		  TextButton(
			onPressed: () => Navigator.pop(context),
			child: const Text('Cancel'),
		  ),
		  ElevatedButton(
			onPressed: () {
			  if (nameController.text.isNotEmpty) {
				final updatedTimeline = timeline.copyWith(
				  name: nameController.text,
				  description: descriptionController.text,
				  updatedAt: DateTime.now(),
				);
				
				context.read<TimelineProvider>().updateTimeline(updatedTimeline);
				Navigator.pop(context);
			  }
			},
			child: const Text('Save'),
		  ),
		],
	  ),
	);
  }

  void _showDeleteConfirmation(BuildContext context, TimelineProvider provider, Timeline timeline) {
	showDialog(
	  context: context,
	  builder: (context) => AlertDialog(
		title: const Text('Delete Timeline'),
		content: Text('Are you sure you want to delete "${timeline.name}"?'),
		actions: [
		  TextButton(
			onPressed: () => Navigator.pop(context),
			child: const Text('Cancel'),
		  ),
		  ElevatedButton(
			onPressed: () {
			  provider.deleteTimeline(timeline.id);
			  Navigator.pop(context);
			},
			style: ElevatedButton.styleFrom(
			  backgroundColor: Theme.of(context).colorScheme.error,
			  foregroundColor: Theme.of(context).colorScheme.onError,
			),
			child: const Text('Delete'),
		  ),
		],
	  ),
	);
  }
}

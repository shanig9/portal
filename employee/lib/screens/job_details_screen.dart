import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../services/records_service.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  EmployeeController get state => widget.state;
  final _records = RecordsService();
  bool _submitting = false;
  Future<void> _apply(String title, String company, String location) async {
    setState(() => _submitting = true);
    try {
      final documents = await _records.list('documents');
      if (!mounted) return;
      if (documents.isEmpty) {
        EmployeeUi(
          context,
          state,
        ).notice('Upload a PDF resume before applying.');
        state.open('Resume');
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit application?'),
          content: Text(
            'Apply for $title using ${documents.first['filename']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _records.apply(
        title: title,
        company: company,
        location: location,
        documentId: documents.first['id'] as String,
      );
      if (!mounted) return;
      state.update(() => state.applied.add(title));
      EmployeeUi(context, state).notice('Application submitted and saved.');
    } catch (error) {
      if (mounted) {
        EmployeeUi(
          context,
          state,
        ).notice(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    final j = state.jobs.firstWhere(
      (e) => e.$1 == state.selectedJob,
      orElse: () => state.jobs.first,
    );
    return ui.list([
      ui.panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ui.avatar(j.$2.substring(0, 1), 32),
            ui.heading(j.$1),
            Text(j.$2),
            const SizedBox(height: 16),
            ui.caption('${j.$3} · ${j.$5} · ${j.$4}'),
            ui.caption('Posted 2 days ago'),
          ],
        ),
      ),
      ui.heading('About the Job'),
      const Text(
        'Join a creative, growing team. Build meaningful work, collaborate with talented people, and develop your career.',
        style: TextStyle(height: 1.7),
      ),
      ui.heading('Key Responsibilities'),
      const Text(
        '• Plan and execute projects with your team\n• Measure performance and share insights\n• Collaborate across teams\n• Bring fresh ideas and keep learning',
        style: TextStyle(height: 2),
      ),
      ui.heading('Requirements'),
      const Text(
        '• 0–2 years of relevant experience\n• Strong communication and analytical skills\n• A portfolio or examples of your work\n• Degree or equivalent practical experience',
        style: TextStyle(height: 2),
      ),
      ui.heading('Skills'),
      Wrap(
        spacing: 8,
        children: [
          'Communication',
          'Analytics',
          'Teamwork',
        ].map((s) => Chip(label: Text(s))).toList(),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        label: Text(
          _submitting
              ? 'Submitting...'
              : state.applied.contains(j.$1)
              ? 'Application submitted'
              : 'Apply Now',
        ),
        onPressed: _submitting || state.applied.contains(j.$1)
            ? null
            : () => _apply(j.$1, j.$2, j.$3),
        icon: const Icon(Icons.send),
      ),
      TextButton(
        onPressed: () => state.open('My Applications'),
        child: const Text('View My Applications'),
      ),
    ]);
  }
}

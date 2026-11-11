import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';

class JobDetailsScreen extends StatelessWidget {
  const JobDetailsScreen({super.key, required this.state});
  final EmployeeController state;
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
      ui.button(
        state.applied.contains(j.$1) ? 'Application submitted' : 'Apply Now',
        () {
          state.update(() => state.applied.add(j.$1));
          ui.notice('Application added to the preview');
        },
        Icons.send,
      ),
      TextButton(
        onPressed: () => state.open('My Applications'),
        child: const Text('View My Applications'),
      ),
    ]);
  }
}

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    final entries = {
      ...state.applied,
      'Flutter Developer',
      'UI/UX Designer',
      'Digital Marketing Executive',
      'Backend Developer',
      'QA Engineer',
    }.toList();
    return ui.list([
      ui.heading('Track your next opportunity'),
      ui.caption('All your applications, together.'),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        children: ['All', 'In Progress', 'Shortlisted', 'Others']
            .map(
              (e) => ChoiceChip(
                label: Text(e),
                selected: state.applicationFilter == e,
                onSelected: (_) =>
                    state.update(() => state.applicationFilter = e),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      ...entries
          .asMap()
          .entries
          .where(
            (e) =>
                state.applicationFilter == 'All' ||
                state.applicationFilter == 'Shortlisted' && e.key == 0 ||
                state.applicationFilter == 'In Progress' && e.key == 1 ||
                state.applicationFilter == 'Others' && e.key > 1,
          )
          .map(
            (e) => ui.panel(
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ui.avatar('T'),
                title: Text(
                  e.value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Career Connect · Pune\n${state.applied.contains(e.value) ? 'Applied just now' : ['Shortlisted', 'Under Review', 'Interview Scheduled', 'Not Selected', 'Application Closed'][e.key % 5]}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  state.selectedJob = e.value;
                  state.open('Job Details');
                },
              ),
            ),
          ),
    ]);
  }
}

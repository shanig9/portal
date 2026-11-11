import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../theme.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    final visible = state.jobs.where(
      (j) =>
          (state.page != 'Saved Jobs' || state.saved.contains(j.$1)) &&
          '${j.$1} ${j.$2} ${j.$3}'.toLowerCase().contains(
            state.query.toLowerCase(),
          ) &&
          (state.filter == 'All jobs' ||
              state.filter == j.$5 ||
              state.filter == j.$3),
    );
    return ui.list([
      TextFormField(
        initialValue: state.query,
        onChanged: (v) => state.update(() => state.query = v),
        decoration: const InputDecoration(
          hintText: 'Search jobs, companies, or skills…',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: ['All jobs', 'Full Time', 'Part Time', 'Remote', 'Internship']
            .map(
              (e) => ChoiceChip(
                label: Text(e),
                selected: state.filter == e,
                onSelected: (_) => state.update(() => state.filter = e),
              ),
            )
            .toList(),
      ),
      Row(
        children: [
          Expanded(child: ui.heading('Recommended for you')),
          IconButton(
            tooltip: 'Change job layout',
            onPressed: () => state.update(() => state.compact = !state.compact),
            icon: Icon(
              state.compact
                  ? Icons.view_agenda_outlined
                  : Icons.view_list_outlined,
            ),
          ),
        ],
      ),
      if (visible.isEmpty)
        ui.panel(
          const Text('No jobs found. Try another search or save a job.'),
        ),
      ...visible.map(
        (j) => ui.panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ui.avatar(j.$2.substring(0, 1)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        state.selectedJob = j.$1;
                        state.open('Job Details');
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            j.$1,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ui.caption(j.$2),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Save job',
                    onPressed: () => state.update(() {
                      state.saved.contains(j.$1)
                          ? state.saved.remove(j.$1)
                          : state.saved.add(j.$1);
                    }),
                    icon: Icon(
                      state.saved.contains(j.$1)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ui.caption('${j.$3} · ${j.$5} · 0–2 years'),
              if (!state.compact)
                Wrap(
                  spacing: 6,
                  children: [
                    'Communication',
                    'Teamwork',
                  ].map((s) => Chip(label: Text(s))).toList(),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      j.$4,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: blue,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      state.selectedJob = j.$1;
                      state.open('Job Details');
                    },
                    child: Text(
                      state.applied.contains(j.$1) ? 'Applied' : 'View & Apply',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

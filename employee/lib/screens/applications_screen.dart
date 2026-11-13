import 'package:flutter/material.dart';

import '../services/records_service.dart';
import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final _service = RecordsService();
  late Future<List<Map<String, dynamic>>> _applications = _service.list(
    'applications',
  );
  static const labels = {
    'submitted': 'Submitted',
    'under_review': 'Under Review',
    'shortlisted': 'Shortlisted',
    'interview': 'Interview Scheduled',
    'rejected': 'Not Selected',
    'closed': 'Closed',
  };
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, widget.state);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _applications,
      builder: (context, snapshot) => ui.list([
        ui.heading('Track your next opportunity'),
        Row(
          children: [
            const Expanded(child: Text('Your saved application records')),
            IconButton(
              tooltip: 'Refresh applications',
              onPressed: () =>
                  setState(() => _applications = _service.list('applications')),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (snapshot.connectionState != ConnectionState.done)
          const Center(child: CircularProgressIndicator())
        else if (snapshot.hasError)
          Text(snapshot.error.toString().replaceFirst('Exception: ', ''))
        else if (snapshot.data!.isEmpty)
          const Text('No applications yet. Apply for a job to see it here.')
        else
          ...snapshot.data!.map(
            (item) => ui.panel(
              ListTile(
                title: Text(item['job_title'] as String),
                subtitle: Text(
                  '${item['company']} - ${item['location']}\n${labels[item['status']] ?? item['status']}',
                ),
                isThreeLine: true,
              ),
            ),
          ),
      ]),
    );
  }
}

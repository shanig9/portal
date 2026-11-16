import 'package:material_ui/material_ui.dart';

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
  Future<void> _apply(
    String title,
    String company,
    String location,
    String jobId,
  ) async {
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
        jobId: jobId,
        title: title,
        company: company,
        location: location,
        documentId: documents.first['id'] as String,
      );
      if (!mounted) return;
      state.update(() => state.applied.add(jobId.isEmpty ? title : jobId));
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
    if (state.jobs.isEmpty) {
      return const Center(child: Text('This opening is no longer available.'));
    }
    final j = state.jobs.firstWhere(
      (e) => state.selectedJobId.isNotEmpty
          ? e.$6 == state.selectedJobId
          : e.$1 == state.selectedJob,
      orElse: () => state.jobs.first,
    );
    if (state.selectedJobId.isNotEmpty && j.$6 != state.selectedJobId) {
      return const Center(child: Text('This opening is no longer available.'));
    }
    final details = state.jobDetails[j.$6]?['details'] as Map<String, dynamic>?;
    final applicationKey = j.$6.isEmpty ? j.$1 : j.$6;
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
            ui.caption('Published opening'),
          ],
        ),
      ),
      ui.heading('About the Job'),
      Text(
        details?['description'] as String? ??
            'See the recruiter for further details.',
        style: const TextStyle(height: 1.7),
      ),
      ui.heading('Requirements'),
      Text(
        '${details?['experience'] ?? 'Experience: contact recruiter'}\n${details?['qualification'] ?? 'Qualification: contact recruiter'}',
        style: const TextStyle(height: 2),
      ),
      ui.heading('Skills'),
      Wrap(
        spacing: 8,
        children: ((details?['skills'] as List?) ?? const <String>[])
            .whereType<String>()
            .map((s) => Chip(label: Text(s)))
            .toList(),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        label: Text(
          _submitting
              ? 'Submitting...'
              : state.applied.contains(applicationKey)
              ? 'Application submitted'
              : 'Apply Now',
        ),
        onPressed: _submitting || state.applied.contains(applicationKey)
            ? null
            : () => _apply(j.$1, j.$2, j.$3, j.$6),
        icon: const Icon(Icons.send),
      ),
      TextButton(
        onPressed: () => state.open('My Applications'),
        child: const Text('View My Applications'),
      ),
    ]);
  }
}

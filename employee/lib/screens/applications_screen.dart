import 'package:material_ui/material_ui.dart';
import 'package:career_connect_chat/career_connect_chat.dart';

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
  bool _openingChat = false;
  Future<void> _chat(Map<String, dynamic> application) async {
    setState(() => _openingChat = true);
    try {
      final id = await _service.chat(application['id'] as String);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CareerConversation(
            chatId: id,
            title: application['job_title'] as String,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  final _service = RecordsService();
  Future<List<Map<String, dynamic>>> _load() async {
    final items = await _service.list('applications');
    if (mounted) {
      widget.state.update(
        () => widget.state.applied.addAll(
          items.map((item) => item['job_key']).whereType<String>(),
        ),
      );
    }
    return items;
  }

  late Future<List<Map<String, dynamic>>> _applications = _load();
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
              onPressed: () => setState(() => _applications = _load()),
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
                trailing: IconButton(
                  tooltip: 'Message HR',
                  onPressed: _openingChat ? null : () => _chat(item),
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

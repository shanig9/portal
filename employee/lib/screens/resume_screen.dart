import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/records_service.dart';
import '../state/employee_controller.dart';
import '../widgets/profile_setup_scaffold.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final _service = RecordsService();
  late Future<List<Map<String, dynamic>>> _documents = _service.list(
    'documents',
  );
  bool _busy = false;
  void _notice(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _upload() async {
    setState(() => _busy = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (file == null) return;
      final size = await file.length();
      if (size == null || size > 10 * 1024 * 1024) {
        throw Exception('Choose a PDF up to 10 MB.');
      }
      final document = await _service.upload(
        await file.readAsBytes(),
        file.name,
      );
      if (!mounted) return;
      widget.state.update(() {
        widget.state.resume = true;
        widget.state.data['Resume filename'] = document['filename'] as String;
      });
      setState(() => _documents = _service.list('documents'));
      _notice('Document saved securely.');
    } catch (error) {
      _notice(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String id) async {
    setState(() => _busy = true);
    try {
      final url = await _service.download(id);
      if (!await launchUrl(url, webOnlyWindowName: '_self')) {
        throw Exception('Unable to open the document.');
      }
    } catch (error) {
      _notice(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ProfileSetupScaffold(
    state: widget.state,
    index: 5,
    children: [
      const Text(
        'Upload PDF resumes and supporting documents, up to 10 MB each. Your latest document is used when applying.',
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _busy ? null : _upload,
        icon: const Icon(Icons.upload_file),
        label: Text(_busy ? 'Please wait...' : 'Upload PDF document'),
      ),
      const SizedBox(height: 16),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _documents,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Column(
              children: [
                Text(snapshot.error.toString().replaceFirst('Exception: ', '')),
                TextButton(
                  onPressed: () =>
                      setState(() => _documents = _service.list('documents')),
                  child: const Text('Retry'),
                ),
              ],
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Text('No documents uploaded yet.');
          return Column(
            children: items
                .map(
                  (document) => ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: Text(document['filename'] as String),
                    subtitle: Text(
                      '${((document['size_bytes'] as num) / 1024).ceil()} KB',
                    ),
                    trailing: IconButton(
                      tooltip: 'Open document',
                      onPressed: _busy
                          ? null
                          : () => _open(document['id'] as String),
                      icon: const Icon(Icons.open_in_new),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

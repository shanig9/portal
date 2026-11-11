import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import 'employee_ui.dart';

void showCreatePost(BuildContext context, EmployeeController state) {
  final ui = EmployeeUi(context, state);
  String text = '';
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(ctx).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: ui.heading('Create Post')),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            ListTile(
              leading: ui.avatar(),
              title: const Text('Rohit Deshmukh'),
              subtitle: const Text('Job Seeker'),
            ),
            TextField(
              maxLines: 4,
              onChanged: (v) => text = v,
              decoration: const InputDecoration(
                hintText:
                    'Share your update, achievement, or job search journey…',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['Photo', 'Video', 'Reel', 'Document']
                  .map(
                    (e) => ActionChip(
                      label: Text(e),
                      avatar: const Icon(Icons.add, size: 16),
                      onPressed: () => ui.notice(
                        '$e attachments need a connected upload service',
                      ),
                    ),
                  )
                  .toList(),
            ),
            ...['Location', 'Tag People', 'Hashtags'].map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(decoration: InputDecoration(labelText: e)),
              ),
            ),
            const SizedBox(height: 16),
            ui.button('Post', () {
              if (text.trim().isEmpty) {
                ui.notice('Write something to post');
                return;
              }
              state.update(() => state.posts.insert(0, text.trim()));
              Navigator.pop(ctx);
            }, Icons.send),
          ],
        ),
      ),
    ),
  );
}

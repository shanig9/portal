import '../widgets/employee_icon.dart';

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ui.list([
      ui.panel(
        Column(
          children: [
            Row(
              children: [
                ui.avatar('RD', 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ui.heading(state.data['Full Name'] ?? 'Rohit Deshmukh'),
                      ui.caption('Digital Marketing Executive'),
                      ui.caption('Pune, Maharashtra · 2 years experience'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const LinearProgressIndicator(value: .9, minHeight: 6),
            ui.caption('Profile completion · 90%'),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => state.open('Resume'),
                  child: const Text('My Resume'),
                ),
                TextButton(
                  onPressed: () => state.open('Personal Details'),
                  child: const Text('Edit Profile'),
                ),
                TextButton(
                  onPressed: () => state.open('Candidate Details'),
                  child: const Text('Preview'),
                ),
              ],
            ),
          ],
        ),
      ),
      ...[...state.steps, 'My Applications', 'Saved Jobs', 'Refer & Earn'].map(
        (name) => Card(
          margin: const EdgeInsets.only(bottom: 7),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: EmployeeIcon(ui.icon(name), color: blue),
              title: Text(name),
              trailing: const EmployeeIcon(Icons.chevron_right),
              onTap: () => state.open(name),
            ),
          ),
        ),
      ),
      ui.button(
        'Upload / Update Resume',
        () => state.open('Resume'),
        Icons.upload_file,
      ),
      TextButton(
        onPressed: () async {
          if (state.account == null) {
            state.open('Login');
            return;
          }
          try {
            await state.signOut();
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
            }
          }
        },
        child: Text(
          state.account == null ? 'Sign in / Create account' : 'Sign out',
        ),
      ),
    ]);
  }
}

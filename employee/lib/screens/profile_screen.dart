import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../theme.dart';

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
            ui.avatar('RD', 42),
            ui.heading(state.data['Full Name'] ?? 'Rohit Deshmukh'),
            ui.caption('Digital Marketing Executive'),
            ui.caption('Pune, Maharashtra · 2 years experience'),
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
        (name) => ui.panel(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(ui.icon(name), color: blue),
            title: Text(name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => state.open(name),
          ),
        ),
      ),
      TextButton(
        onPressed: () => state.open('Login'),
        child: const Text('Sign in / Create account'),
      ),
    ]);
  }
}

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ui.list([
      ui.heading('Notifications'),
      ui.panel(
        const ListTile(
          leading: Icon(Icons.work_outline, color: blue),
          title: Text('Welcome to Career Connect'),
          subtitle: Text(
            'Complete your profile to discover relevant opportunities.',
          ),
        ),
      ),
    ]);
  }
}

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ui.list([
      TextField(
        onChanged: (v) => state.update(() => state.data['chatQuery'] = v),
        decoration: const InputDecoration(
          hintText: 'Search messages',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 16),
      ...['Career Connect', 'ABC Technologies', 'Pune IT Solutions', 'HR Team']
          .where(
            (e) => e.toLowerCase().contains(
              (state.data['chatQuery'] ?? '').toLowerCase(),
            ),
          )
          .map(
            (e) => ui.panel(
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ui.avatar(e.substring(0, 1)),
                title: Text(
                  e,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Let’s discuss your application.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  state.chat = e;
                  state.open('Conversation');
                },
              ),
            ),
          ),
    ]);
  }
}

import '../widgets/employee_icon.dart';

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../theme.dart';

class ConversationScreen extends StatelessWidget {
  const ConversationScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return Column(
      children: [
        ListTile(
          leading: ui.avatar(state.chat.substring(0, 1)),
          title: Text(state.chat),
          subtitle: const Text('Recruitment team'),
        ),
        Expanded(
          child: ui.list([
            ui.panel(
              const Text(
                'Hello Rohit! Thank you for your interest. What would be a good time to discuss your application?',
              ),
            ),
            ...state.messages.map(
              (m) => Align(
                alignment: Alignment.centerRight,
                child: ui.panel(Text(m)),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextFormField(
            key: ValueKey(state.messages.length),
            onFieldSubmitted: (v) {
              if (v.trim().isNotEmpty) {
                state.update(() => state.messages.add(v.trim()));
              }
            },
            decoration: const InputDecoration(
              hintText: 'Type a message and press enter',
              suffixIcon: EmployeeIcon(Icons.send, color: blue),
            ),
          ),
        ),
      ],
    );
  }
}

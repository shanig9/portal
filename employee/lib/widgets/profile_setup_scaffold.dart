import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import 'employee_ui.dart';

class ProfileSetupScaffold extends StatelessWidget {
  const ProfileSetupScaffold({
    super.key,
    required this.state,
    required this.index,
    required this.children,
  });
  final EmployeeController state;
  final int index;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return Form(
      key: state.form,
      child: ui.list([
        ui.heading(
          index == 5 ? 'Upload Your Resume' : 'Make your profile stand out',
        ),
        ui.caption('Step ${index + 1}: ${state.steps[index]}'),
        const SizedBox(height: 24),
        ...children,
        const SizedBox(height: 32),
        ui.button(index == 5 ? 'Save & Complete Profile' : 'Save & Next', () {
          if (!state.form.currentState!.validate()) return;
          if (index < 5) {
            state.open(state.steps[index + 1]);
          } else {
            state.update(() {
              state.page = 'Profile';
              state.tab = 4;
              state.history.clear();
            });
            ui.notice('Profile saved for this session');
          }
        }, index == 5 ? Icons.check : Icons.arrow_forward),
        TextButton(onPressed: state.back, child: const Text('Back')),
      ]),
    );
  }
}

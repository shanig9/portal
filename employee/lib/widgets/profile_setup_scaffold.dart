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
      child: Column(
        children: [
          Expanded(
            child: ui.list([
              if (index == 5) ui.heading('Upload Your Resume'),
              ui.caption(switch (index) {
                0 => 'Add your personal details',
                1 => "Tell us what kind of job you’re looking for",
                2 => 'Add your educational details',
                3 => 'Add your work experience details',
                4 => 'Add your key skills to match relevant jobs',
                _ => 'Complete your profile and apply for jobs easily.',
              }),
              const SizedBox(height: 24),
              ...children,
            ]),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ui.button(
                  index == 5 ? 'Save & Complete Profile' : 'Save & Next',
                  () {
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
                  },
                  index == 5 ? Icons.check : Icons.arrow_forward,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

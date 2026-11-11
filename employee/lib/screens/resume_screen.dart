import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../theme.dart';
import '../widgets/profile_setup_scaffold.dart';

class ResumeScreen extends StatelessWidget {
  const ResumeScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ProfileSetupScaffold(
      state: state,
      index: 5,
      children: [
        ui.caption(
          'Add your updated resume to complete your profile and apply for jobs easily.',
        ),
        const SizedBox(height: 24),
        const Icon(Icons.upload_file, size: 100, color: blue),
        const SizedBox(height: 24),
        ui.panel(
          Column(
            children: [
              ui.heading('Add Resume'),
              ui.field('Resume filename', value: 'Rohit_Deshmukh_Resume.pdf'),
              ui.button(
                'Add resume to preview',
                () => state.update(() => state.resume = true),
                Icons.add,
              ),
            ],
          ),
        ),
        if (state.resume)
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: blue),
            title: Text(
              state.data['Resume filename'] ?? 'Rohit_Deshmukh_Resume.pdf',
            ),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
        ui.caption(
          'Actual file upload and storage require a connected backend.',
        ),
      ],
    );
  }
}

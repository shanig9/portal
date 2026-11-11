import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../widgets/profile_setup_scaffold.dart';

class WorkExperienceScreen extends StatelessWidget {
  const WorkExperienceScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ProfileSetupScaffold(
      state: state,
      index: 3,
      children: [
        ui.field(
          'Job Title',
          value: 'Digital Marketing Executive',
          required: true,
        ),
        ui.field('Company Name', value: 'Career Connect', required: true),
        ui.select('Experience Type', ['Full Time', 'Part Time', 'Internship']),
        ui.select('Office Mode', ['On-site', 'Remote', 'Hybrid']),
        ui.field('Start Date', value: 'January 2022'),
        if (state.data['current'] != 'yes')
          ui.field('End Date', value: 'March 2024'),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I am currently working here'),
          value: state.data['current'] == 'yes',
          onChanged: (v) =>
              state.update(() => state.data['current'] = v! ? 'yes' : 'no'),
        ),
        ui.field(
          'Responsibilities',
          value: 'Managed digital marketing campaigns, optimized SEO, and created engaging content.',
          lines: 4,
        ),
        ui.extra('Experience'),
      ],
    );
  }
}

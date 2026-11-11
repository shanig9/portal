import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../widgets/profile_setup_scaffold.dart';

class JobPreferencesScreen extends StatelessWidget {
  const JobPreferencesScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ProfileSetupScaffold(
      state: state,
      index: 1,
      children: [
        ui.field(
          'Preferred Job Title',
          value: 'Digital Marketing Executive',
          required: true,
        ),
        ui.choices('Employment Type', ['Full Time', 'Part Time', 'Internship']),
        ui.choices('Work Mode', ['On-site', 'Remote', 'Hybrid']),
        ui.field('Preferred Locations', value: 'Pune, Mumbai'),
        ui.select('Expected Salary', [
          '₹3 – 5 LPA',
          '₹5 – 8 LPA',
          '₹8 – 12 LPA',
        ]),
        ui.select('Notice Period', [
          'Immediate',
          '15 days',
          '30 days',
          '60 days',
        ]),
      ],
    );
  }
}

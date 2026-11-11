import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../widgets/profile_setup_scaffold.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ProfileSetupScaffold(
      state: state,
      index: 2,
      children: [
        ui.select('Highest Qualification', [
          'Bachelor’s Degree',
          'Master’s Degree',
          'Diploma',
          'High School',
        ]),
        ui.field(
          'Degree / Course',
          value: 'B.Tech (Computer Science)',
          required: true,
        ),
        ui.field('Specialization', value: 'Computer Science'),
        ui.select('Course Type', [
          'Full Time',
          'Part Time',
          'Distance Learning',
        ]),
        ui.field(
          'College / Institute',
          value: 'Savitribai Phule Pune University',
          required: true,
        ),
        ui.field('Year of Passing', value: '2020'),
        ui.field('Percentage / CGPA', value: '8.2 CGPA'),
        ui.extra('Education'),
      ],
    );
  }
}

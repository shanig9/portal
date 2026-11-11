import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../widgets/profile_setup_scaffold.dart';

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ProfileSetupScaffold(
      state: state,
      index: 0,
      children: [
        Center(child: ui.avatar('RD', 42)),
        const SizedBox(height: 24),
        ui.field('Full Name', value: 'Rohit Deshmukh', required: true),
        ui.field('Date of Birth', value: '15 March 1998'),
        ui.choices('Gender', ['Male', 'Female', 'Other']),
        ui.field('Mobile Number', value: '+91 98765 43210', required: true),
        ui.field('Email ID', value: 'rohit.deshmukh@gmail.com', required: true),
        ui.field('Current Location', value: 'Pune, Maharashtra'),
      ],
    );
  }
}

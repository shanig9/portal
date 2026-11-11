import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import 'jobs_screen.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) => JobsScreen(state: state);
}

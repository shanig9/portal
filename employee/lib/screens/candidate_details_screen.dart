import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';

class CandidateDetailsScreen extends StatelessWidget {
  const CandidateDetailsScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ui.list([
      ui.panel(
        Column(
          children: [
            ui.avatar('RD', 40),
            ui.heading(state.data['Full Name'] ?? 'Rohit Deshmukh'),
            ui.caption(
              state.data['Job Title'] ?? 'Digital Marketing Executive',
            ),
            ui.caption('Pune · 2 years experience'),
            ui.caption(state.data['Email ID'] ?? 'rohit.deshmukh@gmail.com'),
          ],
        ),
      ),
      ...{
        'Profile Summary': 'Passionate professional with experience in digital marketing, SEO, and content creation.',
        'Skills': state.skills.join(' · '),
        'Education':
            '${state.data['Degree / Course'] ?? 'B.Tech (Computer Science)'}\n${state.data['College / Institute'] ?? 'Savitribai Phule Pune University'}\n${state.data['extraEducation'] ?? ''}',
        'Work Experience':
            '${state.data['Job Title'] ?? 'Digital Marketing Executive'} · ${state.data['Company Name'] ?? 'Career Connect'}\n${state.data['Responsibilities'] ?? 'Managed campaigns and delivered measurable results.'}\n${state.data['extraExperience'] ?? ''}',
        'Resume': state.resume
            ? (state.data['Resume filename'] ?? 'Rohit_Deshmukh_Resume.pdf')
            : 'No resume added yet',
      }.entries.map(
        (e) => ui.panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ui.heading(e.key),
              Text(e.value, style: const TextStyle(height: 1.7)),
            ],
          ),
        ),
      ),
      ui.button(
        'Watch Skill Reel',
        () => state.open('Reels'),
        Icons.play_circle_outline,
      ),
      TextButton(
        onPressed: () => state.open('Personal Details'),
        child: const Text('Edit profile'),
      ),
    ]);
  }
}

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../widgets/profile_setup_scaffold.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ProfileSetupScaffold(
      state: state,
      index: 4,
      children: [
        TextField(
          onSubmitted: state.addSkill,
          decoration: const InputDecoration(
            hintText: 'Type a skill and press enter',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        ui.heading('Selected Skills (${state.skills.length}/10)'),
        Wrap(
          spacing: 8,
          children: state.skills
              .map(
                (s) => InputChip(
                  label: Text(s),
                  onDeleted: () => state.update(() => state.skills.remove(s)),
                ),
              )
              .toList(),
        ),
        ui.heading('Suggested Skills'),
        Wrap(
          spacing: 8,
          children:
              [
                    'Meta Ads',
                    'Email Marketing',
                    'Analytics',
                    'Lead Generation',
                    'Communication',
                    'Team Management',
                  ]
                  .map(
                    (s) => ActionChip(
                      label: Text('+ $s'),
                      onPressed: () => state.addSkill(s),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

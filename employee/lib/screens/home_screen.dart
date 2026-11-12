import '../widgets/employee_icon.dart';

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ui.list([
      TextField(
        decoration: const InputDecoration(
          hintText: 'Search posts, jobs, or people',
          prefixIcon: EmployeeIcon(Icons.search),
        ),
        onSubmitted: (v) {
          state.query = v;
          state.open('Jobs');
        },
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: ['Posts', 'Jobs', 'Reels', 'Saved']
            .map(
              (e) => ActionChip(
                label: Text(e),
                onPressed: () => e == 'Posts'
                    ? ui.createPost()
                    : state.open(e == 'Saved' ? 'Saved Jobs' : e),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      ui.panel(
        Row(
          children: [
            ui.avatar(),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: ui.createPost,
                child: const Text('Share your career journey…'),
              ),
            ),
          ],
        ),
      ),
      ...state.posts.map((p) => ui.post('Rohit Deshmukh', p, false)),
      ui.post(
        'Ananya Deshmukh',
        'Just completed my Google Digital Marketing certification! Excited to explore new opportunities.\n#DigitalMarketing #CareerGrowth',
        true,
      ),
      ui.panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ui.heading('Your next chapter starts here'),
            ui.caption('Help employers discover your strengths.'),
            const SizedBox(height: 12),
            ui.button(
              'Complete my profile',
              () => state.open(state.steps.first),
            ),
          ],
        ),
      ),
    ]);
  }
}

import 'employee_icon.dart';

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import 'employee_ui.dart';
import '../theme.dart';

class CareerPost extends StatelessWidget {
  const CareerPost({
    super.key,
    required this.state,
    required this.name,
    required this.text,
    required this.art,
  });
  final EmployeeController state;
  final String name;
  final String text;
  final bool art;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ui.panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ui.avatar(name.substring(0, 1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ui.caption('Job seeker · Just now'),
                  ],
                ),
              ),
              const EmployeeIcon(Icons.more_horiz),
            ],
          ),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(height: 1.7)),
          if (art)
            Container(
              height: 210,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/images/career_mentor.jpg'),
                  fit: BoxFit.cover,
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xFF142D50), blue],
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EmployeeIcon(
                    Icons.play_circle_outline,
                    size: 70,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Flexible(
                    child: Text(
                      'Build skills. Open doors.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          Wrap(
            spacing: 12,
            children: [
              TextButton.icon(
                onPressed: () => state.update(() => state.liked = !state.liked),
                icon: EmployeeIcon(
                  state.liked ? Icons.favorite : Icons.favorite_border,
                ),
                label: Text(state.liked ? 'Liked' : 'Like'),
              ),
              TextButton.icon(
                onPressed: () => ui.entryDialog(
                  'Comment',
                  (v) => ui.notice('Comment added: $v'),
                ),
                icon: const EmployeeIcon(Icons.chat_bubble_outline),
                label: const Text('Comment'),
              ),
              IconButton(
                tooltip: 'Save post',
                onPressed: () => ui.notice('Post saved for this session'),
                icon: const EmployeeIcon(Icons.bookmark_border),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

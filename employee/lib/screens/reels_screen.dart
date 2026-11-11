import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../theme.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ui.list([
      Wrap(
        spacing: 8,
        children: ['For You', 'Job Tips', 'Interview', 'Career']
            .map(
              (e) => ChoiceChip(
                label: Text(e),
                selected: (state.data['reelCategory'] ?? 'For You') == e,
                onSelected: (_) =>
                    state.update(() => state.data['reelCategory'] = e),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      Container(
        height: 470,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF142B4B), blue],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(
                '${state.data['reelCategory'] ?? 'For You'} · CAREER CLASS',
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.record_voice_over,
              size: 80,
              color: Colors.white70,
            ),
            const SizedBox(height: 24),
            const Text(
              'Your next interview.\nYour best first impression.',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Prepare your story. Research the company.\nAsk thoughtful questions.',
              style: TextStyle(color: Colors.white, height: 1.8),
            ),
            const Spacer(),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Career Connect · Interview tips',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      state.update(() => state.liked = !state.liked),
                  icon: Icon(
                    state.liked ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ui.button(
        state.following ? 'Following Career Connect' : 'Follow Career Connect',
        () => state.update(() => state.following = !state.following),
        Icons.add,
      ),
      ui.caption(
        'Illustrated preview. Video playback needs a connected media source.',
      ),
    ]);
  }
}

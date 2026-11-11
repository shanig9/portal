import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../widgets/employee_ui.dart';
import '../theme.dart';

class ReferralsScreen extends StatelessWidget {
  const ReferralsScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) {
    final ui = EmployeeUi(context, state);
    return ui.list([
      const SizedBox(height: 16),
      const Icon(Icons.card_giftcard, size: 90, color: blue),
      ui.heading('Refer Friends & Earn Points!'),
      ui.caption(
        'Invite your friends to join the app and get rewarded with points.',
      ),
      const SizedBox(height: 24),
      ui.panel(
        const ListTile(
          leading: Icon(Icons.people_outline, color: blue, size: 40),
          title: Text('You refer a friend'),
          subtitle: Text('You earn 100 points'),
        ),
      ),
      ui.heading('Your Referral Stats'),
      ui.panel(
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('0', style: TextStyle(fontSize: 30, color: blue)),
                  Text('Friends referred', textAlign: TextAlign.center),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text('0', style: TextStyle(fontSize: 30, color: blue)),
                  Text('Total points', textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
      ui.heading('Your Referral Code'),
      const SelectableText(
        'ROHIT123',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 28,
          letterSpacing: 3,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      ui.caption('Select and copy your code to invite a friend.'),
      ui.heading('How it works'),
      ui.panel(
        const Text(
          'Share your code with a friend. When they sign up using your code, you earn 100 points. Referral tracking requires a connected account.',
          style: TextStyle(height: 1.8),
        ),
      ),
    ]);
  }
}

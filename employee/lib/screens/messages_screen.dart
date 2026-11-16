import 'package:career_connect_chat/career_connect_chat.dart';
import 'package:material_ui/material_ui.dart';

import '../state/employee_controller.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key, required this.state});
  final EmployeeController state;
  @override
  Widget build(BuildContext context) => const CareerChatInbox();
}

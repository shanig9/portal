import 'employee_icon.dart';

import 'package:flutter/material.dart';

import '../state/employee_controller.dart';
import '../theme.dart';
import 'career_post.dart';
import 'create_post_sheet.dart';

class EmployeeUi {
  EmployeeUi(this.context, this.state);
  final BuildContext context;
  final EmployeeController state;
  Widget heading(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Color(0xFF14243C),
        ),
      ),
    );
  }

  Widget caption(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.blueGrey, height: 1.5),
    );
  }

  Widget panel(Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget list(List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: children,
    );
  }

  Widget avatar([String text = 'RD', double radius = 24]) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE0F0FF),
      backgroundImage: text == 'RD'
          ? const AssetImage('assets/images/profile.jpg')
          : text == 'A'
          ? const AssetImage('assets/images/community.jpg')
          : null,
      child: text == 'RD' || text == 'A'
          ? null
          : Text(
              text,
              style: const TextStyle(color: blue, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget button(
    String text,
    VoidCallback action, [
    IconData icon = Icons.arrow_forward,
  ]) {
    return FilledButton.icon(
      onPressed: action,
      icon: EmployeeIcon(icon, size: 18),
      label: Text(text),
    );
  }

  Widget field(
    String label, {
    String? value,
    bool required = false,
    bool password = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('${state.page}-$label'),
      initialValue: state.data[label] ?? value,
      obscureText: password,
      maxLines: lines,
      onChanged: (v) => state.data[label] = v,
      validator: required
          ? (v) => v == null || v.trim().isEmpty
                ? 'Enter $label'
                : label.contains('Email') && !v.contains('@')
                ? 'Enter a valid email'
                : null
          : null,
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: EmployeeIcon(fieldIcon(label)),
      ),
    ),
  );
  Widget select(String label, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey('${state.page}-$label'),
        initialValue: state.data[label] ?? options.first,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: EmployeeIcon(fieldIcon(label)),
        ),
        items: options
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => state.data[label] = v!,
      ),
    );
  }

  Widget choices(String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: options
              .map(
                (e) => ChoiceChip(
                  label: Text(e),
                  selected: (state.data[label] ?? options.first) == e,
                  onSelected: (_) => state.update(() => state.data[label] = e),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  IconData fieldIcon(String label) {
    final name = label.toLowerCase();
    if (name.contains('email')) return Icons.mail_outline;
    if (name.contains('phone') || name.contains('mobile')) {
      return Icons.phone_outlined;
    }
    if (name.contains('date') ||
        name.contains('birth') ||
        name.contains('year')) {
      return Icons.calendar_month_outlined;
    }
    if (name.contains('location')) return Icons.location_on_outlined;
    if (name.contains('company') || name.contains('college')) {
      return Icons.business_outlined;
    }
    if (name.contains('degree') ||
        name.contains('qualification') ||
        name.contains('course')) {
      return Icons.school_outlined;
    }
    if (name.contains('job') ||
        name.contains('mode') ||
        name.contains('type')) {
      return Icons.work_outline;
    }
    if (name.contains('resume')) return Icons.description_outlined;
    return Icons.person_outline;
  }

  void notice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void menu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .75,
          child: ListView(
            children: [
              ListTile(title: heading('Explore Career Connect')),
              ...[
                ...state.tabs,
                'My Applications',
                'Candidate Details',
                'Refer & Earn',
                'Saved Jobs',
                'Login',
                'Registration',
                ...state.steps,
              ].map(
                (name) => ListTile(
                  title: Text(name),
                  trailing: const EmployeeIcon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    state.open(name);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData icon(String name) {
    return switch (name) {
      'Education' => Icons.school_outlined,
      'Work Experience' => Icons.work_outline,
      'Skills' => Icons.stars_outlined,
      'Resume' => Icons.description_outlined,
      'Refer & Earn' => Icons.card_giftcard,
      'My Applications' => Icons.assignment_outlined,
      'Saved Jobs' => Icons.bookmark_outline,
      _ => Icons.person_outline,
    };
  }

  Widget extra(String type) {
    return Column(
      children: [
        if (state.data['extra$type'] != null)
          ListTile(
            title: Text(state.data['extra$type']!),
            leading: const EmployeeIcon(
              Icons.check_circle_outline,
              color: blue,
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => entryDialog(
            'Add $type',
            (v) => state.update(() => state.data['extra$type'] = v),
          ),
          icon: const EmployeeIcon(Icons.add_circle_outline),
          label: Text('Add Another $type (Optional)'),
        ),
      ],
    );
  }

  void entryDialog(String title, ValueChanged<String> save) {
    String value = '';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          onChanged: (v) => value = v,
          decoration: const InputDecoration(hintText: 'Enter details'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (value.trim().isNotEmpty) {
                save(value.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget post(String name, String text, bool art) =>
      CareerPost(state: state, name: name, text: text, art: art);
  void createPost() => showCreatePost(context, state);
}

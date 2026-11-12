import 'package:flutter/material.dart';

import 'main.dart';
import 'hr_icon.dart';

void go(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      BrandMark(),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Career Connect',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              'HR Job Portal',
              style: TextStyle(fontSize: 15, color: Color(0xFF505C83)),
            ),
          ],
        ),
      ),
    ],
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _WavePainter())),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: children,
          ),
        ),
      ),
    ],
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Career Connect',
    child: Container(
      width: 42,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F1FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.hub_rounded, color: brandBlue, size: 30),
    ),
  );
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .88)
      ..cubicTo(
        size.width * .28,
        size.height * .75,
        size.width * .28,
        size.height * 1.02,
        size.width * .62,
        size.height * .85,
      )
      ..quadraticBezierTo(
        size.width * .9,
        size.height * .65,
        size.width,
        size.height * .75,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFEAF4FF));
    final foreground = Path()
      ..moveTo(0, size.height * .9)
      ..cubicTo(
        size.width * .25,
        size.height * .8,
        size.width * .4,
        size.height * 1.04,
        size.width * .7,
        size.height * .93,
      )
      ..quadraticBezierTo(
        size.width * .9,
        size.height * .86,
        size.width,
        size.height * .91,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(foreground, Paint()..color = const Color(0xFFDDEEFF));
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => false;
}

Widget heading(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 18),
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w900,
      letterSpacing: -.6,
    ),
  ),
);
Widget muted(String text) =>
    Text(text, style: const TextStyle(color: Color(0xFF536185), height: 1.5));
Widget card(Widget child) => Card(
  child: Padding(padding: const EdgeInsets.all(18), child: child),
);
Widget primary(String label, VoidCallback action) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [Color(0xFF0099FF), Color(0xFF0050ED)],
      ),
    ),
    child: FilledButton(
      style: FilledButton.styleFrom(backgroundColor: Colors.transparent),
      onPressed: action,
      child: Text(label),
    ),
  ),
);
Widget section(String label, List<Widget> children) => card(
  Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F1FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      ...children,
    ],
  ),
);

Widget input(
  String label,
  String value,
  ValueChanged<String> changed, {
  bool required = true,
  int lines = 1,
  TextInputType? keyboard,
  int? limit,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 18),
  child: TextFormField(
    initialValue: value,
    onChanged: changed,
    maxLines: lines,
    maxLength: limit,
    keyboardType: keyboard,
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return 'Enter $label';
      if (text.isNotEmpty &&
          keyboard == TextInputType.emailAddress &&
          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
        return 'Enter a valid email address';
      }
      if (text.isNotEmpty &&
          keyboard == TextInputType.phone &&
          text.replaceAll(RegExp(r'\D'), '').length < 10) {
        return 'Enter a valid mobile number';
      }
      if (text.isNotEmpty &&
          keyboard == TextInputType.number &&
          (int.tryParse(text) == null || int.parse(text) < 1)) {
        return 'Enter a positive number';
      }
      return null;
    },
    decoration: InputDecoration(
      labelText: '$label${required ? ' *' : ''}',
      prefixIcon: lines == 1 ? HrIcon(hrFieldIcon(label)) : null,
      alignLabelWithHint: lines > 1,
    ),
  ),
);

Widget dropdown(
  String label,
  String value,
  List<String> options,
  ValueChanged<String> changed,
) => Padding(
  padding: const EdgeInsets.only(bottom: 18),
  child: DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: HrIcon(hrFieldIcon(label)),
    ),
    items: options
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (value) {
      if (value != null) changed(value);
    },
  ),
);

class AdaptivePair extends StatelessWidget {
  const AdaptivePair({super.key, required this.first, required this.second});
  final Widget first;
  final Widget second;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => constraints.maxWidth < 420
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, second],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 16),
              Expanded(child: second),
            ],
          ),
  );
}

class HrIconTile extends StatelessWidget {
  const HrIconTile(this.icon, {super.key, this.size = 48});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFE9F4FF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: HrIcon(icon, size: 24, color: brandBlue),
  );
}

Widget badge(String status) {
  final color = switch (status) {
    'New' || 'Active' => Colors.green,
    'In Review' => Colors.deepPurple,
    'Rejected' || 'Closed' => Colors.red,
    'Draft' => Colors.orange,
    _ => brandBlue,
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(
      status,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    ),
  );
}

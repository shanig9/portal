import 'hr_icon.dart';

import 'package:flutter/material.dart';

import 'auth_screens.dart' show signOutEmployer;

import 'models.dart';
import 'widgets.dart';
import 'main.dart';

List<Widget> companyFields(Company company, {bool registration = false}) => [
  input('Company Name', company.name, (value) => company.name = value),
  dropdown('Industry *', company.industry, [
    'IT Services & Consulting',
    'Healthcare',
    'Education',
    'Manufacturing',
    'Other',
  ], (value) => company.industry = value),
  AdaptivePair(
    first: dropdown('Company Size', company.size, [
      '1 - 10 Employees',
      '11 - 50 Employees',
      '51 - 200 Employees',
      '201 - 500 Employees',
      '500+ Employees',
    ], (value) => company.size = value),
    second: dropdown(
      'Established Year',
      company.year,
      List.generate(47, (index) => '${2026 - index}'),
      (value) => company.year = value,
    ),
  ),
  input('Location', company.location, (value) => company.location = value),
  if (!registration) ...[
    input(
      'Company Website',
      company.website,
      (value) => company.website = value,
      required: false,
      keyboard: TextInputType.url,
    ),
    input(
      'About Company',
      company.about,
      (value) => company.about = value,
      lines: 4,
      limit: 300,
    ),
  ],
  input(
    'Company Phone',
    company.phone,
    (value) => company.phone = value,
    keyboard: TextInputType.phone,
  ),
  input(
    'Official Email',
    company.email,
    (value) => company.email = value,
    keyboard: TextInputType.emailAddress,
  ),
];

class EmployerProfile extends StatelessWidget {
  const EmployerProfile({
    super.key,
    required this.company,
    required this.onChanged,
  });
  final Company company;
  final VoidCallback onChanged;
  Future<void> edit(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(company: company)),
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      heading('Employer Profile'),
      card(
        Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const HrIconTile(Icons.business),
              title: Text(
                company.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              subtitle: Text(company.industry),
              trailing: IconButton(
                tooltip: 'Edit Profile',
                onPressed: () => edit(context),
                icon: const HrIcon(Icons.edit_outlined, color: brandBlue),
              ),
            ),
            const Divider(height: 32),
            ...[
              (Icons.business_outlined, 'Company Name', company.name),
              (Icons.work_outline, 'Industry', company.industry),
              (Icons.people_outline, 'Company Size', company.size),
              (Icons.location_on_outlined, 'Location', company.location),
              (Icons.language, 'Company Website', company.website),
              (Icons.description_outlined, 'About Company', company.about),
            ].map(
              (item) => Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: HrIconTile(item.$1, size: 42),
                    title: Text(
                      item.$2,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item.$3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const HrIcon(Icons.chevron_right, size: 18),
                    onTap: () => edit(context),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
          ],
        ),
      ),
      primary('Edit Profile', () => edit(context)),
      TextButton.icon(
        onPressed: () => signOutEmployer(context),
        icon: const HrIcon(Icons.logout),
        label: const Text('Sign out'),
      ),
    ],
  );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.company});
  final Company company;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  late final Company draft;
  @override
  void initState() {
    super.initState();
    draft = widget.company.copy();
  }

  void save() {
    if (!form.currentState!.validate()) return;
    widget.company
      ..name = draft.name
      ..industry = draft.industry
      ..size = draft.size
      ..year = draft.year
      ..location = draft.location
      ..website = draft.website
      ..about = draft.about
      ..phone = draft.phone
      ..email = draft.email;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit Employer Profile')),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          card(
            Row(
              children: [
                const BrandMark(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      muted(draft.industry),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...companyFields(draft),
          primary('Save Changes', save),
        ],
      ),
    ),
  );
}

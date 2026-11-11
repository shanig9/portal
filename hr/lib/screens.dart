import 'package:flutter/material.dart';

import 'main.dart';
import 'models.dart';
import 'widgets.dart';
import 'job_screens.dart';
import 'profile_screens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: PageBody(
        children: [
          const SizedBox(height: 24),
          const Brand(),
          const SizedBox(height: 28),
          heading('Welcome Employer'),
          muted('Hire the right talent, faster and easier.'),
          const SizedBox(height: 26),
          ...[
            (
              Icons.work_outline,
              'Post Jobs',
              'Reach skilled and verified candidates',
            ),
            (
              Icons.people_outline,
              'Manage Applications',
              'Review, shortlist and connect',
            ),
            (
              Icons.calendar_month,
              'Schedule Interviews',
              'Coordinate directly with candidates',
            ),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.$1, color: brandBlue, size: 30),
                ),
                title: Text(
                  item.$2,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: muted(item.$3),
              ),
            ),
          ),
          Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF5FF), Color(0xFFD5E9FF)],
              ),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.laptop_mac, size: 145, color: Color(0xFF426BB1)),
                Positioned(
                  right: 35,
                  top: 14,
                  child: Icon(Icons.person_search, size: 90, color: brandBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          primary('Login as Employer', () => go(context, const LoginScreen())),
          OutlinedButton(
            onPressed: () => go(context, const RegistrationScreen()),
            child: const Text('Register as Employer'),
          ),
          TextButton(
            onPressed: () => go(context, PortalScreen(company: Company())),
            child: const Text('Explore frontend preview'),
          ),
        ],
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  String phone = '';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          const Brand(),
          const SizedBox(height: 28),
          heading('Employer Login'),
          muted('Enter your mobile number to continue.'),
          const SizedBox(height: 30),
          input(
            'Mobile Number',
            phone,
            (value) => phone = value,
            keyboard: TextInputType.phone,
          ),
          primary('Send OTP', () {
            if (form.currentState!.validate()) {
              go(context, OtpScreen(company: Company(), phone: phone));
            }
          }),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('or'),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),
          card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_add_alt, color: brandBlue, size: 40),
                heading('New to Career Connect?'),
                muted('Create an employer account and start hiring today.'),
                TextButton(
                  onPressed: () => go(context, const RegistrationScreen()),
                  child: const Text('Register as Employer →'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final form = GlobalKey<FormState>();
  final company = Company()
    ..name = ''
    ..location = ''
    ..phone = ''
    ..email = '';
  bool agreed = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          const Brand(),
          heading('Employer Registration'),
          muted('Create your company account and start hiring.'),
          const SizedBox(height: 24),
          ...companyFields(company, registration: true),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: agreed,
            onChanged: (value) => setState(() => agreed = value!),
            title: const Text(
              'I agree to the Terms & Conditions and Privacy Policy',
            ),
          ),
          primary('Register & Get OTP', () {
            if (!form.currentState!.validate()) return;
            if (!agreed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please accept the terms to continue.'),
                ),
              );
              return;
            }
            go(context, OtpScreen(company: company, phone: company.phone));
          }),
        ],
      ),
    ),
  );
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.company, required this.phone});
  final Company company;
  final String phone;
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final form = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Form(
      key: form,
      child: PageBody(
        children: [
          const Brand(),
          heading('Verify Mobile Number'),
          muted('Continue with ${widget.phone}'),
          const SizedBox(height: 24),
          TextFormField(
            maxLength: 6,
            keyboardType: TextInputType.number,
            validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
                ? null
                : 'Enter a six-digit code',
            decoration: const InputDecoration(labelText: 'Verification code'),
          ),
          const SizedBox(height: 12),
          muted(
            'Frontend preview: enter any six digits to explore the employer portal.',
          ),
          primary('Continue to Dashboard', () {
            if (form.currentState!.validate()) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => PortalScreen(company: widget.company),
                ),
                (_) => false,
              );
            }
          }),
        ],
      ),
    ),
  );
}

class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key, required this.company});
  final Company company;
  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  int tab = 0;
  final jobs = [
    Job(),
    Job(
        title: 'Digital Marketing Executive',
        skills: [
          'SEO',
          'Meta Ads',
          'Google Ads',
          'Social Media',
          'Content Creation',
          'Lead Generation',
        ],
      )
      ..experience = '1 - 3 Years'
      ..salary = '₹3 - 5 LPA'
      ..description = 'Plan, execute, and optimize online marketing campaigns across SEO, paid ads, social media, and content channels. Collaborate with cross-functional teams to grow brand visibility and generate quality leads.',
  ];
  final applicants = [
    Applicant('Sneha Kulkarni', 'UI/UX Designer', 'New'),
    Applicant('Amit Patil', 'Flutter Developer', 'In Review'),
    Applicant('Neha More', 'Digital Marketing Executive', 'Shortlisted'),
    Applicant('Rohit Deshmukh', 'Backend Developer', 'New'),
  ];

  Future<void> postJob() async {
    final job = await Navigator.of(context)
        .push<Job>(MaterialPageRoute(builder: (_) => const JobFormScreen()));
    if (job != null && mounted) {
      setState(() {
        jobs.insert(0, job);
        tab = 0;
      });
    }
  }

  Future<void> openJob(Job job) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => JobDetailsScreen(
          job: job,
          applicants: applicants,
          onDelete: () => jobs.remove(job),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Brand(),
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => go(
            context,
            Scaffold(
              appBar: AppBar(title: const Text('Notifications')),
              body: PageBody(
                children: [
                  heading('You’re all caught up'),
                  muted('Your hiring updates will appear here.'),
                ],
              ),
            ),
          ),
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    ),
    body: tab == 2
        ? EmployerProfile(
            company: widget.company,
            onChanged: () => setState(() {}),
          )
        : PageBody(
            children: [
              Row(
                children: [
                  Expanded(child: heading('Job Applications')),
                  TextButton(
                    onPressed: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) =>
                              ApplicationsScreen(applicants: applicants),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    child: const Text('View All →'),
                  ),
                ],
              ),
              ...applicants.map(
                (applicant) => ApplicantTile(
                  applicant: applicant,
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => ApplicantScreen(applicant: applicant),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: heading('Your Jobs')),
                  IconButton(
                    tooltip: 'Post a job',
                    onPressed: postJob,
                    icon: const Icon(Icons.add_circle, color: brandBlue),
                  ),
                ],
              ),
              if (jobs.isEmpty)
                card(muted('No jobs yet. Post your first opportunity.')),
              ...jobs.map(
                (job) => card(
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      job.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${job.location} · ${job.employment}'),
                    trailing: badge(
                      job.draft
                          ? 'Draft'
                          : job.active
                          ? 'Active'
                          : 'Closed',
                    ),
                    onTap: () => openJob(job),
                  ),
                ),
              ),
            ],
          ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (index) {
        if (index == 1) {
          postJob();
        } else {
          setState(() => tab = index);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle, color: brandBlue, size: 34),
          label: 'Post Job',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}

class ApplicantTile extends StatelessWidget {
  const ApplicantTile({
    super.key,
    required this.applicant,
    required this.onTap,
  });
  final Applicant applicant;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => card(
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFE5F1FF),
            child: Text(
              applicant.name.split(' ').map((word) => word[0]).take(2).join(),
              style: const TextStyle(
                color: brandBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applicant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                muted(applicant.role),
                const SizedBox(height: 8),
                badge(applicant.status),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key, required this.applicants});
  final List<Applicant> applicants;
  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  String filter = 'All';
  String query = '';
  @override
  Widget build(BuildContext context) {
    final visible = widget.applicants
        .where(
          (person) =>
              (filter == 'All' || person.status == filter) &&
              '${person.name} ${person.role}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Job Applications')),
      body: PageBody(
        children: [
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Search candidates or roles',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: ['All', 'New', 'In Review', 'Shortlisted', 'Rejected']
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: filter == value,
                    onSelected: (_) => setState(() => filter = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          if (visible.isEmpty)
            card(muted('No applications match your search.')),
          ...visible.map(
            (person) => ApplicantTile(
              applicant: person,
              onTap: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ApplicantScreen(applicant: person),
                  ),
                );
                if (mounted) setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ApplicantScreen extends StatefulWidget {
  const ApplicantScreen({super.key, required this.applicant});
  final Applicant applicant;
  @override
  State<ApplicantScreen> createState() => _ApplicantScreenState();
}

class _ApplicantScreenState extends State<ApplicantScreen> {
  late String status;
  @override
  void initState() {
    super.initState();
    status = widget.applicant.status;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Candidate Details')),
    body: PageBody(
      children: [
        const CircleAvatar(
          radius: 42,
          child: Icon(Icons.person_outline, size: 44),
        ),
        heading(widget.applicant.name),
        muted(widget.applicant.role),
        const SizedBox(height: 16),
        section('Profile Summary', [
          muted(
            'Motivated professional with strong communication, collaboration, and problem-solving skills.',
          ),
          const SizedBox(height: 18),
          const Text('Pune, Maharashtra · 2 years experience'),
        ]),
        section('Skills', [
          Wrap(
            spacing: 8,
            children: [
              widget.applicant.role,
              'Communication',
              'Teamwork',
            ].map((skill) => Chip(label: Text(skill))).toList(),
          ),
        ]),
        dropdown('Application Status', status, [
          'New',
          'In Review',
          'Shortlisted',
          'Rejected',
        ], (value) => status = value),
        primary('Save Status', () {
          widget.applicant.status = status;
          Navigator.pop(context);
        }),
      ],
    ),
  );
}

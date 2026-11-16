import 'package:material_ui/material_ui.dart';

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:career_connect_chat/career_jobs.dart';

import '../services/auth_service.dart';
import '../services/records_service.dart';

class EmployeeController extends ChangeNotifier {
  EmployeeController({
    this.page = 'Login',
    AuthService? auth,
    RecordsService? records,
  }) : auth = auth ?? FirebaseAuthService(),
       _records = records ?? RecordsService(),
       _syncApplications = records != null || Firebase.apps.isNotEmpty {
    if (Firebase.apps.isNotEmpty) {
      jobs.clear();
      _jobSubscription = CareerJobs().watch().listen(
        (items) {
          final now = DateTime.now().millisecondsSinceEpoch;
          update(() {
            jobs.clear();
            jobDetails.clear();
            for (final item in items) {
              if ((item['live'] as int) > now ||
                  (item['expiry'] as int) < now) {
                continue;
              }
              final id = item['id'] as String;
              jobDetails[id] = item;
              jobs.add((
                item['title'] as String,
                item['company'] as String,
                item['location'] as String,
                item['salary'] as String,
                item['employment'] as String,
                id,
              ));
            }
            data.remove('jobsError');
          });
        },
        onError: (Object error) => update(
          () => data['jobsError'] =
              'Unable to load published jobs. Check your connection and retry.',
        ),
      );
    }
    final account = this.auth.currentAccount;
    if (account != null) {
      _setAccount(account);
      if (page == 'Login') page = 'Home';
    }
  }
  final AuthService auth;
  final RecordsService _records;
  final bool _syncApplications;
  bool _disposed = false;
  StreamSubscription<List<Map<String, dynamic>>>? _jobSubscription;
  final jobDetails = <String, Map<String, dynamic>>{};
  String selectedJobId = '';
  @override
  void dispose() {
    _disposed = true;
    _jobSubscription?.cancel();
    super.dispose();
  }

  AuthAccount? account;

  void _setAccount(AuthAccount value) {
    if (account?.uid != value.uid) applied.clear();
    account = value;
    data['Full Name'] = value.name ?? '';
    data['Email ID'] = value.email ?? '';
    data['Mobile Number'] = value.phone ?? '';
    if (_syncApplications) unawaited(refreshAppliedJobs());
  }

  Future<void> refreshAppliedJobs() async {
    final uid = account?.uid;
    if (uid == null || !_syncApplications) return;
    try {
      final applications = await _records.list('applications');
      if (_disposed || account?.uid != uid) return;
      update(() {
        // Keep applications confirmed by a concurrent submission as well.
        applied.addAll(
          applications.map((item) => item['job_key']).whereType<String>(),
        );
        data.remove('applicationsError');
      });
    } catch (_) {
      if (_disposed || account?.uid != uid) return;
      update(
        () =>
            data['applicationsError'] = 'Could not refresh your applied jobs.',
      );
    }
  }

  void authenticated(AuthAccount value, {bool onboarding = false}) =>
      update(() {
        _setAccount(value);
        page = onboarding ? 'Personal Details' : 'Home';
        tab = 0;
        history.clear();
      });

  Future<void> signOut() async {
    await auth.signOut();
    update(() {
      account = null;
      data.clear();
      saved.clear();
      applied.clear();
      posts.clear();
      skills
        ..clear()
        ..addAll(_defaultSkills);
      query = '';
      filter = 'All jobs';
      applicationFilter = 'All';
      resume = false;
      liked = false;
      following = false;
      page = 'Login';
      tab = 0;
      history.clear();
    });
  }

  final tabs = ['Home', 'Jobs', 'Reels', 'Messages', 'Profile'];
  final steps = [
    'Personal Details',
    'Job Preferences',
    'Education',
    'Work Experience',
    'Skills',
    'Resume',
  ];
  final history = <String>[];
  final saved = <String>{}, applied = <String>{};
  final posts = <String>[];
  static const _defaultSkills = <String>[
    'Digital Marketing',
    'Social Media Marketing',
    'SEO',
    'Google Ads',
    'Content Creation',
  ];
  final skills = <String>[..._defaultSkills];
  final data = <String, String>{};
  final form = GlobalKey<FormState>();
  String page;
  String query = '',
      filter = 'All jobs',
      selectedJob = 'Digital Marketing Executive',
      applicationFilter = 'All';
  int tab = 0;
  bool liked = false, following = false, compact = false, resume = false;
  final jobs = const [
    (
      'Digital Marketing Executive',
      'Career Connect',
      'Pune',
      '₹3 – 5 LPA',
      'Full Time',
    ),
    (
      'Frontend Developer',
      'ABC Technologies',
      'Remote',
      '₹6 – 10 LPA',
      'Full Time',
    ),
    ('HR Executive', 'Pune IT Solutions', 'Pune', '₹2.5 – 4 LPA', 'Part Time'),
    (
      'Business Development Associate',
      'NextLadders',
      'Mumbai',
      '₹3 – 6 LPA',
      'Full Time',
    ),
    ('Backend Developer', 'HR Team', 'Hybrid', '₹5 – 8 LPA', 'Full Time'),
    (
      'UI/UX Designer',
      'MindSphere Solutions',
      'Remote',
      '₹4 – 7 LPA',
      'Internship',
    ),
  ].map((job) => (job.$1, job.$2, job.$3, job.$4, job.$5, '')).toList();

  void open(String name) {
    update(() {
      history.add(page);
      page = name;
    });
    if (name == 'Jobs' || name == 'Job Details') {
      unawaited(refreshAppliedJobs());
    }
  }

  void back() =>
      update(() => page = history.isEmpty ? tabs[tab] : history.removeLast());
  void addSkill(String s) {
    if (s.trim().isNotEmpty &&
        !skills.contains(s.trim()) &&
        skills.length < 10) {
      update(() => skills.add(s.trim()));
    }
  }

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  void showHome() => update(() {
    page = 'Home';
    tab = 0;
    history.clear();
  });
}

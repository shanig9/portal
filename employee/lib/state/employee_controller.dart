import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class EmployeeController extends ChangeNotifier {
  EmployeeController({this.page = 'Login', AuthService? auth})
    : auth = auth ?? FirebaseAuthService() {
    final account = this.auth.currentAccount;
    if (account != null) {
      _setAccount(account);
      if (page == 'Login') page = 'Home';
    }
  }
  final AuthService auth;
  AuthAccount? account;

  void _setAccount(AuthAccount value) {
    account = value;
    data['Full Name'] = value.name ?? '';
    data['Email ID'] = value.email ?? '';
    data['Mobile Number'] = value.phone ?? '';
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
      messages.clear();
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
  final posts = <String>[], messages = <String>[];
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
      chat = 'Career Connect',
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
  ];

  void open(String name) => update(() {
    history.add(page);
    page = name;
  });
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

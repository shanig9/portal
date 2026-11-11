import 'package:flutter/material.dart';

class EmployeeController extends ChangeNotifier {
  EmployeeController({this.page = 'Login'});
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
  final skills = <String>[
    'Digital Marketing',
    'Social Media Marketing',
    'SEO',
    'Google Ads',
    'Content Creation',
  ];
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

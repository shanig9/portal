class Company {
  String name = 'Career Connect Pvt. Ltd.';
  String industry = 'IT Services & Consulting';
  String size = '51 - 200 Employees';
  String year = '2019';
  String location = 'Pune, Maharashtra';
  String website = 'www.example.com';
  String about =
      'We are a digital solutions company providing technology and consulting services.';
  String phone = '+91 90677 77097';
  String email = 'hr@example.com';

  Company copy() => Company()
    ..name = name
    ..industry = industry
    ..size = size
    ..year = year
    ..location = location
    ..website = website
    ..about = about
    ..phone = phone
    ..email = email;
}

class Job {
  Job({this.title = 'Flutter Developer', List<String>? skills})
    : skills = skills ?? ['Flutter', 'Dart', 'API Integration'];
  String title;
  String employment = 'Full Time';
  String experience = '2 - 5 Years';
  String salary = '₹6 - 10 LPA';
  String location = 'Pune';
  String openings = '3';
  String mode = 'On-site';
  String qualification = 'Bachelor’s Degree';
  DateTime live = DateTime(2026, 11, 10);
  DateTime expiry = DateTime(2026, 11, 25);
  List<String> skills;
  String description =
      '• Develop and maintain Flutter mobile applications.\n• Integrate REST APIs and third-party services.\n• Write clean, scalable, and maintainable code.\n• Collaborate with design and backend teams.';
  String about =
      'Career Connect is a technology and consulting company focused on building innovative digital solutions.';
  bool active = true;
  bool draft = false;

  Job copy() => Job(title: title, skills: List.of(skills))
    ..employment = employment
    ..experience = experience
    ..salary = salary
    ..location = location
    ..openings = openings
    ..mode = mode
    ..qualification = qualification
    ..live = live
    ..expiry = expiry
    ..description = description
    ..about = about
    ..active = active
    ..draft = draft;
}

class Applicant {
  Applicant(this.name, this.role, this.status);
  final String name;
  final String role;
  String status;
}

String dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

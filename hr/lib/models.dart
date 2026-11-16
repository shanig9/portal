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
  String? id;
  Map<String, dynamic> toData(String company) => {
    'title': title,
    'company': company,
    'location': location,
    'salary': salary,
    'employment': employment,
    'active': active,
    'draft': draft,
    'live': live.millisecondsSinceEpoch,
    'expiry': DateTime(
      expiry.year,
      expiry.month,
      expiry.day,
      23,
      59,
      59,
    ).millisecondsSinceEpoch,
    'details': {
      'experience': experience,
      'openings': openings,
      'mode': mode,
      'qualification': qualification,
      'skills': skills,
      'description': description,
      'about': about,
    },
  };
  factory Job.fromData(Map<String, dynamic> data) {
    final details = data['details'] as Map<String, dynamic>;
    return Job(
        title: data['title'] as String,
        skills: (details['skills'] as List).cast<String>(),
      )
      ..id = data['id'] as String
      ..employment = data['employment'] as String
      ..location = data['location'] as String
      ..salary = data['salary'] as String
      ..active = data['active'] as bool
      ..draft = data['draft'] as bool
      ..live = DateTime.fromMillisecondsSinceEpoch(data['live'] as int)
      ..expiry = DateTime.fromMillisecondsSinceEpoch(data['expiry'] as int)
      ..experience = details['experience'] as String
      ..openings = details['openings'] as String
      ..mode = details['mode'] as String
      ..qualification = details['qualification'] as String
      ..description = details['description'] as String
      ..about = details['about'] as String;
  }
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
  DateTime live = DateTime.now();
  DateTime expiry = DateTime.now().add(const Duration(days: 30));
  List<String> skills;
  String description =
      '• Develop and maintain Flutter mobile applications.\n• Integrate REST APIs and third-party services.\n• Write clean, scalable, and maintainable code.\n• Collaborate with design and backend teams.';
  String about =
      'Career Connect is a technology and consulting company focused on building innovative digital solutions.';
  bool active = true;
  bool draft = false;

  Job copy() => Job(title: title, skills: List.of(skills))
    ..id = id
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

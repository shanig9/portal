import 'package:flutter/material.dart';

import 'state/employee_controller.dart';
import 'widgets/employee_ui.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/saved_jobs_screen.dart';
import 'screens/job_details_screen.dart';
import 'screens/reels_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/conversation_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/applications_screen.dart';
import 'screens/candidate_details_screen.dart';
import 'screens/referrals_screen.dart';
import 'screens/personal_details_screen.dart';
import 'screens/job_preferences_screen.dart';
import 'screens/education_screen.dart';
import 'screens/work_experience_screen.dart';
import 'screens/skills_screen.dart';
import 'screens/resume_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/notifications_screen.dart';

class EmployeeShell extends StatefulWidget {
  const EmployeeShell({super.key, this.initialPage = 'Login'});
  final String initialPage;
  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  late final EmployeeController state;
  @override
  void initState() {
    super.initState();
    state = EmployeeController(page: widget.initialPage);
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) {
      final ui = EmployeeUi(context, state);
      final setup = state.steps.contains(state.page);
      final auth = [
        'Login',
        'Registration',
        'Forgot Password',
        'Account',
      ].contains(state.page);
      return Scaffold(
        appBar: AppBar(
          leading: state.history.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(10),
                  child: ui.avatar('CC', 16),
                )
              : IconButton(
                  onPressed: state.back,
                  icon: const Icon(Icons.arrow_back),
                ),
          title: Text(
            auth ? 'Career Connect' : state.page,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          actions: [
            if (setup)
              Center(
                child: Text(
                  '${state.steps.indexOf(state.page) + 1} of 6',
                  style: const TextStyle(color: blue),
                ),
              ),
            if (!auth)
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => state.open('Notifications'),
                icon: const Icon(Icons.notifications_none),
              ),
            IconButton(
              tooltip: 'All screens',
              onPressed: ui.menu,
              icon: const Icon(Icons.grid_view_rounded),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                if (setup)
                  LinearProgressIndicator(
                    value: (state.steps.indexOf(state.page) + 1) / 6,
                    color: blue,
                  ),
                Expanded(child: screenFor()),
              ],
            ),
          ),
        ),
        bottomNavigationBar: setup || auth
            ? null
            : NavigationBar(
                selectedIndex: state.tab,
                onDestinationSelected: (index) => state.update(() {
                  state.tab = index;
                  state.page = state.tabs[index];
                  state.history.clear();
                }),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.work_outline),
                    label: 'Jobs',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.video_library_outlined),
                    label: 'Reels',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    label: 'Messages',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: 'Profile',
                  ),
                ],
              ),
        floatingActionButton: state.page == 'Home'
            ? FloatingActionButton(
                onPressed: ui.createPost,
                tooltip: 'Create Post',
                backgroundColor: blue,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              )
            : null,
      );
    },
  );
  Widget screenFor() => switch (state.page) {
    'Home' => HomeScreen(key: ValueKey(state.page), state: state),
    'Jobs' => JobsScreen(key: ValueKey(state.page), state: state),
    'Saved Jobs' => SavedJobsScreen(key: ValueKey(state.page), state: state),
    'Job Details' => JobDetailsScreen(key: ValueKey(state.page), state: state),
    'Reels' => ReelsScreen(key: ValueKey(state.page), state: state),
    'Messages' => MessagesScreen(key: ValueKey(state.page), state: state),
    'Conversation' => ConversationScreen(
      key: ValueKey(state.page),
      state: state,
    ),
    'Profile' => ProfileScreen(key: ValueKey(state.page), state: state),
    'My Applications' => ApplicationsScreen(
      key: ValueKey(state.page),
      state: state,
    ),
    'Candidate Details' => CandidateDetailsScreen(
      key: ValueKey(state.page),
      state: state,
    ),
    'Refer & Earn' => ReferralsScreen(key: ValueKey(state.page), state: state),
    'Personal Details' => PersonalDetailsScreen(
      key: ValueKey(state.page),
      state: state,
    ),
    'Job Preferences' => JobPreferencesScreen(
      key: ValueKey(state.page),
      state: state,
    ),
    'Education' => EducationScreen(key: ValueKey(state.page), state: state),
    'Work Experience' => WorkExperienceScreen(
      key: ValueKey(state.page),
      state: state,
    ),
    'Skills' => SkillsScreen(key: ValueKey(state.page), state: state),
    'Resume' => ResumeScreen(key: ValueKey(state.page), state: state),
    'Login' => LoginScreen(key: ValueKey(state.page), state: state),
    'Registration' => RegistrationScreen(
      key: ValueKey(state.page),
      state: state,
    ),
    'Forgot Password' => ForgotPasswordScreen(
      key: ValueKey(state.page),
      state: state,
    ),
    'Notifications' => NotificationsScreen(
      key: ValueKey(state.page),
      state: state,
    ),
    'Account' => LoginScreen(state: state),
    _ => NotificationsScreen(state: state),
  };
}

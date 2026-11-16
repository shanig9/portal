import 'dart:async';

import 'package:employee/services/auth_service.dart';
import 'package:employee/services/records_service.dart';
import 'package:employee/state/employee_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_service.dart';

class _Records extends RecordsService {
  Future<List<Map<String, dynamic>>> response = Future.value([]);
  @override
  Future<List<Map<String, dynamic>>> list(String resource) => response;
}

void main() {
  test(
    'applied jobs are restored from saved applications after sign in',
    () async {
      final records = _Records()
        ..response = Future.value([
          {'job_key': 'published-job', 'status': 'submitted'},
        ]);
      final state = EmployeeController(
        auth: FakeAuthService(),
        records: records,
      );
      addTearDown(state.dispose);
      state.authenticated(const AuthAccount(uid: 'employee-1'));
      await state.refreshAppliedJobs();
      expect(state.applied, contains('published-job'));
      await state.signOut();
      expect(state.applied, isEmpty);
    },
  );

  test(
    'a pending refresh never adds applications to a different account',
    () async {
      final pending = Completer<List<Map<String, dynamic>>>();
      final records = _Records()..response = pending.future;
      final state = EmployeeController(
        auth: FakeAuthService(),
        records: records,
      );
      addTearDown(state.dispose);
      state.authenticated(const AuthAccount(uid: 'employee-1'));
      await state.signOut();
      records.response = Future.value([]);
      state.authenticated(const AuthAccount(uid: 'employee-2'));
      pending.complete([
        {'job_key': 'private-job'},
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(state.applied, isEmpty);
    },
  );
}

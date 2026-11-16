import 'package:flutter_test/flutter_test.dart';
import 'package:hr/models.dart';

void main() {
  test(
    'published job round trip preserves identity for edits and chat ownership',
    () {
      final original = Job(title: 'Developer', skills: ['Dart'])
        ..id = 'published-job-1'
        ..location = 'Remote'
        ..draft = false;
      final restored = Job.fromData({
        'id': original.id,
        ...original.toData('Career Connect'),
      });
      final edited = restored.copy()..title = 'Senior Developer';
      expect(edited.id, original.id);
      expect(edited.location, 'Remote');
      expect(edited.skills, ['Dart']);
      expect(edited.expiry.isAfter(edited.live), isTrue);
      // App input cannot select a different recruiter; the service supplies ownership.
      expect(edited.toData('Career Connect').containsKey('ownerUid'), isFalse);
    },
  );
}

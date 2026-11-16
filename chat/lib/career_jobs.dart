import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Job ownership always comes from the authenticated publisher.
class CareerJobs {
  CollectionReference<Map<String, dynamic>> get _jobs =>
      FirebaseFirestore.instance.collection('career_jobs');
  Stream<List<Map<String, dynamic>>> watch({bool owned = false}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (owned && uid == null) return Stream.value([]);
    final query = owned
        ? _jobs
              .where('ownerUid', isEqualTo: uid)
              .where('archived', isEqualTo: false)
        : _jobs
              .where('active', isEqualTo: true)
              .where('draft', isEqualTo: false);
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
    );
  }

  Future<String> save(Map<String, dynamic> data, {String? id}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to publish a job.');
    final doc = id == null ? _jobs.doc() : _jobs.doc(id);
    await doc.set({
      ...data,
      'ownerUid': uid,
      'archived': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // Keep recruiter ownership for already submitted applications and chat retries.
  Future<void> delete(String id) => _jobs.doc(id).update({
    'archived': true,
    'active': false,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

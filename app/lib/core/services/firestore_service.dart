import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/scan_result.dart';

const _recyclable = {'플라스틱', '종이류', '유리', '캔', '비닐', '스티로폼'};

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> saveScan(ScanResult result) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final batch = _db.batch();

    // 개인 스캔 기록
    final scanRef = _db.collection('scans').doc();
    batch.set(scanRef, {
      'uid': uid,
      'verdict': result.verdict,
      'condition': result.condition,
      'pollution': result.pollution,
      'recyclable': _recyclable.contains(result.verdict),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 글로벌 통계 atomic 업데이트
    final statsRef = _db.collection('stats').doc('global');
    batch.set(
      statsRef,
      {
        'totalScans': FieldValue.increment(1),
        'verdictCounts.${result.verdict}': FieldValue.increment(1),
        if (_recyclable.contains(result.verdict))
          'recyclableCount': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> globalStatsStream() {
    return _db.collection('stats').doc('global').snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> myScansStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('scans')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> deleteUserData(String uid) async {
    final scans = await _db.collection('scans').where('uid', isEqualTo: uid).get();
    final batch = _db.batch();
    for (final doc in scans.docs) {
      batch.delete(doc.reference);
    }
    if (scans.docs.isNotEmpty) await batch.commit();
  }
}

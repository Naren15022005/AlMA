import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  // ─── Usuario ────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>?> userStream(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => s.data());

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  // ─── Emparejamiento ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> linkCouple(String partnerCode) async {
    final myUid = uid!;

    final codeDoc = await _db.collection('pairCodes').doc(partnerCode.toUpperCase()).get();
    if (!codeDoc.exists) throw Exception('Código no encontrado');

    final partnerUid = codeDoc.data()!['userId'] as String;
    if (partnerUid == myUid) throw Exception('No puedes vincularte contigo mismo');

    final partnerDoc = await _db.collection('users').doc(partnerUid).get();
    if (partnerDoc.data()?['coupleId'] != null) throw Exception('Tu pareja ya está vinculada');

    final myDoc = await _db.collection('users').doc(myUid).get();
    if (myDoc.data()?['coupleId'] != null) throw Exception('Ya estás vinculado');

    final coupleRef = _db.collection('couples').doc();
    final coupleData = {
      'user1Id': myUid,
      'user2Id': partnerUid,
      'anniversary': null,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.set(coupleRef, coupleData);
    batch.update(_db.collection('users').doc(myUid), {'coupleId': coupleRef.id});
    batch.update(_db.collection('users').doc(partnerUid), {'coupleId': coupleRef.id});
    await batch.commit();

    return {'coupleId': coupleRef.id, ...coupleData};
  }

  Stream<Map<String, dynamic>?> coupleStream(String coupleId) => _db
      .collection('couples')
      .doc(coupleId)
      .snapshots()
      .map((s) => s.data());

  // ─── Referencia helper ──────────────────────────────────────────────────

  CollectionReference _coupleCol(String coupleId, String col) =>
      _db.collection('couples').doc(coupleId).collection(col);

  // ─── Cronograma ─────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> eventsStream(String coupleId) => _coupleCol(coupleId, 'events')
      .orderBy('startAt')
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList());

  Future<DocumentReference> createEvent(String coupleId, Map<String, dynamic> data) =>
      _coupleCol(coupleId, 'events').add({...data, 'createdBy': uid, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateEvent(String coupleId, String eventId, Map<String, dynamic> data) =>
      _coupleCol(coupleId, 'events').doc(eventId).update(data);

  Future<void> deleteEvent(String coupleId, String eventId) =>
      _coupleCol(coupleId, 'events').doc(eventId).delete();

  // ─── Series / Películas (pareja) ────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> seriesStream(String coupleId) =>
      _coupleCol(coupleId, 'series')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList());

  Future<DocumentReference> createSeries(String coupleId, Map<String, dynamic> data) =>
      _coupleCol(coupleId, 'series').add({...data, 'addedBy': uid, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateSeries(String coupleId, String id, Map<String, dynamic> data) =>
      _coupleCol(coupleId, 'series').doc(id).update(data);

  Future<void> deleteSeries(String coupleId, String id) =>
      _coupleCol(coupleId, 'series').doc(id).delete();

  // ─── Series personales (sin coupleId — subcollection users/{uid}/series/{id}) ─

  Stream<List<Map<String, dynamic>>> userSeriesStream(String userId) =>
      _db.collection('users').doc(userId).collection('series')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList());

  Future<DocumentReference> createUserSeries(String userId, Map<String, dynamic> data) =>
      _db.collection('users').doc(userId).collection('series')
          .add({...data, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateUserSeries(String userId, String id, Map<String, dynamic> data) =>
      _db.collection('users').doc(userId).collection('series').doc(id).update(data);

  Future<void> deleteUserSeries(String userId, String id) =>
      _db.collection('users').doc(userId).collection('series').doc(id).delete();

  // ─── Diario personal (sin coupleId) ─────────────────────────────────────

  Stream<List<Map<String, dynamic>>> userDiaryStream(String userId) =>
      _db.collection('users').doc(userId).collection('diary')
          .orderBy('entryDate', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList());

  Future<DocumentReference> createUserDiaryEntry(String userId, Map<String, dynamic> data) =>
      _db.collection('users').doc(userId).collection('diary')
          .add({...data, 'authorId': uid, 'createdAt': FieldValue.serverTimestamp()});

  // ─── Distancia ──────────────────────────────────────────────────────────

  Future<void> updateLocation(String userId, String coupleId, double lat, double lng) =>
      _db.collection('locations').doc(userId).set({
        'lat': lat, 'lng': lng, 'coupleId': coupleId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<Map<String, dynamic>?> locationStream(String userId) => _db
      .collection('locations')
      .doc(userId)
      .snapshots()
      .map((s) => s.data());

  // ─── Diario ─────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> diaryStream(String coupleId, String userId) => _coupleCol(coupleId, 'diary')
      .orderBy('entryDate', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .where((e) => e['isPrivate'] != true || e['authorId'] == userId)
          .toList());

  Future<DocumentReference> createDiaryEntry(String coupleId, Map<String, dynamic> data) =>
      _coupleCol(coupleId, 'diary').add({...data, 'authorId': uid, 'partnerReacted': false, 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateDiaryEntry(String coupleId, String entryId, Map<String, dynamic> data) =>
      _coupleCol(coupleId, 'diary').doc(entryId).update(data);

  Future<void> reactDiaryEntry(String coupleId, String entryId) =>
      _coupleCol(coupleId, 'diary').doc(entryId).update({'partnerReacted': true});

  Future<void> deleteDiaryEntry(String coupleId, String entryId) =>
      _coupleCol(coupleId, 'diary').doc(entryId).delete();

  // ─── Pensamientos ────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> thoughtsReceivedStream(String coupleId, String userId) =>
      _coupleCol(coupleId, 'thoughts')
          .where('recipientId', isEqualTo: userId)
          .where('isDelivered', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList());

  Stream<List<Map<String, dynamic>>> thoughtsSentStream(String coupleId, String userId) =>
      _coupleCol(coupleId, 'thoughts')
          .where('senderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList());

  Future<DocumentReference> createThought(String coupleId, String recipientId, Map<String, dynamic> data) {
    final deliverAt = data['deliverAt'] as Timestamp?;
    final isImmediate = deliverAt == null || deliverAt.toDate().isBefore(DateTime.now());
    final thoughtData = {
      ...data,
      'senderId': uid,
      'recipientId': recipientId,
      'isDelivered': isImmediate,
      'isRead': false,
      'isFavorite': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (coupleId == 'test_couple') {
      return _db.collection('users').doc(uid).collection('thoughts').add(thoughtData);
    }
    return _coupleCol(coupleId, 'thoughts').add(thoughtData);
  }

  Future<void> markThoughtRead(String coupleId, String thoughtId) =>
      _coupleCol(coupleId, 'thoughts').doc(thoughtId).update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});

  Future<void> toggleThoughtFavorite(String coupleId, String thoughtId, bool current) =>
      _coupleCol(coupleId, 'thoughts').doc(thoughtId).update({'isFavorite': !current});
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

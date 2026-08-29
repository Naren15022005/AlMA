import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  Future<String> uploadAvatar(Uint8List bytes, String filename) async {
    final ext = filename.split('.').last.toLowerCase();
    final ref = _storage.ref('users/$uid/avatar.$ext');
    final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
    return task.ref.getDownloadURL();
  }

  Future<String> uploadDiaryImage(String coupleId, Uint8List bytes, String filename) async {
    final ext = filename.split('.').last.toLowerCase();
    final ref = _storage.ref('couples/$coupleId/diary/${DateTime.now().millisecondsSinceEpoch}.$ext');
    final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
    return task.ref.getDownloadURL();
  }
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

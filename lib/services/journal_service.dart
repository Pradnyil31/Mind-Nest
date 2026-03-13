import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';
import 'firestore_service.dart';

class JournalService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  JournalService({FirebaseFirestore? firestore, FirestoreService? firestoreService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  // Collection reference
  CollectionReference get _journalCollection => _firestore.collection('journal_entries');

  // Add a new journal entry
  Future<void> addEntry(JournalEntry entry) async {
    try {
      DocumentReference docRef = _journalCollection.doc();
      final entryWithId = entry.copyWith(id: docRef.id);
      await docRef.set(entryWithId.toMap());

      // Log completion for badge system — only fires when entry is actually saved
      _firestoreService.logActivityCompletion(entry.userId, 'journaling');
    } catch (e) {
      throw 'Failed to add journal entry: $e';
    }
  }

  // Get entries for a user (Stream)
  Stream<List<JournalEntry>> getEntriesStream(String userId) {
    return _journalCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JournalEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Update an entry
  Future<void> updateEntry(JournalEntry entry) async {
    try {
      await _journalCollection.doc(entry.id).update(entry.toMap());
    } catch (e) {
      throw 'Failed to update journal entry: $e';
    }
  }

  // Delete an entry
  Future<void> deleteEntry(String entryId) async {
    try {
      await _journalCollection.doc(entryId).delete();
    } catch (e) {
      throw 'Failed to delete journal entry: $e';
    }
  }
}

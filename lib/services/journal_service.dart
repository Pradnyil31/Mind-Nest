import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _journalCollection => _firestore.collection('journal_entries');

  // Add a new journal entry
  Future<void> addEntry(JournalEntry entry) async {
    try {
      // Allow Firestore to generate the ID if not provided, or Use set if ID is managed manually.
      // Better to let Firestore generate ID for new entries.
      /* 
         If entry.id is empty or placeholder, we add to collection to get ID.
         But model demands ID. 
         Let's use doc().set() logic: 
         Generate a new doc ref, get ID, assign to entry, then save.
      */
      
      DocumentReference docRef = _journalCollection.doc();
      final entryWithId = entry.copyWith(id: docRef.id);
      
      await docRef.set(entryWithId.toMap());
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

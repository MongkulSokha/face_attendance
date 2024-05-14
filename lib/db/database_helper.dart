import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  static const collectionName = 'my_collection';

  Future<void> insert(Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection(collectionName).add(data);
    } catch (e) {
      print('Error inserting data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> queryAllDocuments() async {
    List<Map<String, dynamic>> documents = [];
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection(collectionName).get();
      querySnapshot.docs.forEach((doc) {
        documents.add(doc.data() as Map<String, dynamic>);
      });
    } catch (e) {
      print('Error querying data: $e');
    }
    return documents;
  }

  Future<int> queryDocumentCount() async {
    int count = 0;
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection(collectionName).get();
      count = querySnapshot.size;
    } catch (e) {
      print('Error querying document count: $e');
    }
    return count;
  }

  Future<void> update(String documentId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(documentId)
          .update(data);
    } catch (e) {
      print('Error updating document: $e');
    }
  }

  Future<void> delete(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(documentId)
          .delete();
    } catch (e) {
      print('Error deleting document: $e');
    }
  }
}

// lib/scripts/update_items.dart
// Run this once to add description field to all existing items
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  final items = await firestore.collection('items').get();
  
  print('📦 Updating ${items.docs.length} items...');
  
  for (var doc in items.docs) {
    final data = doc.data() as Map<String, dynamic>;
    if (!data.containsKey('description')) {
      await firestore.collection('items').doc(doc.id).update({
        'description': '',
      });
      print('✅ Updated: ${data['name']}');
    }
  }
  
  print('✅ All items updated!');
}
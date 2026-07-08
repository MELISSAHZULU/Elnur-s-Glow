import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _currentIndex = 1;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text('Inventory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('items').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    '${snapshot.data!.docs.length} pieces in collection',
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: '🔍 Search jewellery...',
                  hintStyle: TextStyle(color: AppColors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('items')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 70, color: AppColors.grey),
                          SizedBox(height: 16),
                          Text('Your collection is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          Text('Tap the + button to add your first piece', style: TextStyle(color: AppColors.grey)),
                        ],
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs;
                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      final name = (doc['name'] as String).toLowerCase();
                      final category = (doc['category'] as String).toLowerCase();
                      return name.contains(_searchQuery) || category.contains(_searchQuery);
                    }).toList();
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/item_detail', arguments: doc.id);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.goldLight,
                                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                                    ),
                                    child: data['photo_url'] != null && data['photo_url'].toString().isNotEmpty
                                        ? Image.network(data['photo_url'], fit: BoxFit.cover)
                                        : const Icon(Icons.circle_outlined, color: AppColors.gold, size: 50),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (data['stock_quantity'] ?? 0) <= 3 ? AppColors.red : AppColors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('${data['stock_quantity'] ?? 0} left', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(data['category'] ?? '', style: TextStyle(fontSize: 12, color: AppColors.grey)),
                                    const SizedBox(height: 4),
                                    Text(AppConstants.formatMwk(data['sell_price'] ?? 0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.gold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_item'),
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0: Navigator.pushReplacementNamed(context, '/home'); break;
            case 1: break;
            case 2: Navigator.pushReplacementNamed(context, '/sales'); break;
            case 3: Navigator.pushReplacementNamed(context, '/profile'); break;
          }
        },
      ),
    );
  }
}
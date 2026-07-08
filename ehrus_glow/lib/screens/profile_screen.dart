import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.charcoal),
        ),
      ),
      body: SingleChildScrollView(  // ← WRAPPED WITH SingleChildScrollView TO FIX OVERFLOW
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Business Name Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.goldLight,
                    child: Icon(Icons.store, size: 40, color: AppColors.gold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Ehur's Glow Accessories",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: Ehur',
                    style: TextStyle(color: AppColors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Currency: MWK (Malawi Kwacha)',
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats Cards
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('items').snapshots(),
              builder: (context, itemSnapshot) {
                int totalItems = itemSnapshot.hasData ? itemSnapshot.data!.docs.length : 0;
                int totalStock = 0;
                if (itemSnapshot.hasData) {
                  totalStock = itemSnapshot.data!.docs
                      .fold(0, (sum, doc) => sum + (doc['stock_quantity'] as int? ?? 0));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
                  builder: (context, txnSnapshot) {
                    int totalRevenue = 0;
                    if (txnSnapshot.hasData) {
                      for (var doc in txnSnapshot.data!.docs) {
                        totalRevenue += (doc['total_revenue'] as int? ?? 0);
                      }
                    }

                    return Row(
                      children: [
                        _buildProfileStat('Items', totalItems.toString()),
                        const SizedBox(width: 12),
                        _buildProfileStat('Stock', totalStock.toString()),
                        const SizedBox(width: 12),
                        _buildProfileStat('Revenue', AppConstants.formatMwk(totalRevenue)),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // Settings Options - FIXED ListTile issue
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(Icons.person, 'Owner Profile', () {}),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),
                  _buildSettingsTile(Icons.money, 'Change Currency', () {}),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),
                  _buildSettingsTile(Icons.notifications, 'Low Stock Alert (3 pieces)', () {}),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),
                  _buildSettingsTile(Icons.file_download, 'Export Sales Report', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📊 Report export feature coming soon!')),
                    );
                  }),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),
                  _buildSettingsTile(Icons.backup, 'Backup Data', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('💾 Data backed up to Firebase automatically!')),
                    );
                  }),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),
                  _buildSettingsTile(Icons.share, 'Share App', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📱 Share feature coming soon!')),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20), // Extra bottom padding
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0: Navigator.pushReplacementNamed(context, '/home'); break;
            case 1: Navigator.pushReplacementNamed(context, '/inventory'); break;
            case 2: Navigator.pushReplacementNamed(context, '/sales'); break;
            case 3: break;
          }
        },
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.grey)),
          ],
        ),
      ),
    );
  }

  // FIXED: Added Material wrapper to fix ListTile warning
  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey),
        onTap: onTap,
      ),
    );
  }
}
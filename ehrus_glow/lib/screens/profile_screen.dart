// lib/screens/profile_screen.dart - FULLY UPDATED WITH SIGN OUT
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';

// Import all the new screens
import 'owner_profile_screen.dart';
import 'change_currency_screen.dart';
import 'low_stock_alert_screen.dart';
import 'export_report_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3;
  bool _isLoading = false;

  // ============================================================
  // SIGN OUT
  // ============================================================
  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signOut();
        // AuthWrapper will automatically redirect to Login
        // No need to navigate manually
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // EXPORT SALES REPORT
  // ============================================================
  Future<void> _exportSalesReport() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('date_time', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sales data to export')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Calculate totals
      int totalRevenue = 0;
      int totalProfit = 0;
      for (var doc in snapshot.docs) {
        totalRevenue += (doc['total_revenue'] as int? ?? 0);
        totalProfit += (doc['total_profit'] as int? ?? 0);
      }

      // Create CSV data
      List<List<dynamic>> csvData = [
        ['Sales Report - Ehur\'s Glow Accessories'],
        ['Generated: ${DateTime.now().toString()}'],
        ['Total Sales: ${snapshot.docs.length}'],
        ['Total Revenue: ${AppConstants.formatMwk(totalRevenue)}'],
        ['Total Profit: ${AppConstants.formatMwk(totalProfit)}'],
        [],
        ['Date', 'Item', 'Category', 'Customer', 'Quantity', 'Unit Price (MWK)', 'Total (MWK)', 'Profit (MWK)']
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        csvData.add([
          (data['date_time'] as Timestamp).toDate().toString().split(' ')[0],
          data['item_name'] ?? '',
          data['category'] ?? '',
          data['customer_name'] ?? 'Walk-in',
          data['quantity'] ?? 1,
          data['unit_price'] ?? 0,
          data['total_revenue'] ?? 0,
          data['total_profit'] ?? 0,
        ]);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'sales_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      final csv = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csv);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '📊 Sales Report from Ehur\'s Glow Accessories\n\n'
              'Total Sales: ${snapshot.docs.length}\n'
              'Total Revenue: ${AppConstants.formatMwk(totalRevenue)}\n'
              'Total Profit: ${AppConstants.formatMwk(totalProfit)}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Report exported successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // BACKUP DATA
  // ============================================================
  Future<void> _backupData() async {
    setState(() => _isLoading = true);
    
    try {
      final itemsSnapshot = await FirebaseFirestore.instance.collection('items').get();
      final transactionsSnapshot = await FirebaseFirestore.instance.collection('transactions').get();
      final customersSnapshot = await FirebaseFirestore.instance.collection('customers').get();

      // Create backup file
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json');
      
      final backupData = {
        'items': itemsSnapshot.docs.map((d) => d.data()).toList(),
        'transactions': transactionsSnapshot.docs.map((d) => d.data()).toList(),
        'customers': customersSnapshot.docs.map((d) => d.data()).toList(),
        'backup_date': DateTime.now().toIso8601String(),
        'total_items': itemsSnapshot.docs.length,
        'total_transactions': transactionsSnapshot.docs.length,
        'total_customers': customersSnapshot.docs.length,
      };
      
      await backupFile.writeAsString(backupData.toString());

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('💾 Backup Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Items: ${itemsSnapshot.docs.length}'),
              Text('✅ Transactions: ${transactionsSnapshot.docs.length}'),
              Text('✅ Customers: ${customersSnapshot.docs.length}'),
              const SizedBox(height: 12),
              const Text(
                'Your data is safely backed up to Firebase Cloud.',
                style: TextStyle(fontSize: 13, color: Colors.green),
              ),
              const SizedBox(height: 4),
              Text(
                'Backup file saved locally at: ${backupFile.path}',
                style: TextStyle(fontSize: 11, color: AppColors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Share.shareXFiles(
                  [XFile(backupFile.path)],
                  text: '💾 Backup file from Ehur\'s Glow Accessories',
                );
              },
              child: const Text('Share Backup'),
            ),
          ],
        ),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error backing up: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // SHARE APP
  // ============================================================
  Future<void> _shareApp() async {
    await Share.share(
      '💎 Ehur\'s Glow Accessories\n\n'
      'A beautiful jewellery inventory and sales management app.\n'
      'Track stock, sales, revenue, and profit easily!\n\n'
      '✨ Features:\n'
      '• 📦 Inventory Management\n'
      '• 💰 Revenue & Profit Tracking\n'
      '• 👥 Customer Tracking\n'
      '• 📊 Sales Dashboard\n'
      '• 📅 Sales History\n'
      '• 📸 Photo Upload\n'
      '• 🔔 Low Stock Alerts\n\n'
      'Built with Flutter & Firebase 🚀\n\n'
      'Download now and grow your jewellery business!',
    );
  }

  // ============================================================
  // CHECK LOW STOCK
  // ============================================================
  Future<void> _checkLowStock() async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('profile')
          .get();
      
      int threshold = 3;
      if (profileDoc.exists) {
        final data = profileDoc.data() as Map<String, dynamic>;
        threshold = data['low_stock_alert'] ?? 3;
      }

      final items = await FirebaseFirestore.instance
          .collection('items')
          .where('stock_quantity', isLessThan: threshold)
          .get();
      
      if (items.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ No items are below the alert threshold!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Low Stock Items'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.docs.length,
              itemBuilder: (context, index) {
                final data = items.docs[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(data['name'] ?? 'Unknown'),
                  subtitle: Text(data['category'] ?? ''),
                  trailing: Text(
                    '${data['stock_quantity'] ?? 0} left',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/inventory');
              },
              child: const Text('Go to Inventory'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.charcoal),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ============================================================
            // USER INFO CARD
            // ============================================================
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.goldLight, AppColors.gold.withOpacity(0.3)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      user?.photoURL != null
                          ? Icons.person
                          : Icons.person_outline,
                      size: 40,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Ehur',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoal,
                          ),
                        ),
                        Text(
                          user?.email ?? 'No email',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '✅ Active',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ============================================================
            // BUSINESS NAME CARD
            // ============================================================
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
                  const Icon(
                    Icons.storefront,
                    size: 40,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Ehur's Glow Accessories",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
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

            // ============================================================
            // STATS CARDS
            // ============================================================
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

            // ============================================================
            // SETTINGS OPTIONS
            // ============================================================
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
                  // 1. Owner Profile
                  _buildSettingsTile(
                    Icons.person_outline,
                    'Owner Profile',
                    'Edit owner details',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OwnerProfileScreen()),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),

                  // 2. Change Currency
                  _buildSettingsTile(
                    Icons.currency_exchange,
                    'Change Currency',
                    'Change currency settings',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangeCurrencyScreen()),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),

                  // 3. Low Stock Alert
                  _buildSettingsTile(
                    Icons.notifications_outlined,
                    'Low Stock Alert',
                    'Current: 3 pieces',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LowStockAlertScreen()),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),

                  // 4. Export Sales Report
                  _buildSettingsTile(
                    Icons.file_download_outlined,
                    'Export Sales Report',
                    'Export as CSV',
                    _exportSalesReport,
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),

                  // 5. Backup Data
                  _buildSettingsTile(
                    Icons.backup_outlined,
                    'Backup Data',
                    'Automatic cloud backup',
                    _backupData,
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),

                  // 6. Share App
                  _buildSettingsTile(
                    Icons.share_outlined,
                    'Share App',
                    'Share with friends',
                    _shareApp,
                  ),
                  
                  // ============================================================
                  // 7. SIGN OUT (NEW!)
                  // ============================================================
                  const Divider(height: 1, thickness: 1, color: Colors.grey),
                  _buildSettingsTile(
                    Icons.logout,
                    'Sign Out',
                    'Sign out of your account',
                    _signOut,
                    isSignOut: true,  // ← Special styling
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ============================================================
            // FOOTER
            // ============================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, size: 16, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Text(
                        'Made with ❤️ for Ehur\'s Glow',
                        style: TextStyle(color: AppColors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.0.0 • Built with Flutter & Firebase',
                    style: TextStyle(color: AppColors.grey.withOpacity(0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/inventory');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/sales');
              break;
            case 3:
              break;
          }
        },
      ),
    );
  }

  // ============================================================
  // HELPER WIDGETS
  // ============================================================
  Widget _buildProfileStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldLight.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isSignOut = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSignOut
                ? Colors.red.withOpacity(0.1)
                : AppColors.goldLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSignOut ? Colors.red : AppColors.gold,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isSignOut ? Colors.red : AppColors.charcoal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isSignOut ? Colors.red.shade300 : AppColors.grey,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: isSignOut ? Colors.red.shade300 : AppColors.grey,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
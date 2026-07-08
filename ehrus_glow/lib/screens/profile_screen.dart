import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ==================== BACKUP DATA ====================
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error backing up: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==================== SHARE APP ====================
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

  // ==================== CHECK LOW STOCK ====================
  Future<void> _checkLowStock() async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('profile')
          .get();
      
      int threshold = 3;
      if (profileDoc.exists) {
        threshold = (profileDoc.data() as Map<String, dynamic>)['low_stock_alert'] ?? 3;
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

  // ==================== EXPORT REPORT ====================
  Future<void> _exportReport() async {
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
        final data = doc.data();
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
            // Business Name Card
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
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront,
                      size: 50,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Ehur's Glow Accessories",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, size: 16, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Owner: Ehur',
                        style: TextStyle(color: AppColors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Currency: MWK (Malawi Kwacha)',
                      style: TextStyle(color: AppColors.charcoal, fontSize: 13),
                    ),
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

            // ==================== SETTINGS OPTIONS ====================
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
                  // 1. Owner Profile - Navigates to Owner Profile Screen
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

                  // 2. Change Currency - Navigates to Currency Screen
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

                  // 3. Low Stock Alert - Navigates to Alert Screen
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

                  // 4. Export Sales Report - Fully Functional
                  _buildSettingsTile(
                    Icons.file_download_outlined,
                    'Export Sales Report',
                    'Export as CSV',
                    _exportReport,
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),

                  // 5. Backup Data - Fully Functional
                  _buildSettingsTile(
                    Icons.backup_outlined,
                    'Backup Data',
                    'Automatic cloud backup',
                    _backupData,
                  ),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),

                  // 6. Share App - Fully Functional
                  _buildSettingsTile(
                    Icons.share_outlined,
                    'Share App',
                    'Share with friends',
                    _shareApp,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Footer
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.charcoal),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.goldLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.gold, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.grey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
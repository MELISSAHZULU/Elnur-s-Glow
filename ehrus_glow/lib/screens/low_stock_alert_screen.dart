// lib/screens/low_stock_alert_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class LowStockAlertScreen extends StatefulWidget {
  const LowStockAlertScreen({super.key});

  @override
  State<LowStockAlertScreen> createState() => _LowStockAlertScreenState();
}

class _LowStockAlertScreenState extends State<LowStockAlertScreen> {
  int _alertThreshold = 3;
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  final List<int> _thresholdOptions = [1, 2, 3, 5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('profile')
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _alertThreshold = data['low_stock_alert'] ?? 3;
          _notificationsEnabled = data['notifications_enabled'] ?? true;
        });
      }
    } catch (e) {
      // Use defaults
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('profile')
          .set({
        'low_stock_alert': _alertThreshold,
        'notifications_enabled': _notificationsEnabled,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Update the items with the new threshold
      await _updateItemAlerts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Low stock alert settings saved!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateItemAlerts() async {
    try {
      final items = await FirebaseFirestore.instance.collection('items').get();
      for (var doc in items.docs) {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(doc.id)
            .update({
          'low_stock_alert': _alertThreshold,
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _checkLowStockItems() async {
    try {
      final items = await FirebaseFirestore.instance
          .collection('items')
          .where('stock_quantity', isLessThan: _alertThreshold)
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
                Navigator.pushNamed(context, '/inventory');
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Low Stock Alert',
          style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.orange.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Alert Level',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          '$_alertThreshold pieces',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _checkLowStockItems,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Check Now'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Set Alert Threshold',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will be notified when stock falls below this number',
              style: TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            
            // Threshold Selection
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _thresholdOptions.map((value) {
                return FilterChip(
                  label: Text(value.toString()),
                  selected: _alertThreshold == value,
                  onSelected: (selected) {
                    setState(() => _alertThreshold = value);
                  },
                  selectedColor: AppColors.gold,
                  labelStyle: TextStyle(
                    color: _alertThreshold == value ? Colors.white : AppColors.charcoal,
                    fontWeight: _alertThreshold == value ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Notifications Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Get alerts when stock is low'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
                activeColor: AppColors.gold,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.goldLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Preview - Items Below Threshold',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('items')
                        .where('stock_quantity', isLessThan: _alertThreshold)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Loading...', style: TextStyle(color: AppColors.grey));
                      }
                      
                      if (snapshot.data!.docs.isEmpty) {
                        return const Text(
                          '✅ No items are low in stock',
                          style: TextStyle(color: Colors.green),
                        );
                      }
                      
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(data['name'] ?? 'Unknown'),
                            trailing: Text(
                              '${data['stock_quantity'] ?? 0} left',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        '🔔 Save Alert Settings',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
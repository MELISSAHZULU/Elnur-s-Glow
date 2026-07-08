// lib/screens/export_report_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../utils/constants.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  bool _isExporting = false;
  String _selectedPeriod = 'This Month';
  String _exportMessage = '';
  bool _exportSuccess = false;

  final List<String> _periods = ['Today', 'This Week', 'This Month', 'All Time'];

  Future<void> _exportReport() async {
    setState(() {
      _isExporting = true;
      _exportMessage = 'Generating report...';
      _exportSuccess = false;
    });

    try {
      DateTime startDate = _getStartDate();
      Query query = FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('date_time', descending: true);

      if (_selectedPeriod != 'All Time') {
        query = query.where('date_time', isGreaterThan: startDate);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _exportMessage = 'No sales data to export for selected period';
          _isExporting = false;
        });
        return;
      }

      // Calculate totals
      int totalRevenue = 0;
      int totalProfit = 0;
      int totalItems = 0;
      Map<String, int> categoryCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;  // ← FIX: Cast to Map
        totalRevenue += (data['total_revenue'] as int? ?? 0);
        totalProfit += (data['total_profit'] as int? ?? 0);
        totalItems += (data['quantity'] as int? ?? 1);
        
        final category = data['category'] ?? 'Uncategorized';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      // Create CSV data
      List<List<dynamic>> csvData = [
        ['Sales Report - Ehur\'s Glow Accessories'],
        ['Period: ${_selectedPeriod}', 'Generated: ${DateTime.now().toString()}'],
        [],
        ['Date', 'Item', 'Category', 'Customer', 'Quantity', 'Unit Price (MWK)', 'Total (MWK)', 'Profit (MWK)']
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;  // ← FIX: Cast to Map
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

      // Add summary
      csvData.add([]);
      csvData.add(['SUMMARY']);
      csvData.add(['Total Sales', snapshot.docs.length]);
      csvData.add(['Total Items Sold', totalItems]);
      csvData.add(['Total Revenue', AppConstants.formatMwk(totalRevenue)]);
      csvData.add(['Total Profit', AppConstants.formatMwk(totalProfit)]);
      csvData.add(['Average Profit per Sale', AppConstants.formatMwk(totalProfit ~/ snapshot.docs.length)]);
      
      // Add category breakdown
      csvData.add([]);
      csvData.add(['Category Breakdown']);
      categoryCounts.forEach((category, count) {
        csvData.add([category, '$count sales']);
      });

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
              'Period: $_selectedPeriod\n'
              'Total Sales: ${snapshot.docs.length}\n'
              'Total Revenue: ${AppConstants.formatMwk(totalRevenue)}\n'
              'Total Profit: ${AppConstants.formatMwk(totalProfit)}',
      );

      setState(() {
        _exportMessage = '✅ Report exported successfully!';
        _exportSuccess = true;
        _isExporting = false;
      });

    } catch (e) {
      setState(() {
        _exportMessage = 'Error exporting report: $e';
        _isExporting = false;
        _exportSuccess = false;
      });
    }
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'All Time':
        return DateTime(2000);
      default:
        return DateTime(now.year, now.month, 1);
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
          'Export Sales Report',
          style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.goldLight, AppColors.gold.withOpacity(0.15)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.analytics, size: 40, color: AppColors.gold),
                  SizedBox(height: 8),
                  Text(
                    'Export your sales data',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Choose your period and format',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Period Selection
            const Text(
              'Select Period',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _periods.map((period) {
                  return ChoiceChip(
                    label: Text(period),
                    selected: _selectedPeriod == period,
                    onSelected: (selected) {
                      setState(() => _selectedPeriod = period);
                    },
                    selectedColor: AppColors.gold,
                    labelStyle: TextStyle(
                      color: _selectedPeriod == period ? Colors.white : AppColors.charcoal,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Export Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isExporting ? null : _exportReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isExporting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Exporting...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.file_download, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            '📊 Export Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Status Message
            if (_exportMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _exportSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _exportSuccess ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _exportMessage,
                  style: TextStyle(
                    color: _exportSuccess ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 What\'s included:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('All sales transactions'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Revenue and profit totals'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Customer names'),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Category breakdown'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
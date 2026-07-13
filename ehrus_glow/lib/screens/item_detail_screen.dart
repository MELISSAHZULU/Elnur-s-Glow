// lib/screens/item_detail_screen.dart - WITH EDIT & DELETE
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../models/item_model.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int _quantity = 1;
  TextEditingController _customerController = TextEditingController();
  List<String> _customerSuggestions = [];
  bool _isSelling = false;
  bool _isRestocking = false;
  bool _isDeleting = false;

  // ============================================================
  // EDIT ITEM - Navigate to Edit Screen
  // ============================================================
  Future<void> _editItem(Item item) async {
    // Show a simple edit dialog
    final nameController = TextEditingController(text: item.name);
    final costController = TextEditingController(text: item.costPrice.toString());
    final sellController = TextEditingController(text: item.sellPrice.toString());
    final stockController = TextEditingController(text: item.stockQuantity.toString());
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✏️ Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Cost Price (MWK)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sellController,
                decoration: const InputDecoration(labelText: 'Selling Price (MWK)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(widget.itemId)
            .update({
          'name': nameController.text.trim(),
          'cost_price': int.parse(costController.text),
          'sell_price': int.parse(sellController.text),
          'profit': int.parse(sellController.text) - int.parse(costController.text),
          'stock_quantity': int.parse(stockController.text),
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Item updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ============================================================
  // DELETE ITEM
  // ============================================================
  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isDeleting = true);
      
      try {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(widget.itemId)
            .delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Item deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isDeleting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ============================================================
  // SELL ITEM
  // ============================================================
  Future<void> _sellItem(Item item) async {
    if (item.stockQuantity < _quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough stock! Only ${item.stockQuantity} left.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_customerController.text.trim().isEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Customer Name'),
          content: const Text('Sell to walk-in customer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Sell'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSelling = true);

    try {
      String customerName = _customerController.text.trim();
      String? customerId;

      if (customerName.isNotEmpty) {
        var existingCustomer = await FirebaseFirestore.instance
            .collection('customers')
            .where('name', isEqualTo: customerName)
            .limit(1)
            .get();

        if (existingCustomer.docs.isEmpty) {
          var newCustomer = await FirebaseFirestore.instance
              .collection('customers')
              .add({
            'name': customerName,
            'total_spent': 0,
            'last_purchase_date': FieldValue.serverTimestamp(),
            'created_at': FieldValue.serverTimestamp(),
          });
          customerId = newCustomer.id;
        } else {
          customerId = existingCustomer.docs.first.id;
        }
      }

      int totalRevenue = item.sellPrice * _quantity;
      int totalProfit = item.profit * _quantity;

      await FirebaseFirestore.instance.collection('transactions').add({
        'item_id': widget.itemId,
        'item_name': item.name,
        'category': item.category,
        'customer_id': customerId,
        'customer_name': customerName.isNotEmpty ? customerName : 'Walk-in',
        'quantity': _quantity,
        'unit_price': item.sellPrice,
        'total_revenue': totalRevenue,
        'cost_price': item.costPrice,
        'total_profit': totalProfit,
        'date_time': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.itemId)
          .update({
        'stock_quantity': item.stockQuantity - _quantity,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (customerId != null) {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(customerId)
            .update({
          'total_spent': FieldValue.increment(totalRevenue),
          'last_purchase_date': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Sold $_quantity ${item.name} for ${AppConstants.formatMwk(totalRevenue)}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSelling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // RESTOCK ITEM
  // ============================================================
  Future<void> _restockItem(Item item) async {
    int addQty = 0;
    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Restock Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current stock: ${item.stockQuantity}'),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'How many to add?',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    addQty = int.tryParse(value) ?? 0;
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'New stock will be: ${item.stockQuantity + addQty}',
                  style: TextStyle(
                    color: addQty > 0 ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: addQty > 0 ? () => Navigator.pop(context, addQty) : null,
                style: TextButton.styleFrom(
                  foregroundColor: addQty > 0 ? AppColors.gold : Colors.grey,
                ),
                child: const Text('Add Stock'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null || result <= 0) return;

    setState(() => _isRestocking = true);

    try {
      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.itemId)
          .update({
        'stock_quantity': item.stockQuantity + result,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Added $result items to ${item.name}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isRestocking = false);
      }
    } catch (e) {
      setState(() => _isRestocking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCustomerSuggestions();
  }

  void _loadCustomerSuggestions() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .orderBy('name')
          .limit(10)
          .get();
      
      setState(() {
        _customerSuggestions = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      // Silently fail
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
          'Item Details',
          style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w600),
        ),
        actions: [
          // ============================================================
          // EDIT BUTTON
          // ============================================================
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.gold),
            onPressed: () async {
              final doc = await FirebaseFirestore.instance
                  .collection('items')
                  .doc(widget.itemId)
                  .get();
              if (doc.exists) {
                _editItem(Item.fromFirestore(doc));
              }
            },
            tooltip: 'Edit Item',
          ),
          // ============================================================
          // DELETE BUTTON
          // ============================================================
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isDeleting ? null : _deleteItem,
            tooltip: 'Delete Item',
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('items')
            .doc(widget.itemId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Item not found'));
          }

          Item item = Item.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: AppColors.gold,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  item.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                ),
                const SizedBox(height: 8),
                Text(
                  item.category,
                  style: TextStyle(fontSize: 14, color: AppColors.grey),
                ),
                const SizedBox(height: 20),

                // Cost, Price, Profit
                Row(
                  children: [
                    _buildInfoCard('COST', item.formattedCostPrice, Colors.grey),
                    const SizedBox(width: 12),
                    _buildInfoCard('PRICE', item.formattedSellPrice, AppColors.gold),
                    const SizedBox(width: 12),
                    _buildInfoCard('PROFIT', '+${item.formattedProfit}', Colors.green),
                  ],
                ),
                const SizedBox(height: 20),

                // Stock
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STOCK: ${item.stockQuantity} remaining',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: item.isLowStock ? Colors.red : AppColors.charcoal,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isRestocking ? null : () => _restockItem(item),
                        icon: _isRestocking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add, size: 18),
                        label: Text(_isRestocking ? 'Adding...' : 'Restock'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 16),

                // SELL Section
                const Text(
                  'SELL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                ),
                const SizedBox(height: 12),

                // Quantity selector
                Row(
                  children: [
                    const Text('Quantity', style: TextStyle(fontSize: 14, color: AppColors.grey)),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.goldLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 20),
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(
                            width: 40,
                            child: Center(
                              child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: _quantity < item.stockQuantity ? () => setState(() => _quantity++) : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Customer Name
                const Text('Customer Name (Optional)', style: TextStyle(fontSize: 14, color: AppColors.grey)),
                const SizedBox(height: 4),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _customerSuggestions.where((option) =>
                        option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (value) => _customerController.text = value,
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    _customerController = controller;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search or enter customer name',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Sell Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSelling ? null : () => _sellItem(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSelling
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'SELL - ${AppConstants.formatMwk(item.sellPrice * _quantity)}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Necklace': return Icons.circle_outlined;
      case 'Ring': return Icons.circle;
      case 'Earrings': return Icons.bolt;
      case 'Bracelet': return Icons.timeline;
      case 'Anklet': return Icons.settings_ethernet;
      default: return Icons.category_outlined;
    }
  }
}
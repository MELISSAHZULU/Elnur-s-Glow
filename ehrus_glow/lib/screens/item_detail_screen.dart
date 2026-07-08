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
  bool _isLoading = false;

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

    setState(() => _isLoading = true);

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Sold $_quantity ${item.name} for ${AppConstants.formatMwk(totalRevenue)}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selling item: $e'),
          backgroundColor: Colors.red,
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Item Details',
          style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w600),
        ),
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
                // Image
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(20),
                    image: item.photoUrl != null && item.photoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item.photoUrl == null || item.photoUrl!.isEmpty
                      ? const Icon(Icons.image_outlined, color: AppColors.gold, size: 70)
                      : null,
                ),
                const SizedBox(height: 20),

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
                        onPressed: () {
                          // Restock logic
                          showDialog(
                            context: context,
                            builder: (context) {
                              int addQty = 0;
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
                                      onChanged: (value) => addQty = int.tryParse(value) ?? 0,
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      if (addQty > 0) {
                                        await FirebaseFirestore.instance
                                            .collection('items')
                                            .doc(widget.itemId)
                                            .update({
                                          'stock_quantity': item.stockQuantity + addQty,
                                        });
                                        Navigator.pop(context);
                                        setState(() {});
                                      }
                                    },
                                    child: const Text('Add Stock'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Restock'),
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
                    onPressed: _isLoading ? null : () => _sellItem(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
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
}
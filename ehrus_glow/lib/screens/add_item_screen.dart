// lib/screens/add_item_screen.dart - WITH DESCRIPTION FIELD
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();  // ← NEW
  String _selectedCategory = 'Necklace';
  final _costPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();
  
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _categories = ['Necklace', 'Ring', 'Earrings', 'Bracelet', 'Anklet', 'Other'];

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      final itemData = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),  // ← NEW
        'cost_price': int.parse(_costPriceController.text),
        'sell_price': int.parse(_sellPriceController.text),
        'profit': int.parse(_sellPriceController.text) - int.parse(_costPriceController.text),
        'stock_quantity': int.parse(_stockController.text),
        'photo_url': null,
        'low_stock_alert': 3,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await FirebaseFirestore.instance.collection('items').add(itemData);
      print('✅ Item saved successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      print('❌ Save error: $e');
      setState(() {
        _isSaving = false;
        _errorMessage = 'Error: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          onPressed: () {
            if (!_isSaving) Navigator.pop(context);
          },
        ),
        title: const Text(
          'Add New Item',
          style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                  SizedBox(height: 16),
                  Text('Saving your item... ✨'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Name
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          hintText: 'e.g., Rose Gold Crystal Brooch',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 16),

                      // ============================================================
                      // NEW: Description Field
                      // ============================================================
                      TextFormField(
                        controller: _descriptionController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'e.g., Rose gold plated with crystal center, 2 inches',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,  // Allows up to 3 lines
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category_outlined),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  size: 18,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 8),
                                Text(category),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _isSaving ? null : (value) => setState(() => _selectedCategory = value!),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _costPriceController,
                              enabled: !_isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Cost Price *',
                                hintText: 'e.g., 172500',
                                border: OutlineInputBorder(),
                                prefixText: 'MK ',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value!.isEmpty ? 'Enter cost price' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _sellPriceController,
                              enabled: !_isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Selling Price *',
                                hintText: 'e.g., 460000',
                                border: OutlineInputBorder(),
                                prefixText: 'MK ',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value!.isEmpty ? 'Enter selling price' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _stockController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity *',
                          hintText: 'e.g., 1 (for unique pieces)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_outlined),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Enter stock quantity' : null,
                      ),
                      const SizedBox(height: 24),

                      // Preview Profit
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.goldLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Profit per item:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              AppConstants.formatMwk(
                                (int.tryParse(_sellPriceController.text) ?? 0) - 
                                (int.tryParse(_costPriceController.text) ?? 0)
                              ),
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tip for unique pieces
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '💡 Tip: Enter each unique piece separately with Stock: 1 for better tracking.',
                                style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '💎 Save Item',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();  // ← NEW
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}
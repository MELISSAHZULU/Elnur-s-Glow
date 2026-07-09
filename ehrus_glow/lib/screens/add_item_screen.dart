// lib/screens/add_item_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import '../utils/constants.dart';
import '../services/cloudinary_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCategory = 'Necklace';
  final _costPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();
  
  bool _isSaving = false;
  String? _errorMessage;
  int _uploadProgress = 0;
  bool _isUploading = false;
  
  Uint8List? _imageBytes;
  String? _imageName;

  final List<String> _categories = ['Necklace', 'Ring', 'Earrings', 'Bracelet', 'Anklet', 'Other'];

  Future<void> _pickImage() async {
    if (_isSaving) return;
    
    try {
      final input = html.FileUploadInputElement();
      input.accept = 'image/*';
      input.multiple = false;
      input.click();
      
      await input.onChange.first;
      
      if (input.files == null || input.files!.isEmpty) return;
      
      final file = input.files![0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      
      await reader.onLoad.first;
      
      final bytes = reader.result as Uint8List;
      
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
      
      print('📸 Image picked: ${file.name}, size: ${bytes.length} bytes');
      
    } catch (e) {
      print('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error picking image'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _isUploading = false;
      _uploadProgress = 0;
    });
    
    try {
      String? photoUrl;
      
      if (_imageBytes != null) {
        setState(() {
          _isUploading = true;
        });
        
        for (int i = 0; i <= 100; i += 10) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            setState(() => _uploadProgress = i);
          }
        }
        
        final cleanName = 'jewellery_${DateTime.now().millisecondsSinceEpoch}';
        photoUrl = await CloudinaryService.uploadBytes(_imageBytes!, cleanName);
        
        setState(() {
          _isUploading = false;
          _uploadProgress = 100;
        });
        
        if (photoUrl == null) {
          setState(() {
            _isSaving = false;
            _errorMessage = 'Failed to upload image. Please try again.';
          });
          return;
        }
      }

      final itemData = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'description': '',
        'cost_price': int.parse(_costPriceController.text),
        'sell_price': int.parse(_sellPriceController.text),
        'profit': int.parse(_sellPriceController.text) - int.parse(_costPriceController.text),
        'stock_quantity': int.parse(_stockController.text),
        'photo_url': photoUrl,
        'low_stock_alert': 3,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await FirebaseFirestore.instance.collection('items').add(itemData);
      print('✅ Item saved successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _imageBytes != null 
                ? '✅ Item added with photo!' 
                : '✅ Item added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      print('❌ Save error: $e');
      setState(() {
        _isSaving = false;
        _isUploading = false;
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
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    super.dispose();
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
        actions: [
          if (_imageBytes != null && !_isSaving)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => setState(() {
                _imageBytes = null;
                _imageName = null;
              }),
            ),
        ],
      ),
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isUploading) ...[
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '📸 Uploading image... $_uploadProgress%',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _uploadProgress / 100,
                        backgroundColor: AppColors.goldLight,
                        color: AppColors.gold,
                      ),
                    ),
                  ] else ...[
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Saving your item... ✨',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
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
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _imageBytes != null ? AppColors.gold : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: _imageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(
                                        _imageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '📸 ${_imageName ?? "Image"}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      color: AppColors.gold,
                                      size: 50,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '📸 Tap to add photo',
                                      style: TextStyle(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Uploaded to Cloudinary (FREE)',
                                      style: TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

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

                      TextFormField(
                        controller: _nameController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          hintText: 'e.g., Gold Floral Necklace',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 16),

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
                          labelText: 'Initial Stock *',
                          hintText: 'e.g., 10',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_outlined),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Enter stock quantity' : null,
                      ),
                      const SizedBox(height: 24),

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

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_upload, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '📸 Photos uploaded to Cloudinary (FREE) - 25GB storage included!',
                                style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

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
}
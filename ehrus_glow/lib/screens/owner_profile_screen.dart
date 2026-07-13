// lib/screens/owner_profile_screen.dart - WITHOUT IMAGE PICKER
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _selectedCurrency = 'MWK';
  int _lowStockAlert = 3;

  final List<String> _currencies = ['MWK', 'USD', 'EUR', 'GBP', 'ZAR', 'KES', 'TZS', 'UGX', 'NGN', 'GHS'];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('profile')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Loading timed out. Please check your connection.'),
          );
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['owner_name'] ?? 'Ehur';
        _businessController.text = data['business_name'] ?? "Ehur's Glow Accessories";
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _addressController.text = data['address'] ?? '';
        _selectedCurrency = data['currency'] ?? 'MWK';
        _lowStockAlert = data['low_stock_alert'] ?? 3;
      }
    } catch (e) {
      _nameController.text = 'Ehur';
      _businessController.text = "Ehur's Glow Accessories";
      _phoneController.text = '';
      _emailController.text = '';
      _addressController.text = '';
      _selectedCurrency = 'MWK';
      _lowStockAlert = 3;
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load profile data. Using defaults.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('profile')
          .set({
        'owner_name': _nameController.text.trim(),
        'business_name': _businessController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'currency': _selectedCurrency,
        'low_stock_alert': _lowStockAlert,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true))
      .timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Save timed out. Please check your connection.'),
      );
      
      await _updateItemAlerts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isSaving = false;
      });
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

  Future<void> _updateItemAlerts() async {
    try {
      final items = await FirebaseFirestore.instance
          .collection('items')
          .get()
          .timeout(const Duration(seconds: 10));
      
      for (var doc in items.docs) {
        await FirebaseFirestore.instance
            .collection('items')
            .doc(doc.id)
            .update({
          'low_stock_alert': _lowStockAlert,
        }).timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      // Silently fail - not critical
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
          'Owner Profile',
          style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isSaving)
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
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ============================================================
                    // PROFILE PHOTO - PLACEHOLDER (No image picker)
                    // ============================================================
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.gold, AppColors.goldLight],
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.goldLight,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Owner Profile',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Error Message
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
                    
                    // Owner Name
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name *',
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Business Name
                    TextFormField(
                      controller: _businessController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Business Name *',
                        hintText: 'Enter your business name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store_outlined),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter business name' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'e.g., +265 888 123 456',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'your@email.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    // Address
                    TextFormField(
                      controller: _addressController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Business Address',
                        hintText: 'Enter your business address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    // Currency Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_exchange),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _currencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: _isSaving ? null : (value) {
                        setState(() => _selectedCurrency = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Low Stock Alert
                    DropdownButtonFormField<int>(
                      value: _lowStockAlert,
                      decoration: const InputDecoration(
                        labelText: 'Low Stock Alert *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notifications_outlined),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [1, 2, 3, 5, 10, 15, 20].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text('$value pieces'),
                        );
                      }).toList(),
                      onChanged: _isSaving ? null : (value) {
                        setState(() => _lowStockAlert = value!);
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Saving...',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    '💾 Save Profile',
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
                    
                    const SizedBox(height: 12),
                    
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your profile information is stored securely in Firebase Cloud.',
                              style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Business Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.goldLight),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.gold),
                              const SizedBox(width: 8),
                              const Text(
                                'Business Summary',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryItem('Currency', _selectedCurrency),
                              _buildSummaryItem('Low Stock Alert', '$_lowStockAlert pieces'),
                            ],
                          ),
                          if (_phoneController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem('Phone', _phoneController.text),
                                _buildSummaryItem('Email', _emailController.text.isNotEmpty ? _emailController.text : 'Not set'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
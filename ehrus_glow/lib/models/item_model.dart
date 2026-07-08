import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class Item {
  String? id;
  String name;
  String category;
  String description;
  int costPrice;
  int sellPrice;
  int profit;
  int stockQuantity;
  String? photoUrl;
  int lowStockAlert;
  Timestamp createdAt;
  Timestamp updatedAt;

  Item({
    this.id,
    required this.name,
    required this.category,
    this.description = '',
    required this.costPrice,
    required this.sellPrice,
    required this.stockQuantity,
    this.photoUrl,
    this.lowStockAlert = 3,
    required this.createdAt,
    required this.updatedAt,
  }) : profit = sellPrice - costPrice;

  factory Item.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Item(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      costPrice: data['cost_price'] ?? 0,
      sellPrice: data['sell_price'] ?? 0,
      stockQuantity: data['stock_quantity'] ?? 0,
      photoUrl: data['photo_url'],
      lowStockAlert: data['low_stock_alert'] ?? 3,
      createdAt: data['created_at'] ?? Timestamp.now(),
      updatedAt: data['updated_at'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'profit': profit,
      'stock_quantity': stockQuantity,
      'photo_url': photoUrl,
      'low_stock_alert': lowStockAlert,
      'created_at': createdAt,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  String get formattedCostPrice => AppConstants.formatMwk(costPrice);
  String get formattedSellPrice => AppConstants.formatMwk(sellPrice);
  String get formattedProfit => AppConstants.formatMwk(profit);
  bool get isLowStock => stockQuantity <= lowStockAlert;
}
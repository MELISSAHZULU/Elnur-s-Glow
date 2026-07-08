import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class Transaction {
  String? id;
  String itemId;
  String itemName;
  String? customerId;
  String customerName;
  int quantity;
  int unitPrice;
  int totalRevenue;
  int costPrice;
  int totalProfit;
  Timestamp dateTime;

  Transaction({
    this.id,
    required this.itemId,
    required this.itemName,
    this.customerId,
    required this.customerName,
    required this.quantity,
    required this.unitPrice,
    required this.totalRevenue,
    required this.costPrice,
    required this.totalProfit,
    required this.dateTime,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      itemId: data['item_id'] ?? '',
      itemName: data['item_name'] ?? '',
      customerId: data['customer_id'],
      customerName: data['customer_name'] ?? 'Walk-in',
      quantity: data['quantity'] ?? 1,
      unitPrice: data['unit_price'] ?? 0,
      totalRevenue: data['total_revenue'] ?? 0,
      costPrice: data['cost_price'] ?? 0,
      totalProfit: data['total_profit'] ?? 0,
      dateTime: data['date_time'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'customer_id': customerId,
      'customer_name': customerName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_revenue': totalRevenue,
      'cost_price': costPrice,
      'total_profit': totalProfit,
      'date_time': dateTime,
    };
  }

  String get formattedTotal => AppConstants.formatMwk(totalRevenue);
  String get formattedProfit => AppConstants.formatMwk(totalProfit);
}
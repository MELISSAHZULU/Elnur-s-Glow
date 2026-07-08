import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: TextStyle(
                  color: AppColors.charcoal.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_greeting, Ehur 🪙',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '"Alright, T\'iswolox. News."',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),

              // Stats Cards
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('items').snapshots(),
                builder: (context, itemSnapshot) {
                  int totalStock = 0;
                  if (itemSnapshot.hasData) {
                    totalStock = itemSnapshot.data!.docs
                        .fold(0, (sum, doc) => sum + (doc['stock_quantity'] as int? ?? 0));
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('date_time', isGreaterThan: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ))
                        .snapshots(),
                    builder: (context, txnSnapshot) {
                      int todayRevenue = 0;
                      int todayProfit = 0;
                      
                      if (txnSnapshot.hasData) {
                        for (var doc in txnSnapshot.data!.docs) {
                          todayRevenue += (doc['total_revenue'] as int? ?? 0);
                          todayProfit += (doc['total_profit'] as int? ?? 0);
                        }
                      }

                      return Row(
                        children: [
                          _buildStatCard('Total Stock', totalStock.toString(), AppColors.gold, Icons.inventory_2_outlined),
                          const SizedBox(width: 12),
                          _buildStatCard('Revenue', AppConstants.formatMwk(todayRevenue), AppColors.charcoal, Icons.attach_money),
                          const SizedBox(width: 12),
                          _buildStatCard('My Profit', AppConstants.formatMwk(todayProfit), Colors.green.shade700, Icons.trending_up),
                        ],
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 24),

              // Quick Search
              const Text(
                'QUICK SELL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/inventory'),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.grey),
                      const SizedBox(width: 12),
                      Text(
                        '🔍 Try "Gold Hoop" or "Pearl"...',
                        style: TextStyle(color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Today's Sales Header
              const Text(
                'TODAY\'S SALES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('date_time', isGreaterThan: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ))
                      .orderBy('date_time', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hourglass_empty, size: 50, color: AppColors.grey),
                            SizedBox(height: 12),
                            Text('No sales today yet', style: TextStyle(color: AppColors.grey, fontSize: 16)),
                            Text('Start selling your beautiful pieces! ✨', style: TextStyle(color: AppColors.grey, fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.goldLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.circle_outlined, color: AppColors.gold, size: 30),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['item_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    Row(
                                      children: [
                                        Text(data['customer_name'] ?? 'Walk-in', style: TextStyle(fontSize: 13, color: AppColors.grey)),
                                        const SizedBox(width: 8),
                                        Text('•', style: TextStyle(color: AppColors.grey)),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('h:mm a').format((data['date_time'] as Timestamp).toDate()),
                                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                AppConstants.formatMwk(data['total_revenue'] ?? 0),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.charcoal),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0: break;
            case 1: Navigator.pushReplacementNamed(context, '/inventory'); break;
            case 2: Navigator.pushReplacementNamed(context, '/sales'); break;
            case 3: Navigator.pushReplacementNamed(context, '/profile'); break;
          }
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
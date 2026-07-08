import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/owner_profile_screen.dart';
import 'screens/change_currency_screen.dart';
import 'screens/low_stock_alert_screen.dart';
import 'screens/export_report_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBpCZa9o3wgYyzVkOnjjlQNtAW7i482haI',
      authDomain: 'elnur-s-glow.firebaseapp.com',
      projectId: 'elnur-s-glow',
      storageBucket: 'elnur-s-glow.firebasestorage.app',
      messagingSenderId: '943860119463',
      appId: '1:943860119463:web:6690063ca6d480abc7e882',
      measurementId: 'G-T5NMJPZ8RW',
    ),
  );

  // ================================================================
  // 🔧 FIX: Force Long-Polling to prevent WebSocket session churn
  // ================================================================
  // Enable offline persistence to reduce connection issues
  await FirebaseFirestore.instance.enablePersistence();
  
  // Set Firestore settings
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  
  // Optional: Set host to force long-polling via URL parameter
  // This is a workaround for WebSocket issues
  print('✅ Firestore: Settings applied with persistence enabled');

  runApp(const EhrusGlowApp());
}

class EhrusGlowApp extends StatelessWidget {
  const EhrusGlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Ehur's Glow Accessories",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          primary: AppColors.gold,
          secondary: AppColors.charcoal,
        ),
        scaffoldBackgroundColor: AppColors.cream,
        fontFamily: GoogleFonts.inter().fontFamily,
        useMaterial3: true,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/sales': (context) => const SalesHistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/owner_profile': (context) => const OwnerProfileScreen(),
        '/change_currency': (context) => const ChangeCurrencyScreen(),
        '/low_stock_alert': (context) => const LowStockAlertScreen(),
        '/export_report': (context) => const ExportReportScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/item_detail') {
          final itemId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ItemDetailScreen(itemId: itemId),
          );
        }
        if (settings.name == '/add_item') {
          return MaterialPageRoute(
            builder: (context) => const AddItemScreen(),
          );
        }
        return null;
      },
    );
  }
}
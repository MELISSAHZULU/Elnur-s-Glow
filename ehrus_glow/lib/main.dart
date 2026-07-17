// lib/main.dart - UPDATED WITH YOUR NEW FIREBASE CONFIG
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
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
  
  // ============================================================
  // 🔧 FIX: Use the UPDATED web config from Firebase Console
  // ============================================================
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBpCZa9o3wgYyzVkOnj1qNtAW7i482haI',    // ← UPDATED
        authDomain: 'elnur-s-glow.firebaseapp.com',
        projectId: 'elnur-s-glow',
        storageBucket: 'elnur-s-glow.firebasestorage.app',
        messagingSenderId: '94386119463',                     // ← UPDATED
        appId: '1:94386119463:web:6699063ca6d480abc7e882',    // ← UPDATED
        measurementId: 'G-T5NMJPZ8RW',                        // ← UPDATED
      ),
    );
  } else {
    // Mobile - uses google-services.json
    await Firebase.initializeApp();
  }

  // Enable Firestore persistence
  try {
    await FirebaseFirestore.instance.enablePersistence();
    print('✅ Firestore persistence enabled');
  } catch (e) {
    print('❌ Persistence error: $e');
  }

  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    print('✅ Firestore settings applied');
  } catch (e) {
    print('❌ Settings error: $e');
  }

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
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
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

// ============================================================
// AUTH WRAPPER - Shows Login or Home based on auth state
// ============================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
          );
        }
        
        if (snapshot.hasData) {
          // User is logged in → go to Home
          return const HomeScreen();
        } else {
          // User is NOT logged in → go to Login
          return const LoginScreen();
        }
      },
    );
  }
}
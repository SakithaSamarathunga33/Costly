import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/add_expense.dart';
import 'screens/add_income.dart';
import 'screens/transactions_history.dart';
import 'screens/analytics.dart';
import 'screens/profile.dart';
import 'screens/edit_profile.dart';

Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/splash_screen':
      return _slideUpRoute(const SplashScreen());
    case '/home_dashboard':
      return _slideUpRoute(const HomeDashboard());
    case '/register_screen':
      return _fadeRoute(const RegisterScreen());
    case '/login_screen':
      return _fadeRoute(const LoginScreen());
    case '/add_expense':
      return _slideUpRoute(const AddExpenseScreen());
    case '/add_income':
      return _slideUpRoute(const AddIncomeScreen());
    case '/transactions_history':
      return _slideUpRoute(const TransactionsHistoryScreen());
    case '/analytics':
      return _slideUpRoute(const AnalyticsScreen());
    case '/profile':
      return _slideUpRoute(const ProfileScreen());
    case '/edit_profile':
      return _slideUpRoute(const EditProfileScreen());
    default:
      return _slideUpRoute(const SplashScreen());
  }
}

PageRouteBuilder<T> _slideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

PageRouteBuilder<T> _fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the app with MultiProvider for global state management
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: MaterialApp(
        title: 'COSTLY',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5D3891),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        ),
        initialRoute: '/splash_screen',
        onGenerateRoute: generateRoute,
      ),
    );
  }
}

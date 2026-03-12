import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/add_expense.dart';
import 'screens/add_income.dart';
import 'screens/transactions_history.dart';
import 'screens/analytics.dart';
import 'screens/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize(
    clientId: kIsWeb
        ? '212715503122-j2di6qp94erapbiqieu0dohn0qrgasla.apps.googleusercontent.com'
        : null,
    serverClientId: '212715503122-j2di6qp94erapbiqieu0dohn0qrgasla.apps.googleusercontent.com',
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
        routes: {
          '/splash_screen': (context) => const SplashScreen(),
          '/home_dashboard': (context) => const HomeDashboard(),
          '/register_screen': (context) => const RegisterScreen(),
          '/login_screen': (context) => const LoginScreen(),
          '/add_expense': (context) => const AddExpenseScreen(),
          '/add_income': (context) => const AddIncomeScreen(),
          '/transactions_history': (context) =>
              const TransactionsHistoryScreen(),
          '/analytics': (context) => const AnalyticsScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}

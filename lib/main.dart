import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/recurring_transaction_provider.dart';
import 'providers/savings_goal_provider.dart';
import 'providers/debt_provider.dart';
import 'services/notification_service.dart';
import 'screens/recurring_transactions_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/savings_goals_screen.dart';
import 'screens/debts_screen.dart';
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
import 'screens/income_list_screen.dart';
import 'screens/expense_list_screen.dart';
import 'screens/budget_settings.dart';

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
    case '/income_list':
      return _slideUpRoute(const IncomeListScreen());
    case '/expense_list':
      return _slideUpRoute(const ExpenseListScreen());
    case '/budget_settings':
      return _slideUpRoute(const BudgetSettingsScreen());
    case '/recurring_transactions':
      return _slideUpRoute(const RecurringTransactionsScreen());
    case '/savings_goals':
      return _slideUpRoute(const SavingsGoalsScreen());
    case '/debts':
      return _slideUpRoute(const DebtsScreen());
    case '/notification_settings':
      return _slideUpRoute(const NotificationSettingsScreen());
    default:
      return _slideUpRoute(const SplashScreen());
  }
}

PageRouteBuilder<T> _slideUpRoute<T>(Widget page) {
  const duration = Duration(milliseconds: 400);
  const reverseDuration = Duration(milliseconds: 340);
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final secondary = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.09),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0, -0.035),
            ).animate(secondary),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0.94).animate(secondary),
              child: RepaintBoundary(child: child),
            ),
          ),
        ),
      );
    },
  );
}

PageRouteBuilder<T> _fadeRoute<T>(Widget page) {
  const duration = Duration(milliseconds: 320);
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: RepaintBoundary(child: child),
      );
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().init();
  final themeProvider = ThemeProvider();
  await themeProvider.init();
  runApp(ExpenseTrackerApp(themeProvider: themeProvider));
}

class ExpenseTrackerApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const ExpenseTrackerApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => RecurringTransactionProvider()),
        ChangeNotifierProvider(create: (_) => SavingsGoalProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'COSTLY',
          debugShowCheckedModeBanner: false,
          themeMode: theme.mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5D3891),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7B52AB),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
          ),
          initialRoute: '/splash_screen',
          onGenerateRoute: generateRoute,
        ),
      ),
    );
  }
}

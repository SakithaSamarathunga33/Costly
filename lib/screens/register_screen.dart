import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/top_toast.dart';
import '../widgets/app_animations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscureText = true;

  // Controllers to capture form input
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Google sign-in hidden — uncomment to restore.
  // /// Handle Google sign in
  // Future<void> _handleGoogleSignIn() async {
  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //   final transactionProvider =
  //       Provider.of<TransactionProvider>(context, listen: false);
  //
  //   final success = await authProvider.signInWithGoogle();
  //
  //   if (success && mounted) {
  //     await transactionProvider.fetchTransactions(authProvider.userId);
  //     if (mounted) {
  //       Navigator.pushNamedAndRemoveUntil(
  //         context,
  //         '/home_dashboard',
  //         (route) => false,
  //       );
  //     }
  //   } else if (mounted && authProvider.error != null) {
  //     showTopToast(context, authProvider.error!, isError: true);
  //   }
  // }

  /// Handle sign up button press
  Future<void> _handleRegister() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    final success = await authProvider.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Fetch transactions (empty for new user)
      await transactionProvider.fetchTransactions(authProvider.userId);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home_dashboard',
          (route) => false,
        );
      }
    } else if (mounted && authProvider.error != null) {
      showTopToast(context, authProvider.error!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF5D3891);
    final cs = Theme.of(context).colorScheme;

    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ScreenEntrance(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: StaggeredColumn(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                // Header Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join COSTLY today',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Register Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name Field
                      Text(
                        'Full Name',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: TextStyle(color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: 'John Doe',
                          hintStyle:
                              TextStyle(color: cs.onSurfaceVariant),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          prefixIcon: Icon(Icons.person_outline,
                              color: cs.onSurfaceVariant),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: primary, width: 2),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      Text(
                        'Email Address',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: 'name@company.com',
                          hintStyle:
                              TextStyle(color: cs.onSurfaceVariant),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          prefixIcon: Icon(Icons.mail_outline,
                              color: cs.onSurfaceVariant),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: primary, width: 2),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      Text(
                        'Password',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        style: TextStyle(color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle:
                              TextStyle(color: cs.onSurfaceVariant),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          prefixIcon: Icon(Icons.lock_outline,
                              color: cs.onSurfaceVariant),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: cs.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: primary, width: 2),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button - connected to auth logic
                      ElevatedButton(
                        onPressed:
                            authProvider.isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: primary.withOpacity(0.5),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sign Up',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.person_add_alt_1_outlined,
                                      size: 20),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),

                // Google sign-in hidden — uncomment block below + _handleGoogleSignIn to restore.
                // const SizedBox(height: 24),
                //
                // // ─── OR CONTINUE WITH divider ───
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 8),
                //   child: Row(
                //     children: [
                //       Expanded(
                //           child:
                //               Divider(color: Colors.black.withOpacity(0.08))),
                //       Padding(
                //         padding: const EdgeInsets.symmetric(horizontal: 14.0),
                //         child: Text(
                //           'OR CONTINUE WITH',
                //           style: TextStyle(
                //             color: cs.onSurfaceVariant,
                //             fontSize: 11,
                //             fontWeight: FontWeight.w600,
                //             letterSpacing: 0.5,
                //           ),
                //         ),
                //       ),
                //       Expanded(
                //           child:
                //               Divider(color: Colors.black.withOpacity(0.08))),
                //     ],
                //   ),
                // ),
                //
                // const SizedBox(height: 16),
                //
                // // ─── Google Button ───
                // Center(
                //   child: SizedBox(
                //     width: 180,
                //     height: 46,
                //     child: OutlinedButton(
                //       onPressed:
                //           authProvider.isLoading ? null : _handleGoogleSignIn,
                //       style: OutlinedButton.styleFrom(
                //         side: BorderSide(color: Colors.black.withOpacity(0.1)),
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(14),
                //         ),
                //         backgroundColor: cs.surfaceContainerLow,
                //       ),
                //       child: Row(
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         children: [
                //           Image.asset(
                //             'assets/images/glogo.png',
                //             width: 20,
                //             height: 20,
                //             fit: BoxFit.contain,
                //           ),
                //           const SizedBox(width: 8),
                //           Text(
                //             'Google',
                //             style: TextStyle(
                //               color: cs.onSurface,
                //               fontSize: 14,
                //               fontWeight: FontWeight.w500,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
                //
                // const SizedBox(height: 24),

                const SizedBox(height: 24),

                // Footer Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                            context, '/login_screen');
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

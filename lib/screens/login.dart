import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register.dart';

extension StringCapitalize on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _driverFormKey = GlobalKey<FormState>();
  final _dispatcherFormKey = GlobalKey<FormState>();

  final TextEditingController _driverEmailController = TextEditingController();
  final TextEditingController _driverPasscodeController =
      TextEditingController();

  final TextEditingController _dispatcherEmailController =
      TextEditingController();
  final TextEditingController _dispatcherPasswordController =
      TextEditingController();

  bool _obscureDriverPasscode = true;
  bool _obscureDispatcherPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _driverEmailController.dispose();
    _driverPasscodeController.dispose();
    _dispatcherEmailController.dispose();
    _dispatcherPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loginDriver() async {
    if (!_driverFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.loginDriver(
      _driverEmailController.text.trim(),
      _driverPasscodeController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/driver');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loginDispatcher() async {
    if (!_dispatcherFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.loginDispatcher(
      _dispatcherEmailController.text.trim(),
      _dispatcherPasswordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dispatcher');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? 48.0 : 24.0,
              vertical: 20.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600,
                minHeight: screenHeight - 120,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth > 400 ? 32 : 24,
                      vertical: screenWidth > 400 ? 32 : 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: screenWidth > 400 ? 100 : 80,
                          height: screenWidth > 400 ? 100 : 80,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Vaaganam',
                          style: TextStyle(
                            fontSize: screenWidth > 400 ? 32 : 28,
                            fontWeight: FontWeight.bold,
                            color: primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Logistics Management System',
                          style: TextStyle(
                            fontSize: screenWidth > 400 ? 16 : 14,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.all(screenWidth > 400 ? 20 : 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey[600],
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth > 400 ? 16 : 14,
                            ),
                            unselectedLabelStyle: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: screenWidth > 400 ? 16 : 14,
                            ),
                            tabs: [
                              Tab(
                                height: screenWidth > 400 ? 60 : 50,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      size: screenWidth > 400 ? 24 : 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Driver'),
                                  ],
                                ),
                              ),
                              Tab(
                                height: screenWidth > 400 ? 60 : 50,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.business_center,
                                      size: screenWidth > 400 ? 24 : 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Dispatcher'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: screenHeight > 800 ? 480 : 420,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildDriverLoginForm(),
                              _buildDispatcherLoginForm(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverLoginForm() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _driverFormKey,
        child: Column(
          children: [
            Text(
              'Driver Login',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _driverEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email ID',
                hintText: 'Enter your email address',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.email, size: 22),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                labelStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              style: const TextStyle(fontSize: 16),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _driverPasscodeController,
              obscureText: _obscureDriverPasscode,
              decoration: InputDecoration(
                labelText: 'Passcode',
                hintText: 'Enter your passcode',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.pin, size: 22),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                labelStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureDriverPasscode
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureDriverPasscode = !_obscureDriverPasscode,
                    );
                  },
                ),
              ),
              style: const TextStyle(fontSize: 16),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your passcode';
                }
                if (value.length < 4) {
                  return 'Passcode must be at least 4 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: primary.withOpacity(0.3),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Login as Driver',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 7),

            TextButton(
              onPressed: () {
                _showForgotCredentialsDialog('passcode');
              },
              child: const Text('Forgot passcode?'),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RegisterPage(isDriver: true),
                  ),
                );
              },
              child: const Text(
                'New Driver? Register here',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDispatcherLoginForm() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Form(
        key: _dispatcherFormKey,
        child: Column(
          children: [
            Text(
              'Dispatcher Login',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 28),

            TextFormField(
              controller: _dispatcherEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email ID',
                hintText: 'Enter your email address',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.email, size: 22),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                labelStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              style: const TextStyle(fontSize: 16),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _dispatcherPasswordController,
              obscureText: _obscureDispatcherPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.lock, size: 22),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                labelStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureDispatcherPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureDispatcherPassword =
                          !_obscureDispatcherPassword,
                    );
                  },
                ),
              ),
              style: const TextStyle(fontSize: 16),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginDispatcher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Login as Dispatcher',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 7),

            TextButton(
              onPressed: () {
                _showForgotCredentialsDialog('password');
              },
              child: const Text('Forgot password?'),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RegisterPage(isDriver: false),
                  ),
                );
              },
              child: const Text(
                'New Dispatcher? Register here',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotCredentialsDialog(String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Forgot ${type.capitalize()}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To reset your $type, please contact your administrator or support team.',
            ),
            const SizedBox(height: 16),
            const Text('Support Information:'),
            const SizedBox(height: 8),
            const Text('📧 Email: support@vaaganam.com'),

            const Text('🕒 Support Hours: 9 AM - 6 PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please contact support to reset your $type'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}

// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/home_screen.dart';
import 'providers/auth_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return authState.when(
      data: (user) {
        // If user is not authenticated, show login screen
        if (user == null) {
          return const LoginScreen();
        }
        // If user is authenticated, show home screen
        return const HomeScreen();
      },
      loading: () => const SplashScreen(),
      error: (error, stackTrace) => _ErrorScreen(
        error: error,
        stackTrace: stackTrace,
        onRetry: () {
          // Refresh auth state
          ref.invalidate(authProvider);
        },
        onGoToLogin: () {
          // Manually set auth state to null to show login screen
          ref.read(authProvider.notifier).setUser(null);
        },
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;
  final VoidCallback onGoToLogin;

  const _ErrorScreen({
    required this.error,
    required this.stackTrace,
    required this.onRetry,
    required this.onGoToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Error title
                Text(
                  'Something Went Wrong',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Error message
                Text(
                  _getErrorMessage(error),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Show detailed error in debug mode
                if (stackTrace != null && const bool.fromEnvironment('DEBUG', defaultValue: false))
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        stackTrace.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Go to Login button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onGoToLogin,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      'Go to Login Screen',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                // Contact support option
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // Show support dialog
                    _showSupportDialog(context);
                  },
                  child: const Text(
                    'Need Help? Contact Support',
                    style: TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error.toString().contains('Network is unreachable') ||
        error.toString().contains('SocketException')) {
      return 'Please check your internet connection and try again.';
    } else if (error.toString().contains('401') ||
        error.toString().contains('Unauthorized')) {
      return 'Your session has expired. Please login again.';
    } else if (error.toString().contains('404')) {
      return 'Unable to connect to the server. Please try again later.';
    } else if (error.toString().contains('Timeout')) {
      return 'Request timed out. Please check your connection.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@skillstreak.com'),
            SizedBox(height: 8),
            Text('Phone: +91-XXXXXXXXXX'),
            SizedBox(height: 8),
            Text('Hours: Mon-Fri, 9 AM - 6 PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle email launch
              Navigator.pop(context);
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }
}

// Extension to simplify setting user state
extension AuthNotifierExtension on AuthNotifier {
  void setUser(dynamic user) {
    state = AsyncValue.data(user);
  }
}
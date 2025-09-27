import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Map<String, dynamic>? _passwordStrength;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      _passwordStrength = AuthService.validatePasswordStrength(password);
    });
  }

  void _showAlertDialog(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isSuccess) {
                  // Navigate back to login screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthResetPasswordRequested(
          token: widget.resetToken,
          newPassword: _passwordController.text,
        ),
      );
    }
  }

  Color _getPasswordStrengthColor(int score) {
    switch (score) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPasswordStrengthText(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
      case 5:
        return 'Strong';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showAlertDialog('Reset Failed', state.message);
          } else if (state is AuthResetPasswordSuccess) {
            _showAlertDialog(
              'Password Reset Successful',
              'Your password has been reset successfully. You can now login with your new password.',
              isSuccess: true,
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // Icon and Title
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Create New Password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    'Please enter your new password. Make sure it\'s strong and secure.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // New Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: _checkPasswordStrength,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter your new password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),

                  // Password Strength Indicator
                  if (_passwordStrength != null && _passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Password Strength: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                _getPasswordStrengthText(_passwordStrength!['score']),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getPasswordStrengthColor(_passwordStrength!['score']),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _passwordStrength!['score'] / 5,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getPasswordStrengthColor(_passwordStrength!['score']),
                            ),
                          ),
                          if (_passwordStrength!['feedback'].isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...(_passwordStrength!['feedback'] as List<String>).map(
                              (feedback) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        feedback,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Confirm Password Input
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _resetPassword(),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      hintText: 'Re-enter your new password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Reset Password Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Reset Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Security Tips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Security Tips',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...const [
                          '• Use a mix of uppercase and lowercase letters',
                          '• Include numbers and special characters',
                          '• Avoid using personal information',
                          '• Don\'t reuse passwords from other accounts',
                        ].map(
                          (tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
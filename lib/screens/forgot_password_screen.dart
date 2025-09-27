import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../services/auth_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showAlertDialog(String title, String message, {
    bool isSuccess = false, 
    String? resetToken,
    VoidCallback? onOk,
  }) {
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (resetToken != null) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Development Mode - Reset Token:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                resetToken,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: resetToken));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reset token copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Copy token',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'In production, this token would be sent via email. Use it to reset your password.',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (resetToken != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResetPasswordScreen(resetToken: resetToken),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_reset),
                label: const Text('Reset Password'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onOk != null) onOk();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _sendResetEmail() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthForgotPasswordRequested(email: _emailController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showAlertDialog('Reset Failed', state.message);
          } else if (state is AuthForgotPasswordSuccess) {
            setState(() {
              _isEmailSent = true;
            });
            
            _showAlertDialog(
              'Reset Instructions Sent',
              state.message.split('\n\n')[0], // Get main message without token
              isSuccess: true,
              resetToken: state.resetToken,
              onOk: () {
                if (state.resetToken == null) {
                  Navigator.of(context).pop(); // Back to login if no token
                }
              },
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
                  const SizedBox(height: 40),
                  
                  // Icon and Title
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Reset Your Password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    _isEmailSent 
                        ? 'Check your email for reset instructions'
                        : 'Enter your email address and we\'ll send you instructions to reset your password.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  if (!_isEmailSent) ...[
                    // Email Input
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _sendResetEmail(),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter your email address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!AuthService.isValidEmail(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Send Reset Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return ElevatedButton(
                          onPressed: isLoading ? null : _sendResetEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
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
                                  'Send Reset Instructions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        );
                      },
                    ),
                  ] else ...[
                    // Success State
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.mark_email_read,
                            size: 48,
                            color: Colors.green[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Email Sent Successfully!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check your inbox and follow the instructions to reset your password.',
                            style: TextStyle(
                              color: Colors.green[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Try Again Button
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEmailSent = false;
                        });
                        _emailController.clear();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Try Different Email',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Remember your password? '),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Help Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Need Help?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'If you don\'t receive the email, check your spam folder or contact support.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
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
import 'package:attandance/constants/constants.dart';
import 'package:attandance/screens/LoginScreen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/Colors.dart';
import '../utils/ApiInterceptor.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final Dio _dio = ApiInterceptor.createDio(); // Use ApiInterceptor to create Dio instance

  final emailController = TextEditingController();

  void _resetPassword() async {
    final email = emailController.text.trim();
    // Basic email validation
    if (email.isEmpty || !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    try {
      final response = await _dio.post(
        constants.BASE_URL+constants.RESET_PASSWORD,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset link sent to $email')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reset link')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo at the top
                Center(
                  child: Image.asset(
                    'assets/img.png', // Add your logo in assets and update pubspec.yaml
                    height: 100,
                  ),
                ),
                const SizedBox(height: 40),
          
                // Heading
                const Text(
                  'Forgot Password',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter your email address to receive a password reset link.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
          
                // Email Text Field
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    prefixIcon: Icon(Icons.email, color: thameColor),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: thameColor!, width: 2),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
          
                  ),
          
                  keyboardType: TextInputType.emailAddress,
                ),
          
                const SizedBox(height: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus(); // Hide the keyboard
                          _resetPassword();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: thameColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Reset Password',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12), // spacing between the buttons
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>LoginScreen()),);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                )
          
              ],
            ),
          ),
        ),
      ),
    );
  }
}

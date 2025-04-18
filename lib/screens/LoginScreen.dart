import 'package:attandance/constants/constants.dart';
import 'package:attandance/screens/ForgetPasswordScreen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../constants/Colors.dart';
import '../utils/ApiInterceptor.dart';
import '../utils/Utils.dart';
import 'HomeScreen.dart';
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  final Dio _dio = ApiInterceptor.createDio(); // Use ApiInterceptor to create Dio instance

  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final response = await _dio.post(
          constants.BASE_URL+constants.LOGIN,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
          data: {
            "email": _email,   // Use phone or email depending on your API field
            "password": _password,
          },
        );
        setState(() => _isLoading = false);
        if (response.statusCode == 200 && response.data['status']=='success') {
          final data = response.data;
          Utils.saveStringToPrefs(constants.USER_NAME, data['user']['name']);
          Utils.saveStringToPrefs(constants.EMAIL, data['user']['email']);
          Utils.saveStringToPrefs(constants.MOBILE, data['user']['mobile']);
          Utils.saveStringToPrefs(constants.USER_ID, data['user']['id']);
          Utils.saveStringToPrefs(constants.USER_ROLE, data['user']['role']);
          Fluttertoast.showToast(msg: "Login successful!");
          // Navigate to next screen or handle the response
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()),);
        } else {
          Fluttertoast.showToast(msg: "Login failed: ${response.data['message']}");
        }
      } catch (e) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: "Error: $e");
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required bool isPassword,
    required Function(String) onSaved,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      obscureText: isPassword,
      keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
      validator: validator,
      onSaved: (value) => onSaved(value!),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: thameColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: thameColor!, width: 2),
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: thameColor))
          : Center(  // <-- Center the content
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,  // <-- Ensure it doesn't stretch vertically
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/irclogo.jpg', height: 120, width: 150),
                SizedBox(height: 30),

                // Phone Number Field
                _buildTextField(
                  label: 'Email',
                  icon: Icons.email,
                  isPassword: false,
                  onSaved: (value) => _email = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your Email';
                    }
                    // if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    //   return 'Enter a valid 10-digit phone number';
                    // }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Password Field
                _buildTextField(
                  label: 'Password',
                  icon: Icons.lock,
                  isPassword: true,
                  onSaved: (value) => _password = value,
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
                SizedBox(height: 40),

                // Login Button
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: thameColor,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Login', style: TextStyle(fontSize: 16, color: Colors.white)),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),

                // Forgot Password & Sign Up
                SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>ForgetPasswordScreen()),);
                    },
                    child: Text('Forgot Password?', style: TextStyle(color: thameColor)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

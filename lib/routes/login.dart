import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:su_credit/routes/home.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';

  Future<void> _showDialog(String title, String message) async {
    bool isAndroid = Platform.isAndroid;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        if (isAndroid) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        } else {
          return CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        }
      },
    );
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print('Username: $username, Password: $password');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Home(userName: username),
        ),
      );
    } else {
      _showDialog(
        'Form Error',
        'Please correct the errors in the form.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 400,
              width: double.infinity,
              color: AppColors.primary,
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                'SUcredit',
                style: AppStyles.screenTitle.copyWith(
                  color: AppColors.surface,
                  fontSize: 80,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(minHeight: 350),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.person,
                              color: AppColors.primary,
                            ),
                            labelText: 'SU-Net Username',
                            labelStyle: AppStyles.bodyText.copyWith(
                              color: AppColors.primary,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primary,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Username is required';
                            }
                            return null;
                          },
                          onSaved: (value) => username = value ?? '',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: TextFormField(
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.lock,
                              color: AppColors.primary,
                            ),
                            labelText: 'SU-Net Password',
                            labelStyle: AppStyles.bodyText.copyWith(
                              color: AppColors.primary,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primary,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            } else if (value.length < 5) {
                              return 'Password must be at least 5 characters';
                            }
                            return null;
                          },
                          onSaved: (value) => password = value ?? '',
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: AppStyles.buttonText.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
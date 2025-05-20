import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:su_credit/routes/home.dart';
import 'package:provider/provider.dart';
import 'package:su_credit/providers/auth_provider.dart' as app_auth;

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String name = '';
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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

  void _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // Use AuthProvider instead of direct FirebaseAuth
        final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);

        // Use signUp method from AuthProvider, passing name as optional parameter
        await authProvider.signUp(
          email,
          _passwordController.text.trim(),
          name: name.isNotEmpty ? name : null,
        );

        if (mounted) {
          await _showDialog('Registration Successful', 'Your account has been created.');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => Home(userName: email),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          _showDialog('Registration Error', e.toString());
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Create Account', style: TextStyle(color: AppColors.surface)),
        iconTheme: const IconThemeData(color: AppColors.surface),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email, color: AppColors.primary),
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email is required';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  onSaved: (value) => email = value!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person, color: AppColors.primary),
                    labelText: 'Full Name (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onSaved: (value) => name = value?.trim() ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    if (value.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.surface,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Register', style: TextStyle(color: AppColors.surface, fontSize: 18)),
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
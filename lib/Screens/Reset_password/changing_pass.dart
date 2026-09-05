import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Verify/Screens/Loginpage.dart';

import '../../custom_widget/Paths.dart';

class Password extends StatefulWidget {
  final String number;
  const Password({super.key, required this.number});

  @override
  State<Password> createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController password = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;


  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final pass = password.text.trim();

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        'https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/reset_password_for_main_application.php',
      );

      final response = await http.post(
        url,
        body: {
          "Mobile": widget.number,
          "Passwords": pass,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true) {
          showSuccess(data["message"] ?? "Password updated");

          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          });
        } else {
          showError(data["message"] ?? "Failed to update password");
        }
      } else {
        showError("error : Something went wrong})");
      }
    } catch (e) {
      showError("Something went wrong");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium!.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.black,
              child: Image.asset(
                AppImages.appbar,
                height: 100,
              ),
            ),
            const SizedBox(height: 30),


        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                  Text(
                    'Set New Password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Create a new password for your account',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),

                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.phone, size: 18,color: Colors.black),
                              const SizedBox(width: 10),
                              Text(
                                "+91 ${widget.number}",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500,color: Colors.black),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        TextFormField(
                          controller: password,
                          obscureText: !_showPassword,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => _showPassword = !_showPassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter password';
                            }
                            if (value.length < 6) {
                              return 'Minimum 6 characters required';
                            }
                            return null;
                          },
                        ),                        const SizedBox(height: 60),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                resetPassword();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                              backgroundColor: textColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Update Password',
                              style: TextStyle(fontSize: 16),
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
          ],
        ),
      ),
    );
  }
}

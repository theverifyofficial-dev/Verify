import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:Verify/utilities/hex_color.dart';
import '../../custom_widget/Paths.dart';
import '../../custom_widget/back_button.dart';
import 'otp.dart';

class Forget extends StatefulWidget {
  const Forget({super.key});

  @override
  State<Forget> createState() => _ForgetState();
}

class _ForgetState extends State<Forget> {
  final TextEditingController number = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> checkNumberAndSendOtp(String number) async {
    setState(() => _isLoading = true);

    try {
      const apiKey = String.fromEnvironment('TWO_FACTOR_API_KEY');

      print(apiKey);

      final url = Uri.parse(
          'https://verifyrealestateandservices.in/WebService4.asmx/CheckMobileNumber?FNumber=$number');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = response.body;

        // 🔥 Convert string response to JSON
        final decoded = jsonDecode(data);

        if (decoded is List && decoded.isNotEmpty) {
          final status = decoded[0]["Status"];

          if (status == 1) {
            // ✅ Number exists → send OTP

            final otpUrl = Uri.parse(
                "https://2factor.in/API/V1/$apiKey/SMS/+91$number/AUTOGEN");

            final otpResponse = await http.get(otpUrl);

            if (otpResponse.statusCode == 200) {
              final sessionId = RegExp(r'"Details":"(.*?)"')
                  .firstMatch(otpResponse.body)
                  ?.group(1);

              if (sessionId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Otp(number: number, sessionId: sessionId),
                  ),
                );
              } else {
                showError("Failed to get session ID");
              }
            } else {
              showError("Failed to send OTP");
            }
          } else {
            showError("Mobile number not registered");
          }
        } else {
          showError("Invalid server response");
        }
      } else {
        showError("Server error (${response.statusCode})");
      }
    } catch (e) {
      showError("Something went wrong");
    }

    setState(() => _isLoading = false);
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

    @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      backgroundColor: "#001234".toColor(),
      body: Column(
        children: [
          // Header Image
          Container(
            width: double.infinity,
            color: "#001234".toColor(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const CustomBackButton(),
                const SizedBox(width: 16),
                Image.asset(AppImages.logo2, height: 100),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Form Section

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  Text(
                    'Forgot Password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Enter your registered phone number to receive an OTP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Phone Number Input
                  Form(
                    key: _formKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: TextFormField(
                        controller: number,
                        cursorColor: Colors.black,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          hintText: "Phone Number",
                          hintStyle: TextStyle(color: Colors.black,),
                          prefixIcon: const Icon(Icons.call,color: Colors.black,),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter phone number';
                          }
                          if (value.length != 10) {
                            return 'Enter valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                        if (_formKey.currentState!.validate()) {
                          await checkNumberAndSendOtp(number.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor:  Theme.of(context).scaffoldBackgroundColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      )
                          : const Text(
                        "Send OTP",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

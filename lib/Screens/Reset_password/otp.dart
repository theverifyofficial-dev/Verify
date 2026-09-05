import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:http/http.dart' as http;
import 'package:Verify/utilities/hex_color.dart';
import 'dart:convert'; // REQUIRED

import 'changing_pass.dart';
class Otp extends StatefulWidget {
  final String number;
  final String sessionId;

  const Otp({super.key, required this.number, required this.sessionId});

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> {

  String _otp = "";
  bool _isLoading = false;
  final _formkey = GlobalKey<FormState>();


  Future<void> verifyOTP() async {

    if (_otp.length != 6) {
      showError("Enter valid 6-digit OTP");
      return;
    }

    const apiKey = String.fromEnvironment('TWO_FACTOR_API_KEY');

    try {
      final url = Uri.parse(
        "https://2factor.in/API/V1/$apiKey/SMS/VERIFY/${widget.sessionId}/$_otp",
      );

      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (data["Status"] == "Success") {

        showSuccess("OTP Verified Successfully");

        // ✅ OTP correct
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Password(number: widget.number,)),
        );

      } else {
        // ❌ Show backend message instead of status code
        showError(data["Details"] ?? "Invalid OTP");
      }

    } catch (e) {
      showError("Something went wrong");
    }
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
    return SafeArea(
        child: Scaffold(
            backgroundColor: "#001234".toColor(),
            body: SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.all(20.0),
                  child:
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20,),
                         Text('Verification Code',style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Colors.white),),
                        const SizedBox(height: 20,),
                         Text('Enter the verification code that we send on mobile after confirmation you can reset your password',style: TextStyle(fontSize: 18,color: Colors.white),),
                        const SizedBox(height: 100,),
                        Form(
                          key: _formkey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Pinput(
                                length: 6,
                                onChanged: (value) => _otp = value,
                                onCompleted: (value) => _otp = value,
                                validator: (value) {
                                  if (value == null || value.length != 6) {
                                    return "Enter 6-digit OTP";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 60,),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                  if (_formkey.currentState!.validate()) {
                                    setState(() => _isLoading = true);
                                    await verifyOTP();
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Theme.of(context).primaryColor,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                                    : const Text("Confirm"),
                              ),
                            ],
                          ),
                        ),
                      ]
                  ),
                )
            )
        ));
  }
}

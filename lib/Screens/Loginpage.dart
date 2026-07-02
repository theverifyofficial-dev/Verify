import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Verify/utilities/theme-helper.dart';
import 'package:Verify/custom_widget/Paths.dart';
import 'package:Verify/utilities/hex_color.dart';
import '../main.dart';
import 'Homepage.dart';
import 'Reset_password/forget.dart';
import 'SignUp.dart';
import 'Splash.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _showPassword = false;
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  Future<void>loginUser() async {

    String fcmToken = await getFCMToken();

    String token = await getFCMToken();

    if (token.isEmpty) {
      token = "IOS_SIMULATOR";
    }

    const String url = 'https://verifyrealestateandservices.in/PHP_Files/Login_Main_App/Login_Main_APP.php';
    final response  = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {
              'Mobile': _mobileController.text,
              'Passwords': _passController.text,
              'FCM': fcmToken,
            }
        ));
    final data= json.decode(response.body);

    print(data);
    if(response.statusCode==200 && data['status'] == 'success'){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:
        Text(data['message'] ??'User Login Successfully'),
        ),
      );

      final String? profileImage = data['user']['profile_image'];



      final String fullNameFromAPI = data['user']['FullName']; // fixed casing
      final String emailFromAPI = data['user']['Email'];       // fixed casing
      final int IDFromAPI = data['user']['id'];                // already an int
      final String mobileFromAPI = data['user']['Mobile'];
      var shared_pref= await SharedPreferences.getInstance();
      await shared_pref.setBool(SplashScreenState.KEY_LOGIN, true);
      await shared_pref.setString('name', fullNameFromAPI);
      await shared_pref.setString('email', emailFromAPI);
      await shared_pref.setString('number', mobileFromAPI);
      await shared_pref.setInt('id', IDFromAPI);
      /// SAVE FCM TOKEN
      await shared_pref.setString(
        'fcm_token',
        fcmToken,
      );

      if (profileImage != null && profileImage.isNotEmpty) {
        String fullUrl =
            "https://verifyrealestateandservices.in/Second%20PHP%20FILE/profie_image_update_main_realestate/$profileImage";

        await shared_pref.setString('profile_image_url', fullUrl);
      }

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)
      => Homepage(),
      ));

    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      child: Scaffold(
        backgroundColor: "#001234".toColor(),
        body:SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  color: "#001234".toColor(),

                  child: Image.asset(
                    AppImages.logo2,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Form(
                    key: _formkey,
                    child: Column(
                      children: [
                         Text(
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                         Text(
                          "Login to your account",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),

                        buildTextField(
                          controller: _mobileController,
                          hint: 'Phone Number',
                          icon: Icons.call,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // only numbers
                            LengthLimitingTextInputFormatter(10),   // max 10 digits
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter phone number';
                            } else if (value.length != 10) {
                              return 'Enter valid 10-digit number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        buildTextField(
                          controller: _passController,
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Enter password'
                              : null,
                        ),
                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => Forget()),
                              );
                            },
                            child:  Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        GestureDetector(
                          onTap: (){
                            if(_formkey.currentState!.validate()){
                              loginUser();
                            }
                            else{
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            color: AppColors.textColor(context),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  :  Text(
                                "Login",
                                style: TextStyle(
                                  color: AppColors.bgColor(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don’t have an account? ",style: TextStyle(color: Colors.white),),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpPage()));
                              },
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ]
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters, // 👈 add this
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_showPassword,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters, // 👈 use here
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium!.color,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).textTheme.bodyMedium!.color,
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          )
              : null,
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}

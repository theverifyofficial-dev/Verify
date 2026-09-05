import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:Verify/utilities/hex_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../custom_widget/Paths.dart';
import '../../custom_widget/back_button.dart';

class RegisterVehiclePage extends StatefulWidget {
  const RegisterVehiclePage({super.key});

  @override
  State<RegisterVehiclePage> createState() =>
      _RegisterVehiclePageState();
}

class _RegisterVehiclePageState extends State<RegisterVehiclePage> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController vehicleNumberController =
  TextEditingController();

  final TextEditingController messageController =
  TextEditingController();

  final List<String> vehicleTypes = [
    "Car",
    "Bike",
    "Scooter",
    "Truck",
    "Taxi",
    "Auto",
    "Bus",
    "Other",
  ];

  String? selectedVehicleType;

  File? vehicleImage;

  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();

  /// 🔥 PICK IMAGE
  Future<void> pickVehicleImage() async {
    final picked =
    await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        vehicleImage = File(picked.path);
      });
    }
  }

  /// 🔥 REGISTER
  Future<void> registerVehicle() async {

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedVehicleType == null) {
      showSnack("Select vehicle type", error: true);
      return;
    }

    if (vehicleImage == null) {
      showSnack("Upload vehicle image", error: true);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      /// 🔥 USER ID
      final prefs = await SharedPreferences.getInstance();

      final userId =
          prefs.getInt('id')?.toString() ?? "";
      final name =
          prefs.getString('name')?.toString() ?? "";
      final number =
          prefs.getString('number')?.toString() ?? "";

      if (userId.isEmpty) {
        showSnack("User not found", error: true);
        return;
      }

      /// 🔥 API URL
      final Uri url = Uri.parse(
        "https://verifyrealestateandservices.in/Second%20PHP%20FILE/vehicle_alert/vehicle_alert.php",
      );

      /// 🔥 REQUEST
      final request = http.MultipartRequest(
        'POST',
        url,
      );

      /// 🔥 FIELDS
      request.fields.addAll({

        'user_id': userId,
        'name': name,
        'number': number,

        'vehicle_number':
        vehicleNumberController.text
            .trim()
            .toUpperCase(),

        'vehicle_type':
        selectedVehicleType ?? "",

        'message':
        messageController.text.trim(),

        'created_at':
        DateTime.now().toString(),
      });

      /// 🔥 IMAGE
      request.files.add(
        await http.MultipartFile.fromPath(
          'vehicle_pic',
          vehicleImage!.path,
        ),
      );

      /// 🔥 SEND
      final streamedResponse =
      await request.send();

      final response =
      await http.Response.fromStream(
        streamedResponse,
      );

      /// 🔥 SUCCESS
      if (response.statusCode == 200 &&
          response.body.contains("success")) {

        showSnack(
          "Vehicle registered successfully",
        );

        _showSuccessDialog();

      } else {

        showSnack(
          "Registration failed",
          error: true,
        );
      }

    } catch (e) {

      showSnack(
        "Error: $e",
        error: true,
      );

    } finally {

      setState(() {
        isLoading = false;
      });
    }
  }

  void showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        error ? Colors.red : Colors.green.shade700,
      ),
    );
  }

  /// 🔥 SUCCESS
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                height: 78,
                width: 78,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: "#001234".toColor().withOpacity(0.08),
                ),

                child: Icon(
                  Icons.check_rounded,
                  size: 42,
                  color: "#001234".toColor(),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Vehicle Registered",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: "#001234".toColor(),
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Your vehicle is now securely connected with Verify.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: "#001234".toColor(),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),

                  child: const Text(
                    "Done",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    vehicleNumberController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: "#EEF5FF".toColor(),

      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Image.asset(AppImages.logo2, height: 70),
        centerTitle: true,
        backgroundColor: "#001234".toColor(),
        surfaceTintColor: "#001234".toColor(),
      ),

      body: Stack(
        children: [

          SingleChildScrollView(
            padding: const EdgeInsets.all(18),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TITLE
                  Text(
                    "Register Vehicle",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: "#001234".toColor(),
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Securely add your vehicle to Verify network.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 26),

                  /// IMAGE UPLOAD
                  _uploadBox(),

                  const SizedBox(height: 22),

                  /// VEHICLE NUMBER
                  _inputTitle("Vehicle Number"),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: vehicleNumberController,

                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,

                    /// 🔥 MAX LENGTH
                    maxLength: 12,

                    inputFormatters: [

                      /// ONLY A-Z + 0-9
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Z0-9]'),
                      ),

                      /// REMOVE SPACES + FORCE UPPERCASE
                      TextInputFormatter.withFunction(
                            (oldValue, newValue) {

                          String text = newValue.text
                              .replaceAll(" ", "")
                              .toUpperCase();

                          /// 🔥 LIMIT CHARACTERS
                          if (text.length > 12) {
                            text = text.substring(0, 12);
                          }

                          return TextEditingValue(
                            text: text,
                            selection: TextSelection.collapsed(
                              offset: text.length,
                            ),
                          );
                        },
                      ),
                    ],

                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),

                    decoration: _inputDecoration(
                      hint: "DL76CAR8765",
                      icon: Icons.confirmation_number_rounded,
                    ).copyWith(

                      /// 🔥 REMOVE DEFAULT COUNTER SPACE
                      counterText: "",

                      /// OPTIONAL RIGHT SIDE LIMIT TEXT
                      suffixText: "Max 12",
                      suffixStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    validator: (value) {

                      if (value == null || value.trim().isEmpty) {
                        return "Enter vehicle number";
                      }

                      if (value.length < 8) {
                        return "Enter valid vehicle number";
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  /// VEHICLE TYPE
                  _inputTitle("Vehicle Type"),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedVehicleType,

                    decoration: _inputDecoration(
                      hint: "Select vehicle type",
                      icon: Icons.directions_car_filled_rounded,
                    ),

                    dropdownColor: Colors.white,

                    borderRadius: BorderRadius.circular(14),

                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),

                    items: vehicleTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        selectedVehicleType = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  /// MESSAGE
                  _inputTitle("Emergency Message"),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: messageController,
                    maxLines: 4,

                    style: const TextStyle(
                      fontFamily: 'Poppins',
                    ),

                    decoration: _inputDecoration(
                      hint:
                      "Optional message for people contacting you...",
                      icon: Icons.message_rounded,
                    ),
                  ),

                  const SizedBox(height: 26),

                  /// INFO CARD
                  Container(
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),

                      border: Border.all(
                        color: "#001234"
                            .toColor()
                            .withOpacity(0.08),
                      ),
                    ),

                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Icon(
                          Icons.lock_rounded,
                          color: "#001234".toColor(),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            "Your personal number remains hidden. Users can contact you securely through Verify.",
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.grey.shade700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// BUTTON
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed:
                      isLoading ? null : registerVehicle,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: "#001234".toColor(),
                        foregroundColor: Colors.white,
                        elevation: 0,

                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(30),
                        ),
                      ),

                      child: isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        "Register Vehicle",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          /// LOADING
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
            ),
        ],
      ),
    );
  }

  /// 🔥 IMAGE BOX
  Widget _uploadBox() {

    return GestureDetector(
      onTap: pickVehicleImage,

      child: Container(
        height: 180,
        width: double.infinity,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),

          border: Border.all(
            color: "#001234".toColor().withOpacity(0.08),
          ),
        ),

        child: vehicleImage == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              height: 62,
              width: 62,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: "#001234"
                    .toColor()
                    .withOpacity(0.08),
              ),

              child: Icon(
                Icons.add_a_photo_rounded,
                color: "#001234".toColor(),
                size: 30,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              "Upload Vehicle Photo",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: "#001234".toColor(),
                fontFamily: 'Poppins',
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Tap to select image",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(22),

          child: Stack(
            fit: StackFit.expand,
            children: [

              Image.file(
                vehicleImage!,
                fit: BoxFit.cover,
              ),

              Positioned(
                right: 12,
                top: 12,

                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      vehicleImage = null;
                    });
                  },

                  child: Container(
                    padding: const EdgeInsets.all(6),

                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 TITLE
  Widget _inputTitle(String title) {

    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: "#001234".toColor(),
        fontFamily: 'Poppins',
      ),
    );
  }

  /// 🔥 INPUT DECORATION
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontFamily: 'Poppins',
      ),

      prefixIcon: Icon(
        icon,
        color: "#001234".toColor(),
      ),

      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide(
          color: "#001234".toColor().withOpacity(0.08),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide(
          color: "#001234".toColor(),
          width: 1.4,
        ),
      ),
    );
  }
}
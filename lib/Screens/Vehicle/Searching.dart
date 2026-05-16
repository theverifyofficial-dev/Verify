import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:Verify/utilities/hex_color.dart';

import '../../custom_widget/Paths.dart';
import '../../custom_widget/back_button.dart';

class SearchVehiclePage extends StatefulWidget {
  const SearchVehiclePage({super.key});

  @override
  State<SearchVehiclePage> createState() =>
      _SearchVehiclePageState();
}

class _SearchVehiclePageState
    extends State<SearchVehiclePage> {

  final TextEditingController searchController =
  TextEditingController();

  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  bool noVehicleFound = false;

  Map<String, dynamic>? vehicleData;

  /// 🔥 SEARCH
  Future<void> searchVehicle() async {

    FocusScope.of(context).unfocus();

    /// 🔥 VALIDATION FIRST
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
      vehicleData = null;
    });

    try {

      final vehicleNumber = searchController.text
          .trim()
          .replaceAll(" ", "")
          .toUpperCase();

      final response = await http.get(

        Uri.parse(
          "https://verifyrealestateandservices.in/Second%20PHP%20FILE/vehicle_alert/show_vehicle_details.php?vehicle_number=$vehicleNumber",
        ),
      );

      final data = json.decode(response.body);

      print(data);

      if (response.statusCode == 200 &&
          data["status"] == "success" &&
          data["data"] != null &&
          data["data"].isNotEmpty) {

        setState(() {


          /// 🔥 FIRST VEHICLE
          vehicleData = data["data"][0];

          noVehicleFound = false;
        });

      } else {

        showSnack(
          "Vehicle not found",
        );

        setState(() {
          noVehicleFound = true;
        });
      }

    } catch (e) {

      showSnack(
        "Something went wrong",
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  void showSnack(String msg) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
        
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        
              /// TITLE
              Text(
                "Find Vehicle Owner",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: "#001234".toColor(),
                  fontFamily: 'Poppins',
                ),
              ),
        
              const SizedBox(height: 6),
        
              Text(
                "Search vehicle and alert its owner securely.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontFamily: 'Poppins',
                ),
              ),
        
              const SizedBox(height: 26),
        
              /// SEARCH FIELD
              TextFormField(
                controller: searchController,
        
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.search,
                autovalidateMode:
                AutovalidateMode.onUserInteraction,
        
                /// 🔥 LIMIT
                maxLength: 12,

                validator: (value) {

                  final text = value!
                      .trim()
                      .replaceAll(" ", "")
                      .toUpperCase();

                  if (text.isEmpty) {
                    return "Enter vehicle number";
                  }

                  /// 🔥 INDIAN VEHICLE FORMAT
                  final regex = RegExp(
                    r'^[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{4}$',
                  );

                  if (!regex.hasMatch(text)) {
                    return "Invalid vehicle number";
                  }

                  return null;
                },

                onChanged: (_) {

                  if (vehicleData != null) {

                    setState(() {
                      vehicleData = null;
                    });
                  }
                },
                /// 🔥 FORMAT
                inputFormatters: [
        
                  /// ONLY A-Z + 0-9
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[A-Z0-9]'),
                  ),
        
                  /// REMOVE SPACE + FORCE CAPS
                  TextInputFormatter.withFunction(
                        (oldValue, newValue) {
        
                      String text = newValue.text
                          .replaceAll(" ", "")
                          .toUpperCase();
        
                      /// LIMIT LENGTH
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

                onFieldSubmitted: (_) async {

                  if (_formKey.currentState!.validate()) {
                    await searchVehicle();
                  }
                },
        
                decoration: InputDecoration(
        
                  hintText: "DL76CAR8765",
        
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    letterSpacing: 1,
                    fontFamily: 'Poppins',
                  ),

                  prefixIcon: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isLoading
                          ? Icons.search_off_rounded
                          : Icons.directions_car_filled_rounded,
                      color: "#001234".toColor(),
                    ),
                  ),
        
                  suffixText: "Max 12",
        
                  suffixStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
        
                  filled: true,
                  fillColor: Colors.white,
        
                  counterText: "",
        
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
                      color: "#001234"
                          .toColor()
                          .withOpacity(0.08),
                    ),
                  ),
        
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: "#001234".toColor(),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
        
              const SizedBox(height: 18),
        
              /// SEARCH BUTTON
              SizedBox(
                width: double.infinity,
        
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {

                    if (_formKey.currentState!.validate()) {
                      await searchVehicle();
                    }
                  },
        
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    "#001234".toColor(),
        
                    foregroundColor: Colors.white,
        
                    elevation: 0,
        
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
        
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(30),
                    ),
                  ),
        
                  child: isLoading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child:
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Search Vehicle",
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
        
              const SizedBox(height: 30),

              if (noVehicleFound)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [

                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.red.shade400,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "Vehicle Not Found",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "This vehicle is not registered on Verify yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              if (vehicleData == null && !isLoading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [

                      Icon(
                        Icons.directions_car_rounded,
                        size: 52,
                        color: "#001234".toColor(),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Search Any Registered Vehicle",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: "#001234".toColor(),
                          fontFamily: 'Poppins',
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Enter vehicle number to alert the owner securely.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

              /// RESULT
              if (vehicleData != null)
                _vehicleResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 RESULT CARD
  Widget _vehicleResultCard() {

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Container(
                height: 54,
                width: 54,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green
                      .withOpacity(0.12),
                ),

                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Vehicle Found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      vehicleData![
                      "vehicle_number"],
                      style: TextStyle(
                        color:
                        Colors.grey.shade700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// VEHICLE IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              "https://verifyrealestateandservices.in/Second%20PHP%20FILE/vehicle_alert/alert_images/${vehicleData!["vehicle_pic"]}",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,

              loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                  ) {
                if (loadingProgress == null) {
                  return child;
                }

                return Container(
                  height: 180,
                  color: "#EEF5FF".toColor(),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: "#001234".toColor(),
                    ),
                  ),
                );
              },

              errorBuilder: (
                  context,
                  error,
                  stackTrace,
                  ) {
                return Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: "#EEF5FF".toColor(),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        size: 42,
                        color: "#001234".toColor(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Vehicle image unavailable",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // /// NAME
          // _infoRow(
          //   "Owner",
          //   vehicleData!["name"],
          // ),
          //
          // const SizedBox(height: 10),

          /// TYPE
          _infoRow(
            "Vehicle Type",
            vehicleData!["vehicle_type"],
          ),

          const SizedBox(height: 10),

          /// MESSAGE
          _infoRow(
            "Owner Message",
            vehicleData!["message"],
          ),

          const SizedBox(height: 24),

          /// BUTTONS
          Row(
            children: [

              Expanded(
                child: ElevatedButton.icon(

                  onPressed: () {

                    /// ALERT API
                  },

                  icon: const Icon(
                    Icons.notifications_active,
                    size: 18,
                  ),

                  label: const Text(
                    "Send Alert",
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    "#001234".toColor(),

                    foregroundColor:
                    Colors.white,

                    elevation: 0,

                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 14,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          16),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(

                  onPressed: () {

                    /// CALL OWNER
                  },

                  icon: Icon(
                    Icons.call_rounded,
                    color: "#001234".toColor(),
                    size: 18,
                  ),

                  label: Text(
                    "Call",
                    style: TextStyle(
                      color:
                      "#001234".toColor(),
                    ),
                  ),

                  style: OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 14,
                    ),

                    side: BorderSide(
                      color:
                      "#001234".toColor(),
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      String title,
      String value,
      ) {

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        Text(
          "$title: ",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: "#001234".toColor(),
            fontFamily: 'Poppins',
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}
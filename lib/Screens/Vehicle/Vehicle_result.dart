import 'package:flutter/material.dart';
import 'package:Verify/utilities/hex_color.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../custom_widget/Paths.dart';
import '../../custom_widget/back_button.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchVehiclePage extends StatefulWidget {
  final Map<String, dynamic> vehicleData;

  const SearchVehiclePage({
    super.key,
    required this.vehicleData,
  });
  @override
  State<SearchVehiclePage> createState() =>
      _SearchVehiclePageState();
}

class _SearchVehiclePageState extends State<SearchVehiclePage> {

  bool isSendingAlert = false;

  Future<void> sendVehicleAlert() async {

    if (isSendingAlert) return;

    final mobile =
    widget.vehicleData["number"]
        .toString()
        .trim();

    if (mobile.isEmpty) {

      showSnack("Mobile number unavailable");
      return;
    }

    setState(() {
      isSendingAlert = true;
    });

    try {

      final response = await http.post(

        Uri.parse(
          "https://verifyrealestateandservices.in/PHP_Files/Login_Main_App/send_vehicle_alert.php",
        ),

        body: {
          "Mobile": mobile,
        },
      );

      final data = json.decode(response.body);

      print(data);

      if (response.statusCode == 200) {

        showSnack("Alert sent successfully");

      } else {

        showSnack(
          data["message"] ??
              "Failed to send alert",
        );
      }

    } catch (e) {

      showSnack("Something went wrong");
    }

    setState(() {
      isSendingAlert = false;
    });
  }

  Future<void> callOwner(String phoneNumber) async {

    if (phoneNumber.trim().isEmpty) {

      showSnack("Phone number unavailable");
      return;
    }

    try {

      final Uri callUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );

      await launchUrl(
        callUri,
        mode: LaunchMode.externalApplication,
      );

    } catch (e) {

      showSnack("Unable to make call");
    }
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
              _vehicleResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _vehicleResultCard() {

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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

      Align(
      alignment: Alignment.centerLeft,
        child: Container(
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
              )),

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
                      widget.vehicleData[
                      "vehicle_number"],
                      style: TextStyle(
                        color: "#001234".toColor(),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),

                      child: const Text(
                        "OWNER VERIFIED",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          fontFamily: 'Poppins',
                        ),
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
              "https://verifyrealestateandservices.in/Second%20PHP%20FILE/vehicle_alert/alert_images/${widget.vehicleData["vehicle_pic"]}",
              height: 210,
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
                  height: 210,
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
                  height: 210,
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

          /// NAME
          _infoRow(
            "Owner",
            widget.vehicleData["name"],
          ),

          const SizedBox(height: 10),

          /// TYPE
          _infoRow(
            "Vehicle Type",
            widget.vehicleData["vehicle_type"],
          ),

          const SizedBox(height: 10),

          _infoRow(
            "Message",
            widget.vehicleData["message"],
          ),

          const SizedBox(height: 24),

          /// BUTTONS
          Row(
            children: [

              Expanded(
              child: OutlinedButton.icon(

                onPressed: isSendingAlert
                    ? null
                    : sendVehicleAlert,

                  icon:  Icon(
                    Icons.notifications_active,
                    color: "#001234".toColor(),
                    size: 18,
                  ),

                label: isSendingAlert
                    ?  SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: "#001234".toColor(),
                  ),
                )
                    : const Text(
                  "Send Alert",
                ),

                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 14,
                  ),

                  minimumSize: const Size(double.infinity, 52),

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

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(

                  onPressed: () {
                    callOwner(widget.vehicleData["number"]);
                  },

                  icon: Icon(
                    Icons.call_rounded,
                    size: 18,
                  ),

                  label: const Text(
                    "Call",
                    ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    "#001234".toColor(),

                    minimumSize: const Size(double.infinity, 52),
                    foregroundColor:
                    Colors.white,

                    elevation: 4,
                    shadowColor:
                    "#001234".toColor().withOpacity(0.25),
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
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
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
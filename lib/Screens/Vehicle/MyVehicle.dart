import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../custom_widget/Paths.dart';
import '../../custom_widget/back_button.dart';
import '../../utilities/hex_color.dart';

class MyRegisteredVehicles extends StatefulWidget {
  const MyRegisteredVehicles({super.key});

  @override
  State<MyRegisteredVehicles> createState() =>
      _MyRegisteredVehiclesState();
}

class _MyRegisteredVehiclesState extends State<MyRegisteredVehicles> {

  List vehicles = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {

    try {

      final prefs =
      await SharedPreferences.getInstance();

      final userId =
          prefs.getInt('id')?.toString() ?? "";

      final response = await http.get(
        Uri.parse(
          "https://verifyrealestateandservices.in/Second%20PHP%20FILE/vehicle_alert/show_api_vehicle_alert.php?user_id=$userId",
        ),
      );

      final decoded = jsonDecode(response.body);

      if (decoded[0]['Status'] == 1) {

        setState(() {

          vehicles = decoded[0]['data'];

          isLoading = false;
        });

      } else {

        setState(() {
          vehicles = [];
          isLoading = false;
        });
      }
    } catch (e) {

      setState(() {
        isLoading = false;
      });
    }
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

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : vehicles.isEmpty
          ? const Center(
        child: Text("No vehicles found"),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vehicles.length,

        itemBuilder: (context, index) {

          final vehicle = vehicles[index];

          /// FORMAT DATE
          String formattedDate = "";

          try {

            final rawDate =
            DateFormat("yyyy-MM-dd hh:mm:ss a")
                .parse(vehicle['created_at']);

            formattedDate =
                DateFormat("dd MMM yyyy")
                    .format(rawDate);

          } catch (e) {

            formattedDate = vehicle['created_at'];
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 18),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TOP SECTION
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// VEHICLE IMAGE
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),

                        child: Image.network(
                          "https://verifyrealestateandservices.in/Second%20PHP%20FILE/vehicle_alert/alert_images/${vehicle['vehicle_pic']}",

                          height: 110,
                          width: 110,
                          fit: BoxFit.cover,

                          errorBuilder: (_, __, ___) {
                            return Container(
                              height: 110,
                              width: 110,
                              color: Colors.grey.shade200,

                              child: const Icon(
                                Icons.image_not_supported,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      /// VEHICLE INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            /// TYPE
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),

                              decoration: BoxDecoration(
                                color: "#001234"
                                    .toColor()
                                    .withOpacity(0.08),

                                borderRadius:
                                BorderRadius.circular(30),
                              ),

                              child: Text(
                                vehicle['vehicle_type'],

                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.w600,
                                  color: "#001234".toColor(),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            /// NUMBER
                            Text(
                              vehicle['vehicle_number'],

                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: "#001234".toColor(),
                                letterSpacing: 1,
                                fontFamily: 'Poppins',
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// DATE
                            Row(
                              children: [

                                Icon(
                                  Icons.calendar_month,
                                  size: 15,
                                  color: Colors.grey.shade600,
                                ),

                                const SizedBox(width: 5),

                                Expanded(
                                  child: Text(
                                    formattedDate,

                                    maxLines: 1,
                                    overflow:
                                    TextOverflow.ellipsis,

                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                      Colors.grey.shade600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  /// MESSAGE
                  if (vehicle['message']
                      .toString()
                      .trim()
                      .isNotEmpty) ...[

                    Text(
                      "Emergency Message",

                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: "#001234".toColor(),
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: "#001234".toColor(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            vehicle['message'],
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.grey.shade800,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      )
    );
  }
}
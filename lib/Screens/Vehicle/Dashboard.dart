import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Verify/utilities/hex_color.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../custom_widget/Paths.dart';
import '../../custom_widget/back_button.dart';
import 'MyVehicle.dart';
import 'Qr_scan.dart';
import 'Vehicle_result.dart';
import 'Vehicle_form.dart';


class Motor extends StatefulWidget {
  const Motor({super.key});

  @override
  State<Motor> createState() => _MotorState();
}

class _MotorState extends State<Motor> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  final TextEditingController searchController =
  TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchVehicle() async {
    if (isSearching) return;

    FocusScope.of(context).unfocus();

    final vehicleNumber = searchController.text
        .trim()
        .replaceAll(" ", "")
        .toUpperCase();

    if (vehicleNumber.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter vehicle number"),
        ),
      );

      return;
    }

    setState(() {
      isSearching = true;
    });

    try {

      final response = await http.get(

        Uri.parse(
          "https://verifyrealestateandservices.in/Second%20PHP%20FILE/vehicle_alert/show_vehicle_details.php?vehicle_number=$vehicleNumber",
        ),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 &&
          data["status"] == "success" &&
          data["data"] != null &&
          data["data"].isNotEmpty) {

        final vehicleData = data["data"][0];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchVehiclePage(
              vehicleData: vehicleData,
            ),
          ),
        );

        searchController.clear();

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vehicle not found"),
          ),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
        ),
      );
    }

    setState(() {
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: "#EEF5FF".toColor(),

      appBar: AppBar(
        leading: const CustomBackButton(),

        title: Image.asset(
          AppImages.logo2,
          height: 70,
        ),

        centerTitle: true,

        backgroundColor: "#001234".toColor(),
        surfaceTintColor: "#001234".toColor(),

        actions: [

          PopupMenuButton<String>(

            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
            ),

            color: Colors.white,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),

            onSelected: (value) {

              if (value == "my_vehicles") {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const MyRegisteredVehicles(),
                  ),
                );
              }
            },

            itemBuilder: (context) => [

              PopupMenuItem(
                value: "my_vehicles",

                child: Row(
                  children: [

                    Icon(
                      Icons.directions_car_filled_rounded,
                      color: "#001234".toColor(),
                      size: 22,
                    ),

                    const SizedBox(width: 10),

                    const Text(
                      "My Vehicles",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// TITLE
              Text(
                "Vehicle Alert",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: "#001234".toColor(),
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Securely connect with vehicle owners through Verify.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 24),

              /// HERO CARD
              _heroCard(context),

              const SizedBox(height: 20),

             Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Find Vehicle Owner",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: "#001234".toColor(),
                          fontFamily: 'Poppins',
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Search vehicle and instantly contact owner.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontFamily: 'Poppins',
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextField(
                        controller: searchController,

                        textCapitalization:
                        TextCapitalization.characters,

                        textInputAction: TextInputAction.search,

                        maxLength: 12,

                        onSubmitted: (_) {
                          searchVehicle();
                        },

                        inputFormatters: [

                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Z0-9]'),
                          ),

                          TextInputFormatter.withFunction(
                                (oldValue, newValue) {

                              String text = newValue.text
                                  .replaceAll(" ", "")
                                  .toUpperCase();

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

                        decoration: InputDecoration(
                          hintText: "DL12ABC3456",
                          hintStyle: TextStyle(color: Colors.black26),
                          counterText: "",
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: "#001234".toColor(),
                          ),

                          filled: true,
                          fillColor: "#EEF5FF".toColor(),

                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              /// QR SCAN
                              IconButton(
                                onPressed: () {

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const VehicleQRScannerPage(),
                                    ),
                                  );
                                },

                                icon: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: "#001234".toColor(),
                                ),
                              ),

                              /// SEARCH
                              IconButton(
                                onPressed: isSearching
                                    ? null
                                    : searchVehicle,

                                icon: isSearching
                                    ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: "#001234".toColor(),
                                  ),
                                )
                                    : Icon(
                                  Icons.arrow_forward_rounded,
                                  color: "#001234".toColor(),
                                ),
                                ),
                            ],
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: "#001234".toColor(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                    ],
                  ),
                ),


              const SizedBox(height: 24),

              /// ACTION CARDS
              _actionCard(
                icon: Icons.directions_car_filled_rounded,
                title: "Register My Vehicle",
                subtitle:
                "Add your vehicle for secure owner verification.",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterVehiclePage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              /// INFO CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: "#001234".toColor().withOpacity(0.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: "#001234".toColor().withOpacity(0.08),
                      ),
                      child: Icon(
                        Icons.shield_rounded,
                        color: "#001234".toColor(),
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            "Privacy Protected",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: "#001234".toColor(),
                              fontFamily: 'Poppins',
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Your mobile number remains hidden. Communication happens securely through Verify.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.4,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final bool isTablet = size.width >= 700;
    final bool isSmallPhone = size.width < 360;

    final double cardHeight =
    isTablet ? 190 : (isSmallPhone ? 125 : 130);
    final double horizontalPadding =
    isTablet ? 28 : (isSmallPhone ? 18 : 22);

    final double titleSize =
    isTablet ? 30 : (isSmallPhone ? 20 : 24);

    final double subTitleSize =
    isTablet ? 15 : (isSmallPhone ? 12 : 13);

    final double iconContainerSize =
    isTablet ? 64 : (isSmallPhone ? 48 : 54);

    final double iconSize =
    isTablet ? 32 : (isSmallPhone ? 24 : 28);

    return Container(
      height: cardHeight,
      width: double.infinity,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 30 : 24),

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            "#001234".toColor(),
            "#032A63".toColor(),
          ],
        ),

        boxShadow: [
          BoxShadow(
            color: "#001234".toColor().withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 30 : 24),
        child: Stack(
          children: [

            /// TOP RIGHT CIRCLE
            Positioned(
              right: -size.width * 0.08,
              top: -size.width * 0.08,
              child: Container(
                height: isTablet ? 180 : 140,
                width: isTablet ? 180 : 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            /// BOTTOM LEFT CIRCLE
            Positioned(
              left: -size.width * 0.05,
              bottom: -size.width * 0.05,
              child: Container(
                height: isTablet ? 130 : 100,
                width: isTablet ? 130 : 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// ICON
                  Row(
                    children: [
                      Container(
                        height: iconContainerSize,
                        width: iconContainerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                        ),
                        child: Icon(
                          Icons.car_crash_rounded,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),

                      SizedBox(width: isSmallPhone ? 6 : 8),

                      Text(
                        "Smart Vehicle\nSafety Network",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                          fontFamily: 'Poppins',
                        ),
                      ),

                    ],
                  ),

                  /// TITLE

                  SizedBox(height: isSmallPhone ? 6 : 8),

                  /// SUBTITLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Connect with vehicle owners in emergencies.",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: subTitleSize,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.4,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),

      child: Ink(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Row(
          children: [

            /// ICON
            Container(
              height: 58,
              width: 58,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: "#001234".toColor().withOpacity(0.08),
              ),

              child: Icon(
                icon,
                color: "#001234".toColor(),
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: "#001234".toColor(),
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade500,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
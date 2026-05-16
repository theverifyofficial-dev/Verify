import 'package:flutter/material.dart';
import 'package:Verify/utilities/hex_color.dart';

import '../../custom_widget/Paths.dart';
import '../../custom_widget/back_button.dart';
import 'MyVehicle.dart';
import 'Searching.dart';
import 'Vehicle_form.dart';


class Motor extends StatefulWidget {
  const Motor({super.key});

  @override
  State<Motor> createState() => _MotorState();
}

class _MotorState extends State<Motor>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

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
    super.dispose();
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
              _heroCard(),

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

              const SizedBox(height: 16),

              _actionCard(
                icon: Icons.search_rounded,
                title: "Find Vehicle Owner",
                subtitle:
                "Search a vehicle and alert its owner instantly.",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SearchVehiclePage(),
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

  /// 🔥 HERO CARD
  Widget _heroCard() {
    return Container(
      height: 190,
      width: double.infinity,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

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

      child: Stack(
        children: [

          /// BG CIRCLE
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                  child: const Icon(
                    Icons.car_crash_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const Spacer(),

                const Text(
                  "Smart Vehicle\nSafety Network",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                    fontFamily: 'Poppins',
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Quickly connect with vehicle owners in emergencies.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.4,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 ACTION CARD
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
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:Verify/utilities/hex_color.dart';
import '../../custom_widget/Paths.dart';
import '../../custom_widget/back_button.dart';
import '../../model/service_model.dart';
import 'Booking_form.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  late Future<List<ServiceModel>> _serviceFuture;

  @override
  void initState() {
    super.initState();
    _serviceFuture = fetchServices();
  }

  Future<List<ServiceModel>> fetchServices() async {
    final url = Uri.parse(
        "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/display_services_data.php");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as List;
      return decoded.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load services");
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
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Text(
                  "Services",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: "#001234".toColor(),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showServiceGuide,
                  child: Icon(
                    Icons.home_repair_service_rounded,
                    color: "#001234".toColor(),
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 GRID
          Expanded(
            child: FutureBuilder<List<ServiceModel>>(
              future: _serviceFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmer();
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No services found"));
                }

                final services = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: services.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    return _animatedCard(services[index], index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 SHIMMER
  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 🔥 ANIMATED CARD WRAPPER
  Widget _animatedCard(ServiceModel service, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 80)),
      tween: Tween(begin: 0.9, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale as double, child: child);
      },
      child: _serviceCard(service),
    );
  }

  /// 🔥 FINAL CARD UI
  Widget _serviceCard(ServiceModel service) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceBookingPage(
              serviceID: service.id,
              serviceName: service.name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), // 👈 softer
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 150, // 👈 TOTAL FIXED HEIGHT (compact)
            child: Stack(
              children: [

                /// IMAGE
                Positioned.fill(
                  child: Image.network(
                    "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/${service.image}",
                    fit: BoxFit.cover,
                  ),
                ),

                /// GRADIENT
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.5, 0.9],
                        colors: [
                          Colors.black.withOpacity(0.75),
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// TEXT + CTA (MERGED 🔥)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Tap to book",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showServiceGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _serviceGuideSheet(),
    );
  }

  Widget _serviceGuideSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: ListView(
            controller: controller,
            children: [

              /// HANDLE
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// TITLE
              Text(
                "Book Services Easily",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: "#001234".toColor(),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Get trusted professionals at your doorstep on time.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 20),

              /// FLOW STEPS (HIGH LEVEL)
              _guideStep(
                Icons.touch_app,
                "Select a Service",
                "Choose from electrician, plumber, AC repair and more.",
              ),

              _guideStep(
                Icons.edit_note,
                "Fill Booking Form",
                "Enter date, time, location & optional details.",
              ),

              _guideStep(
                Icons.verified_user,
                "Verified Professional Assigned",
                "We assign a trusted service expert to you.",
              ),

              _guideStep(
                Icons.home_repair_service,
                "Service at Your Doorstep",
                "Sit back while the expert handles your work.",
              ),

              const SizedBox(height: 20),

              /// TRUST CARD 🔥
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "All professionals are verified for safety & quality service.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              /// PRICE INFO
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: "#EEF5FF".toColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: "#001234".toColor()),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Visiting charges start from ₹100. Final cost depends on work.",
                        style: const TextStyle(fontSize: 13,color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// CTA BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: "#001234".toColor(),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Got it",style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _guideStep(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: "#001234".toColor().withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: "#001234".toColor(), size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

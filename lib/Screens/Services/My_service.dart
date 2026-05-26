import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../custom_widget/back_button.dart';
import '../../utilities/hex_color.dart';

class MyServicesTabbarPage extends StatefulWidget {
  final int initialIndex;
  const MyServicesTabbarPage({
    super.key,
    this.initialIndex = 0,
  });
  @override
  State<MyServicesTabbarPage> createState() =>
      _MyServicesTabbarPageState();
}

class _MyServicesTabbarPageState extends State<MyServicesTabbarPage> with TickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: "#EEF5FF".toColor(),

      appBar: AppBar(
        leading: const CustomBackButton(),

        backgroundColor: "#001234".toColor(),
        surfaceTintColor: "#001234".toColor(),

        title: const Text(
          "My Services",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),

        bottom: TabBar(
          controller: _tabController,

          isScrollable: true,

          indicatorColor: Colors.white,

          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,

          tabs: const [

            Tab(text: "Pending"),

            Tab(text: "Assigned"),

            Tab(text: "Progress"),

            Tab(text: "Completed"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,

        children: const [

          ServiceListWidget(
            api:
            "https://verifyrealestateandservices.in/Second%20PHP%20FILE/service_application/main_application_for_customer_quary.php",

            status: "Waiting",
          ),

          ServiceListWidget(
            api:
            "https://verifyrealestateandservices.in/Second%20PHP%20FILE/service_application/accept_quary_for_customer.php",

            status: "Assigned",
          ),

          ServiceListWidget(
            api:
            "https://verifyrealestateandservices.in/Second%20PHP%20FILE/service_application/show_api_progressing_for_customer.php",

            status: "In Progress",
          ),

          ServiceListWidget(
            api:
            "https://verifyrealestateandservices.in/Second%20PHP%20FILE/service_application/show_api_complete_customer.php",
            status: "Completed",
          ),
        ],
      ),
    );
  }
}

class ServiceListWidget extends StatefulWidget {

  final String api;
  final String status;

  const ServiceListWidget({
    super.key,
    required this.api,
    required this.status,
  });

  @override
  State<ServiceListWidget> createState() =>
      _ServiceListWidgetState();
}

class _ServiceListWidgetState extends State<ServiceListWidget> {

  double selectedRating = 5;

  final TextEditingController
  ratingController =
  TextEditingController();

  late Future<List<dynamic>> futureData;

  @override
  void initState() {
    super.initState();

    futureData = fetchData();
  }

  Future<List<dynamic>> fetchData() async {

    SharedPreferences prefs =
    await SharedPreferences.getInstance();

    final userID =
        prefs.getInt("id")?.toString() ?? "";

    final response = await http.get(
      Uri.parse("${widget.api}?user_ids=$userID"),
    );

    final decoded = json.decode(response.body);

    if (decoded["status"] == "success") {

      return decoded["data"];
    }

    return [];
  }

  Future<void> _refresh() async {

    setState(() {
      futureData = fetchData();
    });

    await futureData;
  }

  String formatDate(String date) {

    try {

      final parsedDate = DateTime.parse(date);

      return DateFormat("dd MMM yyyy")
          .format(parsedDate);

    } catch (e) {

      return date;
    }
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<List<dynamic>>(
      future: futureData,

      builder: (context, snapshot) {

        if (snapshot.connectionState ==
            ConnectionState.waiting) {

          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.isEmpty) {

          return RefreshIndicator(

            onRefresh: _refresh,

            child: ListView(
              children: [
                SizedBox(
                  height:
                  MediaQuery.of(context).size.height * 0.7,

                  child: Center(
                    child: Text(
                      "No ${widget.status} Services",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.reversed.toList();

        return RefreshIndicator(

          onRefresh: _refresh,

          child: ListView.builder(
            padding: const EdgeInsets.all(16),

            itemCount: data.length,

            itemBuilder: (context, index) {

              final item = data[index];

              return Container(
                margin:
                const EdgeInsets.only(bottom: 16),

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                  BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black.withOpacity(0.05),

                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Row(
                      children: [

                        Expanded(
                          child: Text(
                            item["service_names"] ?? "",

                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.w600,

                              color: Colors.black,
                            ),
                          ),
                        ),

                        _statusBadge(widget.status),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _infoRow(
                      Icons.calendar_month,
                      formatDate(item["suitable_day"] ?? ""),
                    ),

                    _infoRow(
                      Icons.access_time,
                      item["suitable_time"] ?? "",
                    ),

                    _infoRow(
                      Icons.location_on,
                      item["address_for_services"] ?? "",
                    ),

                    const SizedBox(height: 10),

                    if (item["description"] != null &&
                        item["description"]
                            .toString()
                            .isNotEmpty)

                      Container(
                        width: double.infinity,

                        padding:
                        const EdgeInsets.all(12),

                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,

                          borderRadius:
                          BorderRadius.circular(12),
                        ),

                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            Icon(
                              Icons.notes,
                              color:
                              Colors.blue.shade800,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                item["description"],
                                style: const TextStyle(
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),


                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(

                        color: widget.status == "Waiting"
                            ? Colors.orange.shade50
                            : widget.status == "Assigned"
                            ? Colors.blue.shade50
                            : widget.status == "In Progress"
                            ? Colors.deepPurple.shade50
                            : Colors.green.shade50,

                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Icon(

                            widget.status == "Waiting"
                                ? Icons.search
                                : widget.status == "Assigned"
                                ? Icons.support_agent
                                : widget.status == "In Progress"
                                ? Icons.home_repair_service
                                : Icons.verified,

                            color: widget.status == "Waiting"
                                ? Colors.orange
                                : widget.status == "Assigned"
                                ? Colors.blue
                                : widget.status == "In Progress"
                                ? Colors.deepPurple
                                : Colors.green,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(

                              widget.status == "Waiting"

                                  ? "We are finding the best technician for your service request."

                                  : widget.status == "Assigned"

                                  ? "A technician has been assigned to your service request. Share the OTP to start service."

                                  : widget.status == "In Progress"

                                  ? "Your service is currently in progress. Share the OTP after work completion."

                                  : "Your service has been completed successfully.",

                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 13.5,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),



                    if ((widget.status == "Assigned" ||
                        widget.status == "In Progress") &&
                        item["rendom_otp"] != null &&
                        item["rendom_otp"].toString().isNotEmpty)

                      Container(
                        width: double.infinity,

                        margin: const EdgeInsets.only(top: 16),

                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,

                          borderRadius: BorderRadius.circular(16),

                          border: Border.all(
                            color: Colors.orange.shade200,
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            Row(
                              children: [

                                Icon(
                                  Icons.lock_clock_outlined,
                                  color: Colors.orange.shade800,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    "Verification OTP",

                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Center(
                              child: SelectableText(
                                item["rendom_otp"],

                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 8,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              widget.status == "Assigned"
                                  ? "Give this OTP to technician to start your service."
                                  : "Give this OTP to technician to complete your service.",

                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if ((widget.status == "Assigned" ||
                        widget.status == "In Progress" ||
                        widget.status == "Completed") &&

                        item["assign_agent_name"] != null &&
                        item["assign_agent_name"]
                            .toString()
                            .isNotEmpty)

                      Container(
                        width: double.infinity,

                        margin: const EdgeInsets.only(top: 16),

                        padding: const EdgeInsets.all(14),

                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Row(
                          children: [

                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blue.shade100,

                              child: Icon(
                                Icons.support_agent,
                                color: Colors.blue.shade800,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,

                                children: [

                                  Text(
                                    item["assign_agent_name"],

                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    "Verified Technician",

                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (item["assign_agent_number"] != null &&
                        item["assign_agent_number"]
                            .toString()
                            .isNotEmpty)

                      const SizedBox(height: 16),



                    if (item["assign_agent_number"] != null &&
                        item["assign_agent_number"]
                            .toString()
                            .isNotEmpty)

                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton.icon(

                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.green,

                            padding:
                            const EdgeInsets.symmetric(
                              vertical: 14,
                            ),

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(14),
                            ),
                          ),

                          onPressed: () async {

                            final number =
                            item["assign_agent_number"];

                            await launchUrl(
                              Uri.parse("tel:$number"),
                            );
                          },

                          icon: const Icon(
                            Icons.call,
                            color: Colors.white,
                          ),

                          label: const Text(
                            "Call Technician",

                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),
                      ),



                    if (widget.status == "Completed")

                      Padding(
                        padding: const EdgeInsets.only(top: 16),

                        child: SizedBox(
                          width: double.infinity,

                          child: ElevatedButton.icon(

                            style: ElevatedButton.styleFrom(
                              backgroundColor: "#001234".toColor(),

                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                            ),

                            onPressed: () {

                              _showRatingBottomSheet(item);
                            },

                            icon: const Icon(
                              Icons.star_rate_rounded,
                              color: Colors.amber,
                            ),

                            label: const Text(
                              "Rate Service",

                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),


                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showRatingBottomSheet(dynamic item) {

    selectedRating = 5;
    ratingController.clear();

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (_) {

        return StatefulBuilder(

          builder: (context, setModalState) {

            return Container(

              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom:
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),

              decoration: const BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [

                  Container(
                    width: 50,
                    height: 5,



                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,

                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),

                  Align(
                    alignment: Alignment.topRight,

                    child: CircleAvatar(
                      child: IconButton(
                      
                        onPressed: () {
                      
                          Navigator.pop(context);
                        },
                      
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Icon(
                    Icons.star_rate_rounded,
                    size: 60,
                    color: Colors.amber,
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    "Rate Your Experience",

                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Your feedback helps us improve service quality.",

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: List.generate(5, (index) {

                      return IconButton(

                        onPressed: () {

                          setModalState(() {
                            selectedRating =
                                index + 1.0;
                          });
                        },

                        icon: Icon(

                          index < selectedRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,

                          color: Colors.amber,
                          size: 38,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: ratingController,

                    maxLines: 4,

                    decoration: InputDecoration(

                      hintText:
                      "Write your feedback (optional)",

                      filled: true,

                      fillColor: "#EEF5FF".toColor(),

                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(16),

                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        "#001234".toColor(),

                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 15,
                        ),

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                      ),

                      onPressed: () async {

                        await submitRating(

                          item,

                          selectedRating.toInt(),

                          ratingController.text,
                        );

                        Navigator.pop(context);
                      },

                      child: const Text(
                        "Submit Review",

                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ),                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> submitRating(
      dynamic item,
      int stars,
      String message,
      ) async {

    try {

      SharedPreferences prefs =
      await SharedPreferences.getInstance();

      final userID =
          prefs.getInt("id")?.toString() ?? "";

      final response = await http.post(

        Uri.parse(
          "https://verifyrealestateandservices.in/Second%20PHP%20FILE/service_application/insert_raiting.php",
        ),

        body: {

          "service_completed_id":
          item["id"].toString(),

          "services_id":
          item["services_id"].toString(),

          "user_ids":
          userID,

          "user_name":
          item["user_names"] ?? "",

          "user_number":
          item["user_number"] ?? "",

          "agent_number":
          item["assign_agent_number"] ?? "",

          "assign_agent_name":
          item["assign_agent_name"] ?? "",

          "rating":
          stars.toString(),

          "review":
          message,
        },
      );

      final decoded =
      json.decode(response.body);

      if (decoded["status"] == "success") {

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(
            content:
            Text("Thanks for your feedback ❤️"),
          ),
        );

      } else {

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(
            content: Text(
              decoded["message"] ??
                  "Failed to submit review",
            ),
          ),
        );
      }

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Widget _infoRow(
      IconData icon,
      String value,
      ) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            size: 19,
            color: Colors.grey.shade700,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              value,

              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text) {

    Color color = Colors.orange;

    if (text == "Assigned") {
      color = Colors.blue;
    }

    if (text == "In Progress") {
      color = Colors.deepPurple;
    }

    if (text == "Completed") {
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.12),

        borderRadius:
        BorderRadius.circular(30),
      ),

      child: Text(
        text,

        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
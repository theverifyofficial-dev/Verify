import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../custom_widget/back_button.dart';
import '../../../model/booked_visit_model.dart';
import '../../../utilities/hex_color.dart';


class PropertyVisitHistoryPage extends StatefulWidget {
  const PropertyVisitHistoryPage({super.key});

  @override
  State<PropertyVisitHistoryPage> createState() =>
      _PropertyVisitHistoryPageState();
}

class _PropertyVisitHistoryPageState
    extends State<PropertyVisitHistoryPage> {

  bool loading = true;

  List<PropertyVisitModel> visits = [];

  @override
  void initState() {
    super.initState();
    loadVisits();
  }

  Future<void> loadVisits() async {
    setState(() {
      loading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getInt("id") ?? 0;

      final response = await http.get(
        Uri.parse(
          "https://verifyrealestateandservices.in/Second%20PHP%20FILE/book_shedual/show_property_visit_by_user_id.php?user_id=$userId",
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["success"] == true) {
          final data = (json["data"] as List)
              .map((e) => PropertyVisitModel.fromJson(e))
              .toList();

          visits = data.reversed.toList();
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      loading = false;
    });
  }

  String formatDate(String value) {
    try {
      return DateFormat("dd MMM yyyy").format(
        DateTime.parse(value),
      );
    } catch (e) {
      return value;
    }
  }

  Color statusChipColor(String status) {
    switch (status.toLowerCase()) {
      case "booked":
        return const Color(0xFF2563EB); // Blue
      case "confirmed":
        return const Color(0xFF16A34A); // Green
      case "completed":
        return const Color(0xFF0F766E); // Teal
      case "cancelled":
        return const Color(0xFFDC2626); // Red
      default:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: const Color(0xffF4F7FB),

      appBar: AppBar(

        elevation: 0,

        centerTitle: true,

        leading: const CustomBackButton(),


        backgroundColor: "#001234".toColor(),

        title: const Text(

          "My Property Visits",

          style: TextStyle(

            color: Colors.white,

            fontWeight: FontWeight.w600,

          ),

        ),

      ),

      body: RefreshIndicator(

        onRefresh: loadVisits,

        child: loading

            ? const Center(

          child: CircularProgressIndicator(),

        )

            : visits.isEmpty

            ? _emptyWidget()

            : ListView.builder(

          padding: const EdgeInsets.all(16),

          itemCount: visits.length,

          itemBuilder: (context, index) {
            final visit = visits[index];

            return _visitCard(visit);
          },

        ),

      ),

    );
  }

  Widget _emptyWidget() {
    return ListView(

      children: [

        const SizedBox(height: 100),

        Icon(

          Icons.event_busy,

          size: 90,

          color: Colors.grey.shade400,

        ),

        const SizedBox(height: 20),

        const Center(

          child: Text(

            "No Property Visits Yet",

            style: TextStyle(

              fontSize: 22,

              fontWeight: FontWeight.bold,

            ),

          ),

        ),

        const SizedBox(height: 10),

        Padding(

          padding: const EdgeInsets.symmetric(horizontal: 30),

          child: Text(

            "Book your first property visit and it will appear here.",

            textAlign: TextAlign.center,

            style: TextStyle(

              color: Colors.grey.shade700,

              fontSize: 15,

              height: 1.5,

            ),

          ),

        ),

      ],

    );
  }

  Widget _visitCard(PropertyVisitModel visit) {


    return InkWell(

      borderRadius: BorderRadius.circular(22),

      onTap: () {
        showVisitBottomSheet(visit);
      },

      child: Container(

        margin: const EdgeInsets.only(bottom: 16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(22),

          boxShadow: [

            BoxShadow(

              color: Colors.black.withOpacity(.05),

              blurRadius: 10,

              offset: const Offset(0, 5),

            )

          ],

        ),

        child: Column(

          children: [

            Container(

              padding: const EdgeInsets.all(18),

              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF153A73),
                    Color(0xFF0B1F46),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),

              child: Row(

                children: [

                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white24,
                      ),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          visit.bhk,

                          style: const TextStyle(

                            color: Colors.white,

                            fontWeight: FontWeight.bold,

                            fontSize: 18,

                          ),

                        ),

                        const SizedBox(height: 3),

                        Text(

                          "Property ID : ${visit.propertyId}",

                          style: const TextStyle(

                            color: Colors.white70,

                          ),

                        ),

                      ],

                    ),

                  ),

                  Container(

                    padding: const EdgeInsets.symmetric(

                      horizontal: 14,

                      vertical: 8,

                    ),

                    decoration: BoxDecoration(

                      color: statusChipColor(visit.visitingStatus),

                      borderRadius: BorderRadius.circular(30),

                    ),

                    child: Text(

                      visit.visitingStatus,

                      style: const TextStyle(

                        color: Colors.white,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                  ),

                ],

              ),

            ),

            Padding(

              padding: const EdgeInsets.all(18),

              child: Column(

                children: [

                  _row(

                    Icons.calendar_today,

                    "Visit Date",

                    formatDate(visit.visitDate),

                  ),

                  const SizedBox(height: 12),

                  _row(

                    Icons.schedule,

                    "Time",

                    visit.visitTime,

                  ),

                  const SizedBox(height: 12),

                  _row(

                    Icons.location_on,

                    "Location",

                    visit.preferredLocation,

                  ),

                  const Divider(height: 28),

                  Row(
                    children: [

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusChipColor(visit.paymentStatus).withOpacity(.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [

                            Icon(
                              Icons.credit_card_rounded,
                              color: statusChipColor(visit.paymentStatus),
                              size: 16,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              visit.paymentStatus,
                              style: TextStyle(
                                color: statusChipColor(visit.paymentStatus),
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                          ],
                        ),
                      ),

                      const Spacer(),

                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.green,
                        size: 20,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        "₹ ${visit.total}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),

                    ],
                  )

                ],

              ),

            ),

          ],

        ),

      ),

    );
  }

  Widget _row(IconData icon,

      String title,

      String value,) {
    return Row(

      children: [

        Icon(

          icon,

          color: "#001234".toColor(),

          size: 18,

        ),

        const SizedBox(width: 10),

        SizedBox(

          width: 90,

          child: Text(

            title,

            style: const TextStyle(

              fontWeight: FontWeight.w600,

            ),

          ),

        ),

        Expanded(

          child: Text(

            value,

            style: const TextStyle(

              color: Colors.black87,

            ),

          ),

        ),

      ],

    );
  }

  void showVisitBottomSheet(PropertyVisitModel visit) {
    showModalBottomSheet(

      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // <-- Required


      builder: (_) {
        return FractionallySizedBox(
            heightFactor: 0.85, // 85% of screen
            child:  Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  Container(

                    width: 60,

                    height: 5,

                    decoration: BoxDecoration(

                      color: Colors.grey.shade300,

                      borderRadius: BorderRadius.circular(20),

                    ),

                  ),

                  const SizedBox(height: 25),

                  Container(

                    height: 90,

                    width: 90,

                    decoration: BoxDecoration(

                      shape: BoxShape.circle,

                      color: "#001234".toColor().withOpacity(.08),

                    ),

                    child: Icon(

                      Icons.home_work,

                      size: 48,

                      color: "#001234".toColor(),

                    ),

                  ),

                  const SizedBox(height: 18),

                  Text(

                    visit.bhk,

                    style: const TextStyle(

                      fontSize: 24,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const SizedBox(height: 5),

                  Text(

                    "Booking #${visit.id}",

                    style: TextStyle(

                      color: Colors.grey.shade700,

                      fontSize: 15,

                    ),

                  ),

                  const SizedBox(height: 25),

                  Container(

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(

                      color: "#EEF5FF".toColor(),

                      borderRadius: BorderRadius.circular(20),

                    ),

                    child: Column(

                      children: [

                        _dialogRow(

                          Icons.location_on,

                          "Preferred Location",

                          visit.preferredLocation,

                        ),

                        const SizedBox(height: 15),

                        _dialogRow(

                          Icons.calendar_today,

                          "Visit Date",

                          formatDate(visit.visitDate),

                        ),

                        const SizedBox(height: 15),

                        _dialogRow(

                          Icons.schedule,

                          "Visit Time",

                          visit.visitTime,

                        ),

                        const SizedBox(height: 15),

                        _dialogRow(

                          Icons.wallet,

                          "Budget",

                          "₹ ${visit.budget}",

                        ),

                        const SizedBox(height: 15),

                        _dialogRow(

                          Icons.payments,

                          "Visit Fee",

                          "₹ ${visit.visitFee}",

                        ),

                        const SizedBox(height: 15),

                        _dialogRow(

                          Icons.receipt_long,

                          "GST",

                          "₹ ${visit.gst}",

                        ),

                        const SizedBox(height: 15),

                        _dialogRow(

                          Icons.account_balance_wallet,

                          "Gateway Charges",

                          "₹ ${visit.gatewayFee}",

                        ),

                        const Divider(height: 30),

                        Row(

                          children: [

                            const Text(

                              "Total Paid",

                              style: TextStyle(

                                fontWeight: FontWeight.bold,

                                fontSize: 17,

                              ),

                            ),

                            const Spacer(),

                            Text(

                              "₹ ${visit.total}",

                              style: TextStyle(

                                fontWeight: FontWeight.bold,

                                fontSize: 20,

                                color: Colors.green.shade700,

                              ),

                            ),

                          ],

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: 20),

                  if (visit.requirements.isNotEmpty)

                    Container(

                      width: double.infinity,

                      padding: const EdgeInsets.all(18),

                      decoration: BoxDecoration(

                        color: Colors.orange.shade50,

                        borderRadius: BorderRadius.circular(18),

                      ),

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          const Row(

                            children: [

                              Icon(

                                Icons.notes,

                                color: Colors.orange,

                              ),

                              SizedBox(width: 8),

                              Text(

                                "Requirements",

                                style: TextStyle(

                                  fontWeight: FontWeight.bold,

                                  fontSize: 16,

                                ),

                              ),

                            ],

                          ),

                          const SizedBox(height: 12),

                          Text(

                            visit.requirements,

                            style: const TextStyle(

                              height: 1.5,

                            ),

                          ),

                        ],

                      ),

                    ),

                  const SizedBox(height: 20),

                  Container(

                    width: double.infinity,

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(

                      color: "#001234".toColor().withOpacity(.06),

                      borderRadius: BorderRadius.circular(18),

                    ),

                    child: Row(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Icon(

                          Icons.support_agent,

                          color: "#001234".toColor(),

                        ),

                        const SizedBox(width: 12),

                        const Expanded(

                          child: Text(

                            "Our property advisor will contact you before your scheduled visit. Please keep your phone reachable.",

                            style: TextStyle(

                              height: 1.5,

                              fontSize: 14,

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: 25),

                  SizedBox(

                    width: double.infinity,

                    height: 55,

                    child: ElevatedButton(

                      style: ElevatedButton.styleFrom(

                        backgroundColor: "#001234".toColor(),

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(30),

                        ),

                      ),

                      onPressed: () {
                        Navigator.pop(context);
                      },

                      child: const Text(

                        "Close",

                        style: TextStyle(

                          color: Colors.white,

                          fontSize: 16,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                    ),

                  ),


                ],

              ),

            ),

          ),

        ));
      },

    );
  }

  Widget _dialogRow(IconData icon,

      String title,

      String value,) {
    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Icon(

          icon,

          color: "#001234".toColor(),

          size: 20,

        ),

        const SizedBox(width: 12),

        SizedBox(

          width: 120,

          child: Text(

            title,

            style: const TextStyle(

              fontWeight: FontWeight.w600,

            ),

          ),

        ),

        Expanded(

          child: Text(

            value,

            style: const TextStyle(

              color: Colors.black87,

            ),

          ),

        ),

      ],

    );
  }
}


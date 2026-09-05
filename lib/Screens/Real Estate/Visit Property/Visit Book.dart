import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../custom_widget/back_button.dart';
import '../../../utilities/hex_color.dart';
import '../../../utilities/membership_helper.dart';
import '../../Membership/membership_page.dart';

class PropertyVisitBookingPage extends StatefulWidget {
  final String bhk;
  final String propertyType;
  final String location;

  const PropertyVisitBookingPage({
    super.key,
    required this.bhk,
    required this.propertyType,
    required this.location,
  });

  @override
  State<PropertyVisitBookingPage> createState() =>
      _PropertyVisitBookingPageState();
}

class _PropertyVisitBookingPageState extends State<PropertyVisitBookingPage> {
  // ── Membership gate ──────────────────────────────────────
  bool _checkingMembership = true;
  bool _isMember = false;

  @override
  void initState() {
    super.initState();
    _checkMembership();

    selectedBhk = widget.bhk;
    if (!bhkOptions.contains(selectedBhk)) {
      bhkOptions.insert(0, selectedBhk);
    }
  }

  Future<void> _checkMembership() async {
    setState(() => _checkingMembership = true);
    final active = await MembershipHelper.isActive();
    setState(() {
      _isMember = active;
      _checkingMembership = false;
    });

    if (!active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMembershipRequiredDialog();
      });
    }
  }

  Future<void> _goToMembershipPurchase() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MembershipPurchasePage()),
    );
    if (result == true) {
      _checkMembership();
    }
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  // ── Form fields (free-visit booking) ────────────────────
  final budgetController = TextEditingController();
  bool bookingLoading = false;
  bool _termsAccepted = false;

  late String selectedBhk;
  final List<String> bhkOptions = ["1 RK", "1 BHK", "2 BHK", "3 BHK", "Commercial"];

  List<String> selectedFloors = [];
  final List<String> floorOptions = [
    "Ground Floor",
    "1st Floor",
    "2nd Floor",
    "3rd Floor",
    "4th Floor",
  ];

  final List<String> requirementLevelOptions = ["Mandatory", "Yes", "Optionally", "No"];

  final List<String> fieldWorkerOptions = const [
    'Saurabh yadav',
    'Faizan Khan',
    'Ravi Kumar',
    'Yash',
  ];

  String? selectedFurnishing;
  String? selectedParking;
  String? selectedBuyRent;
  String? selectedFieldWorker;
  DateTime? selectedShiftingDate;
  DateTime? selectedVisitDate;
  TimeOfDay? selectedVisitTime;

  String _buildRequirementString() {
    final parts = [
      "BHK: $selectedBhk",
      "Property Type: ${widget.propertyType}",
      "Location: ${widget.location}",
      "Floor: ${selectedFloors.join(', ')}",
      "Furnishing: ${selectedFurnishing ?? ''}",
      "Buy/Rent: ${selectedBuyRent ?? ''}",
    ];
    return parts.join(", ");
  }

  bool _validateForm() {
    if (budgetController.text.trim().isEmpty) {
      _showMessage("Please enter your preferred budget.");
      return false;
    }
    if (selectedFloors.isEmpty) {
      _showMessage("Please select at least one preferred floor.");
      return false;
    }
    if (selectedFurnishing == null) {
      _showMessage("Please select furnished type.");
      return false;
    }
    if (selectedBuyRent == null) {
      _showMessage("Please select Buy or Rent.");
      return false;
    }
    if (selectedParking == null) {
      _showMessage("Please select parking Required.");
      return false;
    }
    if (selectedVisitDate == null) {
      _showMessage("Please select your preferred visiting date.");
      return false;
    }
    if (selectedVisitTime == null) {
      _showMessage("Please select your preferred visiting time.");
      return false;
    }
    if (selectedShiftingDate == null) {
      _showMessage("Please select preferred shifting date.");
      return false;
    }
    if (selectedFieldWorker == null) {
      _showMessage("Please select field worker.");
      return false;
    }
    return true;
  }

  // ── Booking (free — no payment gateway involved at all) ──
  Future<void> _bookFreeVisit() async {
    setState(() => bookingLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("id") ?? 0;

      final visitTimeStr = selectedVisitTime != null
          ? selectedVisitTime!.format(context)
          : "";

      final response = await http.post(
        Uri.parse(
          "https://verifyrealestateandservices.in/Second%20PHP%20FILE/book_shedual/create_order.php",
        ),
        body: {
          "user_id": userId.toString(),
          "budget": budgetController.text,
          "preferred_location": widget.location,
          "requirements": _buildRequirementString(),
          "feild_workar_name": selectedFieldWorker,
          "shifting_date": selectedShiftingDate != null
              ? DateFormat("yyyy-MM-dd").format(selectedShiftingDate!)
              : "",
          "visiting_date": selectedVisitDate != null
              ? DateFormat("yyyy-MM-dd").format(selectedVisitDate!)
              : "",
          "visiting_time": visitTimeStr,
          "furnishing": selectedFurnishing ?? "",
        },
      );

      setState(() => bookingLoading = false);

      if (response.statusCode != 200) {
        _showMessage("Unable to book your visit.");
        return;
      }

      final json = jsonDecode(response.body);

      if (json["status"] != true) {
        _showMessage(json["message"] ?? "Something went wrong.");
        return;
      }

      _showSuccessDialog(bookingId: json["booking_id"].toString());
    } catch (e) {
      setState(() => bookingLoading = false);
      _showMessage(e.toString());
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessDialog({required String bookingId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 95,
                width: 95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(.10),
                ),
                child: const Icon(Icons.check_circle, size: 55, color: Colors.green),
              ),
              const SizedBox(height: 22),
              Text(
                "Visit Booked — Free",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: "#001234".toColor(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your membership covered this visit. Our advisor will contact you shortly.",
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, fontSize: 14.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: "#001234".toColor(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Done",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMembershipRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: "#001234".toColor().withOpacity(0.08),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: "#001234".toColor(),
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Membership Required",
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Property visits are free for members. Purchase a yearly membership to book this visit at no extra cost.",
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: "#001234".toColor(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _goToMembershipPurchase();
                  },
                  child: const Text(
                    "Purchase Membership",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Terms & Conditions bottom sheet ──────────────────────
  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: "#EEF5FF".toColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: "#001234".toColor(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Terms & Conditions",
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Free Property Visit (Membership)",
                                style: TextStyle(fontSize: 12.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "TERMS AND CONDITIONS OF SERVICE",
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),

                          _termsParagraph(
                            'By checking the agreement box and confirming this booking, you ("User" or "Client") explicitly acknowledge that you have read, understood, and agreed to be legally bound by these Terms and Conditions.',
                          ),

                          _termsSection(
                            "1. Scope of Service (Membership-Covered Visit)",
                            [
                              "This visit is covered under your active yearly membership and carries no separate visit fee.",
                              "The Company's service obligation is strictly limited to planning, coordinating, and conducting one visit session to present available flats that match your specified budget segment.",
                              "Once matching flats within your specified budget segment have been shown to you, the Company's service obligations for this booking are fully executed and complete.",
                            ],
                          ),

                          _termsSection(
                            "2. Anti-Bypass, Anti-Circumvention & Strict Legal Action",
                            [
                              "Protected Properties: Any flat, residential unit, or property showcased, introduced, or identified to you during the visit is deemed a protected business introduction made through our platform.",
                              "Prohibition of Direct Dealing: You agree that you shall not, directly or indirectly (either personally, or through family members, relatives, legal heirs, corporate entities, partners, or third-party representatives), buy, rent, lease, or enter into any deal with the property owner without involving the Company.",
                              "Commercial Fraud: Any attempt to bypass the Company and contract directly with the property owner or listing representative for a property shown by us constitutes commercial fraud and a material breach of contract.",
                              "Legal Proceedings & Liquidated Damages: If you violate this clause and buy or rent a flat shown by us without our involvement, the Company reserves the right to initiate strict legal action against you in court. Upon such breach, you shall be legally liable to pay liquidated damages equal to our standard platform commission/brokerage fee (2% of total property purchase price or two months' gross rental value, whichever applies) along with all legal costs and court expenses incurred in recovery.",
                            ],
                          ),

                          _termsSection(
                            "3. Absolute Limitation of Liability & Disclaimers",
                            [
                              "Limitation of Scope: Apart from planning, coordinating, and showing you flats in your budget segment, the Company holds no responsibility or liability whatsoever regarding the properties.",
                              "No Ownership or Structural Guarantees: The Company is not responsible for the physical condition, structural integrity, title clarity, legal encumbrances, utility connections, or ownership disputes of any flat shown.",
                              "User Due Diligence: You are solely responsible for conducting independent legal title verification, document checks, and physical inspections prior to entering into any purchase or lease contract with a property owner.",
                              "Owner Disputes: The Company shall not be held liable for any misrepresentations, defaults, or contractual disputes arising between you and the property owner.",
                            ],
                          ),

                          _termsSection(
                            "4. User Information Accuracy & Contact Obligations",
                            [
                              "You warrant that all information provided during booking (name, phone number, budget, visiting date/time preference) is complete and accurate.",
                              "If the Company or field representative is unable to contact you via phone or WhatsApp due to incorrect contact details provided by you, the scheduled visit may be forfeited and will need to be rebooked.",
                            ],
                          ),

                          _termsSection(
                            "5. Site Conduct & Indemnification",
                            [
                              "You agree to maintain proper decorum, follow safety protocols, and respect private premises during site viewings.",
                              "You agree to defend, indemnify, and hold harmless the Company, its directors, employees, and field agents from any claims, losses, or property damages resulting from your personal conduct or negligence during a visit.",
                            ],
                          ),

                          _termsSection(
                            "6. Force Majeure",
                            [
                              "The Company shall not be held liable or considered in breach of contract for any failure or delay in conducting a visit resulting from events beyond reasonable control, including extreme weather, public transport disruptions, government restrictions, or sudden unavailability of the property owner.",
                            ],
                          ),

                          _termsSection(
                            "7. Electronic Agreement & Governing Law",
                            [
                              "Electronic Contract Validity: By checking the agreement box, you acknowledge that this constitutes a legally valid and binding electronic contract under Section 10A of the Information Technology Act, 2000.",
                              "Severability: If any provision of these Terms is held to be invalid or unenforceable by a court, the remaining provisions shall remain in full force and effect.",
                              "Governing Law & Jurisdiction: This agreement is governed by the laws of India, and any legal disputes shall be subject to the exclusive jurisdiction of the local courts where the Company operates.",
                            ],
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: "#001234".toColor(),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          child: const Text(
                            "I Understand",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _termsParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13.5, height: 1.6, color: Colors.black87),
      ),
    );
  }

  Widget _termsSection(String title, List<String> paragraphs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: "#001234".toColor(),
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ...paragraphs.map(
                (text) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                text,
                style: const TextStyle(fontSize: 13.5, height: 1.6, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: "#001234".toColor(),
        centerTitle: true,
        leading: const CustomBackButton(),
        title: const Text(
          "Property Visit",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _checkingMembership
          ? const Center(child: CircularProgressIndicator())
          : _bookingForm(),
      bottomNavigationBar: _checkingMembership ? null : _bookingBottomBar(),
    );
  }

  Widget _bookingForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerCard(),
          const SizedBox(height: 20),
          _bhkSelectorSection(),
          const SizedBox(height: 20),
          _propertyCard(),
          const SizedBox(height: 22),
          _budgetSection(),
          const SizedBox(height: 20),
          _additionalDetailsSection(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: ["#001234".toColor(), "#173B74".toColor()]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Book Your Free Visit",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 10),
          Text(
            "This visit is covered by your membership. Our advisor will arrange multiple $selectedBhk properties for you.",
            style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _bhkSelectorSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.meeting_room_outlined, color: "#001234".toColor()),
              const SizedBox(width: 10),
              const Text("Configuration (BHK)", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 15),
          _dropdownField(
            label: "Select BHK",
            value: selectedBhk,
            options: bhkOptions,
            onChanged: (v) => setState(() => selectedBhk = v ?? selectedBhk),
          ),
        ],
      ),
    );
  }

  Widget _propertyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apartment, color: "#001234".toColor()),
              const SizedBox(width: 10),
              const Text("Selected Preference", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 18),
          _infoTile("Property Type", widget.propertyType),
          _infoTile("Configuration", selectedBhk),
          _infoTile("Location", widget.location),
        ],
      ),
    );
  }

  Widget _budgetSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Preferred Budget", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 15),
          TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Enter your budget",
              prefixIcon: const Icon(Icons.currency_rupee),
              filled: true,
              fillColor: "#EEF5FF".toColor(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _additionalDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Additional Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 15),
          const Text("Preferred Floor(s)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: floorOptions.map((floor) {
              final isSelected = selectedFloors.contains(floor);
              return FilterChip(
                label: Text(floor),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedFloors.add(floor);
                    } else {
                      selectedFloors.remove(floor);
                    }
                  });
                },
                selectedColor: "#001234".toColor().withOpacity(0.15),
                checkmarkColor: "#001234".toColor(),
                backgroundColor: "#EEF5FF".toColor(),
                labelStyle: TextStyle(
                  color: isSelected ? "#001234".toColor() : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? "#001234".toColor() : Colors.transparent),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 15),
          _dropdownField(
            label: "Furnished Type",
            value: selectedFurnishing,
            options: const ["Furnished", "Semi-Furnished", "Unfurnished"],
            onChanged: (v) => setState(() => selectedFurnishing = v),
          ),
          const SizedBox(height: 12),
          _dropdownField(
            label: "Buy / Rent",
            value: selectedBuyRent,
            options: const ["Buy", "Rent"],
            onChanged: (v) => setState(() => selectedBuyRent = v),
          ),
          const SizedBox(height: 12),
          _dropdownField(
            label: "Parking Required",
            value: selectedParking,
            options: requirementLevelOptions,
            onChanged: (v) => setState(() => selectedParking = v),
          ),
          const SizedBox(height: 12),

          // Visiting Date
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
              );
              if (picked != null) {
                setState(() => selectedVisitDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(color: "#EEF5FF".toColor(), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Icon(Icons.event_available_outlined, color: "#001234".toColor()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedVisitDate == null
                          ? "Preferred Visiting Date"
                          : DateFormat("dd MMMM yyyy").format(selectedVisitDate!),
                      style: TextStyle(
                        fontSize: 15,
                        color: selectedVisitDate == null ? Colors.grey : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Visiting Time
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() => selectedVisitTime = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(color: "#EEF5FF".toColor(), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Icon(Icons.schedule_outlined, color: "#001234".toColor()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedVisitTime == null
                          ? "Preferred Visiting Time"
                          : selectedVisitTime!.format(context),
                      style: TextStyle(
                        fontSize: 15,
                        color: selectedVisitTime == null ? Colors.grey : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Shifting Date (separate from visiting date)
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => selectedShiftingDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(color: "#EEF5FF".toColor(), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Icon(Icons.event, color: "#001234".toColor()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedShiftingDate == null
                          ? "Preferred Shifting Date"
                          : DateFormat("dd MMMM yyyy").format(selectedShiftingDate!),
                      style: TextStyle(
                        fontSize: 15,
                        color: selectedShiftingDate == null ? Colors.grey : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _dropdownField(
            label: "Field Worker Name",
            value: selectedFieldWorker,
            options: fieldWorkerOptions,
            onChanged: (v) => setState(() => selectedFieldWorker = v),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(title, style: const TextStyle(color: Colors.black54))),
          Expanded(flex: 6, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _bookingBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _termsAccepted,
                    activeColor: "#001234".toColor(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "I agree to the",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                TextButton(
                  onPressed: _showTermsAndConditions,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Terms & Conditions",
                    style: TextStyle(
                      color: "#001234".toColor(),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Visit Fee", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(
                        "FREE",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: "#001234".toColor(),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        if (!_isMember) {
                          _showMembershipRequiredDialog();
                          return;
                        }
                        if (!_validateForm()) return;
                        if (!_termsAccepted) {
                          _showMessage("Please accept the terms to continue.");
                          return;
                        }
                        if (bookingLoading) return;
                        _bookFreeVisit();
                      },
                      child: bookingLoading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text(
                        "Book Free Visit",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: "#EEF5FF".toColor(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../custom_widget/back_button.dart';
import '../../../model/Calculate_model.dart';
import '../../../utilities/hex_color.dart';

class PropertyVisitBookingPage extends StatefulWidget {

  final String propertyId;
  final String bhk;
  final String propertyType;
  final String location;
  final String name;

  const PropertyVisitBookingPage({
    super.key,
    required this.propertyId,
    required this.bhk,
    required this.propertyType,
    required this.location,
    required this.name,
  });

  @override
  State<PropertyVisitBookingPage> createState() =>
      _PropertyVisitBookingPageState();
}

class _PropertyVisitBookingPageState
    extends State<PropertyVisitBookingPage> {

  bool isLoading = true;

  BookingCalculationModel? calculation;

  final budgetController = TextEditingController();

  final locationController = TextEditingController();

  final requirementController = TextEditingController();

  DateTime? selectedDate;

  String? selectedSlot;

  final List<String> slots = [

    "09:00 AM - 11:00 AM",

    "11:00 AM - 01:00 PM",

    "02:00 PM - 04:00 PM",

    "04:00 PM - 06:00 PM",

    "06:00 PM - 08:00 PM",

  ];

  late Razorpay _razorpay;

  bool paymentLoading = false;

  final floorController = TextEditingController();
  final familyMemberController = TextEditingController();
  final vichleNoController = TextEditingController();

  String? selectedLift;              // "Yes" / "No"
  String? selectedParking;           // "Yes" / "No"
  String? selectedBuyRent;           // "Buy" / "Rent"
  String? selectedFamilyStructure;   // "Nuclear" / "Joint"
  String? selectedReligion;
  DateTime? selectedShiftingDate;

  @override
  void initState() {
    super.initState();

    locationController.text = widget.location;

    loadCalculation();

    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );
  }

  String _buildRequirementString() {
    final parts = [
      "BHK: ${widget.bhk}",
      "Property Type: ${widget.propertyType}",
      "Location: ${locationController.text}",
      "Floor: ${floorController.text}",
      "Buy/Rent: ${selectedBuyRent ?? ''}",
      "Lift Required: ${selectedLift ?? ''}",
      "Parking Required: ${selectedParking ?? ''}",
      if (requirementController.text.trim().isNotEmpty)
        "Notes: ${requirementController.text.trim()}",
    ];
    return parts.join(", ");
  }

  Future<void> loadCalculation() async {

    setState(() {
      isLoading = true;
    });

    final response = await http.post(

      Uri.parse(
          "https://verifyrealestateandservices.in/Second%20PHP%20FILE/book_shedual/calculation_api.php"),

      body: {

        "property_id": widget.propertyId,

        "bhk": widget.bhk,

      },

    );

    if (response.statusCode == 200) {

      calculation = BookingCalculationModel.fromJson(
          jsonDecode(response.body));

    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _openCheckout() async {

    setState(() {
      paymentLoading = true;
    });

    try {

      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getInt("id") ?? 0;

      final response = await http.post(

        Uri.parse(
          "https://verifyrealestateandservices.in/Second%20PHP%20FILE/book_shedual/create_order.php",
        ),

        body: {

          "user_id": userId.toString(),

          "property_id": widget.propertyId,

          "visit_fee": calculation!.visitFee.toString(),

          "gst": calculation!.gst.toString(),

          "gateway_fee": calculation!.gatewayFee.toString(),

          "total": calculation!.total.toString(),

          "budget": budgetController.text,

          "preferred_location": locationController.text,

          "visit_date":
          DateFormat("yyyy-MM-dd").format(selectedDate!),

          "visit_time": selectedSlot!,

          "requirements": _buildRequirementString(),
          "family_structure": selectedFamilyStructure ?? "",
          "family_member": familyMemberController.text,
          "religion": selectedReligion ?? "",
          "feild_workar_name": widget.name,
          "shifting_date": selectedShiftingDate != null
              ? DateFormat("yyyy-MM-dd").format(selectedShiftingDate!)
              : "",
          "vichle_no": vichleNoController.text,
        },

      );

      setState(() {
        paymentLoading = false;
      });

      if (response.statusCode != 200) {

        _showMessage("Unable to create payment order.");

        return;

      }

      final json = jsonDecode(response.body);

      if (json["status"] != true) {

        _showMessage(json["message"]);

        return;

      }

      var options = {

        "key": json["key"],

        "amount": json["amount"],

        "currency": json["currency"],

        "name": "Verify Real Estate",

        "description": "Property Visit Booking",

        "order_id": json["order_id"],

        "prefill": {

          "contact": json["mobile"],

          "email": json["email"],

        },

        "theme": {

          "color": "#001234",

        },

      };

      _razorpay.open(options);

    } catch (e) {

      setState(() {

        paymentLoading = false;

      });

      _showMessage(e.toString());

    }

  }

  Future<void> _verifyPayment({

    required String paymentId,

    required String orderId,

    required String signature,

  }) async {

    try {

      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getInt("id") ?? 0;

      final response = await http.post(

        Uri.parse(
          "https://verifyrealestateandservices.in/Second PHP FILE/book_shedual/verify_payment.php",
        ),

        body: {

          "user_id": userId.toString(),

          "payment_id": paymentId,

          "order_id": orderId,

          "signature": signature,

        },

      );

      if (response.statusCode != 200) {

        _showMessage("Server Error");

        return;

      }

      final json = jsonDecode(response.body);

      if (json["status"] == true) {

        _showSuccessDialog(

          bookingId: json["booking_id"].toString(),

          date: DateFormat(
            "dd MMM yyyy",
          ).format(selectedDate!),

          time: selectedSlot!,

        );

      } else {

        _showMessage(

          json["message"],

        );

      }

    } catch (e) {

      _showMessage(e.toString());

    }

  }

  void _handlePaymentSuccess(

      PaymentSuccessResponse response,

      ) {

    if (response.paymentId == null ||

        response.orderId == null ||

        response.signature == null) {

      _showMessage("Invalid Payment Response");

      return;

    }

    _verifyPayment(

      paymentId: response.paymentId!,

      orderId: response.orderId!,

      signature: response.signature!,

    );

  }

  void _handlePaymentError(

      PaymentFailureResponse response,

      ) {


    _showMessage(

      response.message ?? "Payment Failed",

    );

  }

  void _handleExternalWallet(

      ExternalWalletResponse response,

      ) {

    _showMessage(

      "External Wallet : ${response.walletName}",

    );

  }

  void _showSuccessDialog({
    required String bookingId,
    String? date,
    String? time,
  }) {
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

              /// Success Icon
              Container(
                height: 95,
                width: 95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(.10),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 55,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 22),

              Text(
                "Booking Confirmed",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: "#001234".toColor(),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Your payment was successful and your property visit request has been confirmed.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  fontSize: 14.5,
                ),
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: "#EEF5FF".toColor(),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [

                    _dialogInfoRow(
                      Icons.confirmation_number_outlined,
                      "Booking ID",
                      bookingId,
                    ),

                    if (date != null) ...[
                      const SizedBox(height: 10),
                      _dialogInfoRow(
                        Icons.calendar_month,
                        "Visit Date",
                        date,
                      ),
                    ],

                    if (time != null) ...[
                      const SizedBox(height: 10),
                      _dialogInfoRow(
                        Icons.schedule,
                        "Time Slot",
                        time,
                      ),
                    ],

                    const SizedBox(height: 10),

                    _dialogInfoRow(
                      Icons.payments_outlined,
                      "Payment",
                      "Successful",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.amber.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: const [

                        Icon(
                          Icons.support_agent,
                          color: Colors.orange,
                        ),

                        SizedBox(width: 8),

                        Text(
                          "What happens next?",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                      ],
                    ),

                    SizedBox(height: 14),

                    _stepRow("1", "Our property advisor will contact you shortly."),

                    SizedBox(height: 10),

                    _stepRow("2", "Your requirements will be verified."),

                    SizedBox(height: 10),

                    _stepRow("3", "Multiple matching properties will be shortlisted."),

                    SizedBox(height: 10),

                    _stepRow("4", "A guided property visit will be arranged."),

                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: "#001234".toColor(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {

                    Navigator.pop(context);

                    Navigator.pop(context);

                  },
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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

  Widget _stepRow(String step, String title) {

    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Container(

          height: 24,

          width: 24,

          decoration: BoxDecoration(

            color: "#001234".toColor(),

            shape: BoxShape.circle,

          ),

          alignment: Alignment.center,

          child: Text(

            step,

            style: const TextStyle(

              color: Colors.white,

              fontWeight: FontWeight.bold,

              fontSize: 12,

            ),

          ),

        ),

        const SizedBox(width: 12),

        Expanded(

          child: Text(

            title,

            style: const TextStyle(

              fontSize: 14,

              height: 1.4,

            ),

          ),

        ),

      ],

    );

  }

  Widget _dialogInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: "#001234".toColor()),
        const SizedBox(width: 8),
        Text(
          "$title:",
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13.5,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              color: Colors.black87,
            ),
          ),
        ),
      ],
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

          style: TextStyle(

            color: Colors.white,

            fontWeight: FontWeight.w600,

          ),

        ),

      ),

      body: isLoading

          ? const Center(

        child: CircularProgressIndicator(),

      )

          : SingleChildScrollView(

        padding: const EdgeInsets.all(18),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            _headerCard(),

            const SizedBox(height: 20),

            _propertyCard(),

            const SizedBox(height: 22),

            _budgetSection(),

            const SizedBox(height: 20),

            _locationSection(),

            const SizedBox(height: 20),

            _requirementSection(),

            const SizedBox(height: 20),
            _additionalDetailsSection(),   // <-- missing, add this

            const SizedBox(height: 20),

            _dateSection(),

            const SizedBox(height: 20),

            _timeSlotSection(),

            const SizedBox(height: 20),

            _guidelinesCard(),

            const SizedBox(height: 20),

            _bookingSummaryCard(),

            const SizedBox(height: 120),

          ],

        ),

      ),

      bottomNavigationBar: _bookingBottomBar(),

    );

  }

  Widget _headerCard() {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(24),

        gradient: LinearGradient(

          colors: [

            "#001234".toColor(),

            "#173B74".toColor(),

          ],

        ),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(

            "Book a Property Visit",

            style: TextStyle(

              color: Colors.white,

              fontWeight: FontWeight.bold,

              fontSize: 22,

            ),

          ),

          const SizedBox(height: 10),

          Text(

            "Our property advisor will arrange multiple ${widget.bhk} properties according to your budget and preferences.",

            style: const TextStyle(

              color: Colors.white70,

              height: 1.5,

              fontSize: 15,

            ),

          ),

        ],

      ),

    );

  }

  Widget _propertyCard() {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Icon(

                Icons.apartment,

                color: "#001234".toColor(),

              ),

              const SizedBox(width: 10),

              const Text(

                "Selected Preference",

                style: TextStyle(

                  fontSize: 17,

                  fontWeight: FontWeight.w600,

                ),

              ),

            ],

          ),

          const SizedBox(height: 18),

          _infoTile(

            "Property Type",

            widget.propertyType,

          ),

          _infoTile(

            "Configuration",

            widget.bhk,

          ),

          _infoTile(

            "Location",

            widget.location,

          ),

        ],

      ),

    );

  }

  Widget _budgetSection() {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(

            "Preferred Budget",

            style: TextStyle(

              fontWeight: FontWeight.bold,

              fontSize: 17,

            ),

          ),

          const SizedBox(height: 15),

          TextField(

            controller: budgetController,

            keyboardType: TextInputType.number,

            decoration: InputDecoration(

              hintText: "Enter your budget",

              prefixIcon: const Icon(Icons.currency_rupee),

              filled: true,

              fillColor: "#EEF5FF".toColor(),

              border: OutlineInputBorder(

                borderRadius:

                BorderRadius.circular(18),

                borderSide: BorderSide.none,

              ),

            ),

          ),

        ],

      ),

    );

  }

  Widget _locationSection() {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(

            "Preferred Location",

            style: TextStyle(

              fontWeight: FontWeight.bold,

              fontSize: 17,

            ),

          ),

          const SizedBox(height: 15),

          TextField(

            controller: locationController,

            decoration: InputDecoration(

              prefixIcon: const Icon(

                Icons.location_on,

              ),

              filled: true,

              fillColor: "#EEF5FF".toColor(),

              border: OutlineInputBorder(

                borderRadius:

                BorderRadius.circular(18),

                borderSide: BorderSide.none,

              ),

            ),

          ),

        ],

      ),

    );

  }

  Widget _requirementSection() {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(
            "Any Other Notes",   // was "Additional Requirements"
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 15),

          TextField(

            controller: requirementController,

            maxLines: 4,

            decoration: InputDecoration(

              hintText:
              "Near Metro, Corner Flat, West Facing...",

              hintStyle: TextStyle(color: Colors.grey),

              filled: true,

              fillColor: "#EEF5FF".toColor(),

              border: OutlineInputBorder(

                borderRadius:

                BorderRadius.circular(18),

                borderSide: BorderSide.none,

              ),

            ),

          ),

        ],

      ),

    );

  }

  Widget _additionalDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Additional Details",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: floorController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Preferred Floor",
              filled: true,
              fillColor: "#EEF5FF".toColor(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
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
            label: "Lift Required",
            value: selectedLift,
            options: const ["Yes", "No"],
            onChanged: (v) => setState(() => selectedLift = v),
          ),
          const SizedBox(height: 12),
          _dropdownField(
            label: "Parking Required",
            value: selectedParking,
            options: const ["Yes", "No"],
            onChanged: (v) => setState(() => selectedParking = v),
          ),
          const SizedBox(height: 12),
          _dropdownField(
            label: "Family Structure",
            value: selectedFamilyStructure,
            options: const ["Nuclear", "Joint"],
            onChanged: (v) => setState(() => selectedFamilyStructure = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: familyMemberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "No. of Family Members",
              filled: true,
              fillColor: "#EEF5FF".toColor(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _dropdownField(
            label: "Religion",
            value: selectedReligion,
            options: const ["Hindu", "Muslim", "Sikh", "Christian", "Other"],
            onChanged: (v) => setState(() => selectedReligion = v),
          ),
          const SizedBox(height: 12),
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
              decoration: BoxDecoration(
                color: "#EEF5FF".toColor(),
                borderRadius: BorderRadius.circular(18),
              ),
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
          TextField(
            controller: vichleNoController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: "Vehicle Number (if any)",
              filled: true,
              fillColor: "#EEF5FF".toColor(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
      String title,
      String value,
      ) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 15),

      child: Row(

        children: [

          Expanded(

            flex: 4,

            child: Text(

              title,

              style: const TextStyle(

                color: Colors.black54,

              ),

            ),

          ),

          Expanded(

            flex: 6,

            child: Text(

              value,

              style: const TextStyle(

                fontWeight: FontWeight.w600,

              ),

            ),

          ),

        ],

      ),

    );

  }

  Widget _dateSection() {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(

            "Preferred Visit Date",

            style: TextStyle(

              fontWeight: FontWeight.bold,

              fontSize: 17,

            ),

          ),

          const SizedBox(height: 15),

          InkWell(

            borderRadius: BorderRadius.circular(18),

            onTap: () async {

              final picked = await showDatePicker(

                context: context,

                initialDate: DateTime.now().add(const Duration(days: 1)),

                firstDate: DateTime.now(),

                lastDate: DateTime.now().add(const Duration(days: 90)),

              );

              if (picked != null) {

                setState(() {

                  selectedDate = picked;

                });

              }

            },

            child: Container(

              padding: const EdgeInsets.symmetric(

                horizontal: 18,

                vertical: 16,

              ),

              decoration: BoxDecoration(

                color: "#EEF5FF".toColor(),

                borderRadius: BorderRadius.circular(18),

              ),

              child: Row(

                children: [

                  Icon(

                    Icons.calendar_month,

                    color: "#001234".toColor(),

                  ),

                  const SizedBox(width: 12),

                  Expanded(

                    child: Text(

                      selectedDate == null

                          ? "Select Visit Date"

                          : DateFormat(

                        "dd MMMM yyyy",

                      ).format(selectedDate!),

                      style: TextStyle(

                        fontSize: 15,

                        color: selectedDate == null

                            ? Colors.grey

                            : Colors.black,

                        fontWeight: FontWeight.w500,

                      ),

                    ),

                  ),

                  const Icon(Icons.arrow_forward_ios,size:16),

                ],

              ),

            ),

          ),

        ],

      ),

    );

  }

  Widget _timeSlotSection() {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(

            "Preferred Time Slot",

            style: TextStyle(

              fontWeight: FontWeight.bold,

              fontSize: 17,

            ),

          ),

          const SizedBox(height: 18),

          Wrap(

            spacing: 10,

            runSpacing: 10,

            children: slots.map((slot) {

              final selected = slot == selectedSlot;

              return GestureDetector(

                onTap: () {

                  setState(() {

                    selectedSlot = slot;

                  });

                },

                child: AnimatedContainer(

                  duration: const Duration(milliseconds: 250),

                  padding: const EdgeInsets.symmetric(

                    horizontal: 18,

                    vertical: 12,

                  ),

                  decoration: BoxDecoration(

                    color: selected

                        ? "#001234".toColor()

                        : "#EEF5FF".toColor(),

                    borderRadius: BorderRadius.circular(30),

                    border: Border.all(

                      color: selected

                          ? "#001234".toColor()

                          : Colors.transparent,

                    ),

                  ),

                  child: Row(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Icon(

                        Icons.schedule,

                        size: 18,

                        color: selected

                            ? Colors.white

                            : "#001234".toColor(),

                      ),

                      const SizedBox(width: 8),

                      Text(

                        slot,

                        style: TextStyle(

                          color: selected

                              ? Colors.white

                              : Colors.black87,

                          fontWeight: FontWeight.w600,

                        ),

                      ),

                    ],

                  ),

                ),

              );

            }).toList(),

          ),

        ],

      ),

    );

  }

  Widget _guidelinesCard() {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: Colors.orange.shade50,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(

          color: Colors.orange.shade200,

        ),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Icon(

                Icons.info_outline,

                color: Colors.orange.shade700,

              ),

              const SizedBox(width: 10),

              const Expanded(

                child: Text(

                  "Property Visit Guidelines",

                  style: TextStyle(

                    fontWeight: FontWeight.bold,

                    fontSize: 17,

                  ),

                ),

              ),

            ],

          ),

          const SizedBox(height: 18),

          _guideItem(

            Icons.apartment,

            "One booking allows our advisor to show multiple matching properties.",

          ),

          _guideItem(

            Icons.people,

            "A dedicated property advisor will coordinate your visit.",

          ),

          _guideItem(

            Icons.location_city,

            "Properties will be shortlisted according to your preferred budget and location.",

          ),

          _guideItem(

            Icons.phone,

            "Our team will contact you after successful payment to confirm the schedule.",

          ),

          _guideItem(

            Icons.payments,

            "The visit fee is non-refundable once the booking has been confirmed.",

          ),

        ],

      ),

    );

  }

  Widget _guideItem(

      IconData icon,

      String text,

      ) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 14),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(

            icon,

            size: 20,

            color: "#001234".toColor(),

          ),

          const SizedBox(width: 12),

          Expanded(

            child: Text(

              text,

              style: const TextStyle(

                height: 1.5,

                fontSize: 14,

              ),

            ),

          ),

        ],

      ),

    );

  }

  Widget _bookingSummaryCard() {

    if (calculation == null) {
      return const SizedBox();
    }

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(.05),

            blurRadius: 12,

            offset: const Offset(0,5),

          )

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(

            "Booking Summary",

            style: TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height: 20),

          _priceTile(

            "Property Visit Fee",

            "₹ ${calculation!.visitFee}",

          ),

          _priceTile(

            "GST",

            "₹ ${calculation!.gst}",

          ),

          _priceTile(

            "Gateway Charges",

            "₹ ${calculation!.gatewayFee}",

          ),

          const Divider(height: 28),

          _priceTile(

            "Total Payable",

            "₹ ${calculation!.total}",

            bold: true,

          ),

        ],

      ),

    );

  }

  Widget _priceTile(

      String title,

      String value, {

        bool bold = false,

      }) {

    return Padding(

      padding: const EdgeInsets.symmetric(

        vertical: 8,

      ),

      child: Row(

        children: [

          Expanded(

            child: Text(

              title,

              style: TextStyle(

                fontSize: bold ? 17 : 15,

                fontWeight:

                bold ? FontWeight.bold : FontWeight.w500,

              ),

            ),

          ),

          Text(

            value,

            style: TextStyle(

              color: "#001234".toColor(),

              fontWeight: FontWeight.bold,

              fontSize: bold ? 18 : 16,

            ),

          ),

        ],

      ),

    );

  }

  bool _validateForm() {

    if (budgetController.text.trim().isEmpty) {

      _showMessage("Please enter your preferred budget.");

      return false;

    }

    if (locationController.text.trim().isEmpty) {

      _showMessage("Please enter preferred location.");

      return false;

    }

    if (selectedDate == null) {

      _showMessage("Please select visit date.");

      return false;

    }

    if (selectedSlot == null) {

      _showMessage("Please select a time slot.");

      return false;

    }

    if (floorController.text.trim().isEmpty) {
      _showMessage("Please enter preferred floor.");
      return false;
    }

    if (selectedBuyRent == null) {
      _showMessage("Please select Buy or Rent.");
      return false;
    }

    if (selectedLift == null) {
      _showMessage("Please select lift Required.");
      return false;
    }

    if (selectedParking == null) {
      _showMessage("Please select parking Required.");
      return false;
    }

    if (selectedFamilyStructure == null) {
      _showMessage("Please select family structure.");
      return false;
    }

    if (familyMemberController.text.trim().isEmpty) {
      _showMessage("Please enter number of family members.");
      return false;
    }

    if (selectedReligion == null) {
      _showMessage("Please select religion.");
      return false;
    }

    if (selectedShiftingDate == null) {
      _showMessage("Please select preferred shifting date.");
      return false;
    }

    return true;

  }

  void _showMessage(String msg) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(msg),

        behavior: SnackBarBehavior.floating,

      ),

    );

  }

  Widget _bookingBottomBar() {

    if (calculation == null) {
      return const SizedBox();
    }

    return SafeArea(

      child: Container(

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(

          color: Colors.white,

          boxShadow: [

            BoxShadow(

              color: Colors.black.withOpacity(.08),

              blurRadius: 12,

            )

          ],

        ),

        child: Row(

          children: [

            Expanded(

              child: Column(

                crossAxisAlignment:

                CrossAxisAlignment.start,

                mainAxisSize: MainAxisSize.min,

                children: [

                  const Text(

                    "Total",

                    style: TextStyle(

                      color: Colors.grey,

                    ),

                  ),

                  Text(

                    "₹ ${calculation!.total}",

                    style: TextStyle(

                      color: "#001234".toColor(),

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

                    backgroundColor:

                    "#001234".toColor(),

                    shape:

                    RoundedRectangleBorder(

                      borderRadius:

                      BorderRadius.circular(30),

                    ),

                  ),

                  onPressed: () {

                    if (!_validateForm()) {

                      return;

                    }

                    if (paymentLoading) return;

                    _openCheckout();

                  },

                  child: paymentLoading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Proceed to Payment",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                ),

              ),

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
      items: options
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: "#EEF5FF".toColor(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

}
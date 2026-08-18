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

class _PropertyVisitBookingPageState
    extends State<PropertyVisitBookingPage> {

  bool isLoading = true;
  bool _showAdditionalCharges = false;
  bool _termsAccepted = false;

  BookingCalculationModel? calculation;

  final budgetController = TextEditingController();

  final locationController = TextEditingController();

  final requirementController = TextEditingController();

  late Razorpay _razorpay;

  bool paymentLoading = false;

  final familyMemberController = TextEditingController();

  // BHK is pre-filled from the previous screen but can be changed here,
  // which triggers a recalculation of the visit fee.
  late String selectedBhk;
  final List<String> bhkOptions = [
    "1 RK",
    "1 BHK",
    "2 BHK",
    "3 BHK",
    "Commercial"
  ];

  List<String> selectedFloors = [];   // ← changed from String? selectedFloor
  final List<String> floorOptions = [
    "Ground Floor",
    "1st Floor",
    "2nd Floor",
    "3rd Floor",
    "4th Floor",
    "5th Floor",
  ];

  final List<String> requirementLevelOptions = [
    "Mandatory",
    "Yes",
    "Optionally",
    "No",
  ];

  final List<String> fieldWorkerOptions = const [
    'Saurabh yadav',
    'Faizan Khan',
    'Ravi Kumar',
    'Yash',
  ];

  String? selectedFurnishing;        // "Furnished" / "Semi-Furnished" / "Unfurnished"
  String? selectedLift;              // "Mandatory" / "Yes" / "Optionally" / "No"
  String? selectedParking;           // "Mandatory" / "Yes" / "Optionally" / "No"
  String? selectedBalcony;           // "Mandatory" / "Yes" / "Optionally" / "No"
  String? selectedBuyRent;           // "Buy" / "Rent"
  String? selectedFamilyStructure;   // "Nuclear" / "Joint"
  String? selectedVehicleType;       // "Two Wheeler" / "Four Wheeler"
  String? selectedFieldWorker;       // NEW — selected field worker name
  DateTime? selectedShiftingDate;

  @override
  void initState() {
    super.initState();

    locationController.text = widget.location;

    selectedBhk = widget.bhk;
    if (!bhkOptions.contains(selectedBhk)) {
      bhkOptions.insert(0, selectedBhk);
    }

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
      "BHK: $selectedBhk",
      "Property Type: ${widget.propertyType}",
      "Location: ${locationController.text}",
      "Floor: ${selectedFloors.join(', ')}",
      "Furnishing: ${selectedFurnishing ?? ''}",
      "Buy/Rent: ${selectedBuyRent ?? ''}",
      // "Lift Required: ${selectedLift ?? ''}",
      // "Parking Required: ${selectedParking ?? ''}",
      // "Balcony Required: ${selectedBalcony ?? ''}",
      // if (requirementController.text.trim().isNotEmpty)
      //   "Notes: ${requirementController.text.trim()}",
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

        "bhk": selectedBhk,

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

  void _onBhkChanged(String? value) {
    if (value == null || value == selectedBhk) return;

    setState(() {
      selectedBhk = value;
    });

    // Different BHK configurations carry a different visit fee, so
    // recalculate the amount whenever the BHK selection changes.
    loadCalculation();
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

          "visit_fee": calculation!.visitFee.toString(),

          "gst": calculation!.gst.toString(),

          "gateway_fee": calculation!.gatewayFee.toString(),

          "total": calculation!.total.toString(),

          "budget": budgetController.text,

          "preferred_location": locationController.text,

          "requirements": _buildRequirementString(),
          "family_structure": selectedFamilyStructure ?? "",
          "family_member": familyMemberController.text,
          "feild_workar_name": selectedFieldWorker,
          "shifting_date": selectedShiftingDate != null
              ? DateFormat("yyyy-MM-dd").format(selectedShiftingDate!)
              : "",
          "furnishing": selectedFurnishing ?? "",
          "vehicle_type": selectedVehicleType ?? "",
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

      print(json);

      if (json["status"] == true) {

        _showSuccessDialog(

          bookingId: json["booking_id"].toString(),

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

                    // _dialogInfoRow(
                    //   Icons.confirmation_number_outlined,
                    //   "Booking ID",
                    //   bookingId,
                    // ),
                    //
                    // const SizedBox(height: 10),

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

            _bhkSelectorSection(),

            const SizedBox(height: 20),

            _propertyCard(),

            const SizedBox(height: 22),

            _budgetSection(),

// const SizedBox(height: 20),
//
// _locationSection(),

            const SizedBox(height: 20),

// _requirementSection(),
//
// const SizedBox(height: 20),

            _additionalDetailsSection(),

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

            "Our property advisor will arrange multiple $selectedBhk properties according to your budget and preferences.",

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

  Widget _bhkSelectorSection() {

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

                Icons.meeting_room_outlined,

                color: "#001234".toColor(),

              ),

              const SizedBox(width: 10),

              const Text(

                "Configuration (BHK)",

                style: TextStyle(

                  fontSize: 17,

                  fontWeight: FontWeight.w600,

                ),

              ),

            ],

          ),

          const SizedBox(height: 15),

          _dropdownField(
            label: "Select BHK",
            value: selectedBhk,
            options: bhkOptions,
            onChanged: _onBhkChanged,
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

            selectedBhk,

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
            "Any Other Notes",
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

          // Floor — multi-select, max 5 options available
          const Text(
            "Preferred Floor(s)",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
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
                  side: BorderSide(
                    color: isSelected
                        ? "#001234".toColor()
                        : Colors.transparent,
                  ),
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

          // _dropdownField(
          //   label: "Lift Required",
          //   value: selectedLift,
          //   options: requirementLevelOptions,
          //   onChanged: (v) => setState(() => selectedLift = v),
          // ),
          // const SizedBox(height: 12),

          _dropdownField(
            label: "Parking Required",
            value: selectedParking,
            options: requirementLevelOptions,
            onChanged: (v) => setState(() => selectedParking = v),
          ),
          const SizedBox(height: 12),

          // _dropdownField(
          //   label: "Balcony Required",
          //   value: selectedBalcony,
          //   options: requirementLevelOptions,
          //   onChanged: (v) => setState(() => selectedBalcony = v),
          // ),
          // const SizedBox(height: 12),

          _dropdownField(
            label: "Family Structure",
            value: selectedFamilyStructure,
            options: const ["Nuclear", "Joint", "LiveIn", "Single", "Extended Family", "Other"],
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

          // _dropdownField(
          //   label: "Vehicle Type (if any)",
          //   value: selectedVehicleType,
          //   options: const ["Two Wheeler", "Four Wheeler"],
          //   onChanged: (v) => setState(() => selectedVehicleType = v),
          // ),
          // const SizedBox(height: 12),

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

  Widget _termsAndConditionsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _termsAccepted
              ? Colors.green.withOpacity(.35)
              : Colors.grey.withOpacity(.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: "#EEF5FF".toColor(),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 20,
                  color: "#001234".toColor(),
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  "Terms & Conditions",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          InkWell(
            onTap: () {
              setState(() {
                _termsAccepted = !_termsAccepted;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Checkbox(
                  value: _termsAccepted,
                  activeColor: "#001234".toColor(),
                  onChanged: (value) {
                    setState(() {
                      _termsAccepted = value ?? false;
                    });
                  },
                ),

                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 11,
                      right: 4,
                    ),
                    child: Text(
                      "I agree to the Terms & Conditions",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 4,
            ),
            child: Text(
              "By proceeding with payment, you acknowledge that you have read and agreed to these terms.",
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          const SizedBox(height: 10),

          TextButton.icon(
            onPressed: _showTermsAndConditions,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
            icon: Icon(
              Icons.description_outlined,
              size: 17,
              color: "#001234".toColor(),
            ),
            label: Text(
              "Read Terms & Conditions",
              style: TextStyle(
                color: "#001234".toColor(),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [

                  const SizedBox(height: 12),

                  // Handle
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
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
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Terms & Conditions",
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Property Visit Booking",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 20),

                  // Full Terms
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [

                          const Text(
                            "TERMS AND CONDITIONS OF SERVICE",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 14),

                          _termsParagraph(
                            'By checking the agreement box and proceeding with payment, you ("User" or "Client") explicitly acknowledge that you have read, understood, and agreed to be legally bound by these Terms and Conditions.',
                          ),

                          _termsSection(
                            "1. Scope of Service (One-Time Budget Segment Visit)",
                            [
                              "The fee paid on this portal covers a single, one-time property viewing service (\"Visit\").",
                              "The Company’s service obligation is strictly limited to planning, coordinating, and conducting one visit session to present available flats that match your specified budget segment.",
                              "Once matching flats within your specified budget segment have been shown to you, the Company’s service obligations for this transaction are fully executed and complete.",
                            ],
                          ),

                          _termsSection(
                            "2. Strict Non-Refundable Payment Policy",
                            [
                              "The visit fee paid on this portal is 100% non-refundable, non-transferable, and non-adjustable under any circumstances.",
                              "Once payment is processed, no full, partial, or pro-rata refund shall be granted under any condition, including if you choose not to proceed with the visit, reject the properties shown, or decide not to purchase or rent any flat.",
                              "This payment represents immediate compensation for platform operations, administrative coordination, agent allocation, and logistical expenses incurred prior to and during the service.",
                            ],
                          ),

                          _termsSection(
                            "3. Anti-Bypass, Anti-Circumvention & Strict Legal Action",
                            [
                              "Protected Properties: Any flat, residential unit, or property showcased, introduced, or identified to you during the visit is deemed a protected business introduction made through our platform.",
                              "Prohibition of Direct Dealing: You agree that you shall not, directly or indirectly (either personally, or through family members, relatives, legal heirs, corporate entities, partners, or third-party representatives), buy, rent, lease, or enter into any deal with the property owner without involving the Company.",
                              "Commercial Fraud: Any attempt to bypass the Company and contract directly with the property owner or listing representative for a property shown by us constitutes commercial fraud and a material breach of contract.",
                              "Legal Proceedings & Liquidated Damages: If you violate this clause and buy or rent a flat shown by us without our involvement, the Company reserves the right to initiate strict legal action against you in court. Upon such breach, you shall be legally liable to pay liquidated damages equal to our standard platform commission/brokerage fee (2% of total property purchase price or two months' gross rental value, whichever applies) along with all legal costs and court expenses incurred in recovery.",
                            ],
                          ),

                          _termsSection(
                            "4. Absolute Limitation of Liability & Disclaimers",
                            [
                              "Limitation of Scope: Apart from planning, coordinating, and showing you flats in your budget segment, the Company holds no responsibility or liability whatsoever regarding the properties.",
                              "No Ownership or Structural Guarantees: The Company is not responsible for the physical condition, structural integrity, title clarity, legal encumbrances, utility connections, or ownership disputes of any flat shown.",
                              "User Due Diligence: You are solely responsible for conducting independent legal title verification, document checks, and physical inspections prior to entering into any purchase or lease contract with a property owner.",
                              "Owner Disputes: The Company shall not be held liable for any misrepresentations, defaults, or contractual disputes arising between you and the property owner.",
                            ],
                          ),

                          _termsSection(
                            "5. Payment Gateway & Chargeback Restrictions",
                            [
                              "All online transactions are processed through secure third-party payment gateways. The Company does not store full credit/debit card credentials or banking PINs.",
                              "The Company shall not be held liable for payment failures, bank downtime, unauthorized deductions, or technical delays caused by third-party payment processors or issuing banks.",
                              "You agree not to file fraudulent chargeback claims or \"unauthorized payment\" disputes with your bank or card issuer after paying for the service. Any fraudulent chargeback initiated to evade this non-refundable policy will be legally contested using system logs, IP addresses, and digital acceptance records.",
                            ],
                          ),

                          _termsSection(
                            "6. User Information Accuracy & Contact Obligations",
                            [
                              "You warrant that all information provided during checkout (full name, phone number, email address, budget preference) is complete and accurate.",
                              "If the Company or field representative is unable to contact you via phone or WhatsApp due to incorrect contact details provided by you, the visit service will be deemed forfeited without a refund.",
                            ],
                          ),

                          _termsSection(
                            "7. Site Conduct & Indemnification",
                            [
                              "You agree to maintain proper decorum, follow safety protocols, and respect private premises during site viewings.",
                              "You agree to defend, indemnify, and hold harmless the Company, its directors, employees, and field agents from any claims, losses, or property damages resulting from your personal conduct or negligence during a visit.",
                            ],
                          ),

                          _termsSection(
                            "8. Force Majeure",
                            [
                              "The Company shall not be held liable or considered in breach of contract for any failure or delay in conducting a visit resulting from events beyond reasonable control, including extreme weather, public transport disruptions, government restrictions, or sudden unavailability of the property owner.",
                            ],
                          ),

                          _termsSection(
                            "9. Electronic Agreement & Governing Law",
                            [
                              "Electronic Contract Validity: By completing the payment, you acknowledge that checking the agreement box constitutes a legally valid and binding electronic contract under Section 10A of the Information Technology Act, 2000.",
                              "Severability: If any provision of these Terms is held to be invalid or unenforceable by a court, the remaining provisions shall remain in full force and effect.",
                              "Governing Law & Jurisdiction: This agreement is governed by the laws of India, and any legal disputes shall be subject to the exclusive jurisdiction of the local courts where the Company operates.",
                            ],
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),

                  // Bottom action
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        10,
                        20,
                        16,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            "#001234".toColor(),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            "I Understand",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
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
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _termsSection(
      String title,
      List<String> paragraphs,
      ) {
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
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: Colors.black87,
                ),
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
            offset: const Offset(0, 5),
          ),
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

          const SizedBox(height: 8),

          // Additional Charges Header
          InkWell(
            onTap: () {
              setState(() {
                _showAdditionalCharges = !_showAdditionalCharges;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                const Text(
                  "Additional Charges",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const Spacer(),

                Icon(
                  _showAdditionalCharges
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 22,
                  color: Colors.black54,
                ),
              ],
            ),
          ),

          // GST + Gateway Charges
          if (_showAdditionalCharges) ...[
            const SizedBox(height: 10),

            _priceTile(
              "GST",
              "₹ ${calculation!.gst}",
            ),

            _priceTile(
              "Gateway Charges",
              "₹ ${calculation!.gatewayFee}",
            ),
          ],

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

    // if (locationController.text.trim().isEmpty) {
    //   _showMessage("Please enter preferred location.");
    //   return false;
    // }

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

    // if (selectedLift == null) {
    //   _showMessage("Please select lift Required.");
    //   return false;
    // }

    if (selectedParking == null) {
      _showMessage("Please select parking Required.");
      return false;
    }

    // if (selectedBalcony == null) {
    //   _showMessage("Please select balcony Required.");
    //   return false;
    // }

    if (selectedFamilyStructure == null) {
      _showMessage("Please select family structure.");
      return false;
    }

    if (familyMemberController.text.trim().isEmpty) {
      _showMessage("Please enter number of family members.");
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

        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Terms & Conditions
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _termsAccepted,
                  activeColor: "#001234".toColor(),
                  materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) {
                    setState(() {
                      _termsAccepted = value ?? false;
                    });
                  },
                ),
              ),

              const SizedBox(width: 8),

              const Text(
                "I agree to the",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),

              TextButton(
                onPressed: _showTermsAndConditions,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
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

          // Checkout Row
          Row(
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Visit Fee",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),

                    Text(
                      "₹ ${calculation!.visitFee}",
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
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      if (!_validateForm()) {
                        return;
                      }

                      if (!_termsAccepted) {
                        _showMessage(
                          "Please accept the Terms & Conditions to continue.",
                        );
                        return;
                      }

                      if (paymentLoading) return;

                      _openCheckout();
                    },
                    child: paymentLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                      CircularProgressIndicator(
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
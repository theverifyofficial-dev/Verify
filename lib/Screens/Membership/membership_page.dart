import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../custom_widget/back_button.dart';
import '../../../utilities/hex_color.dart';
import '../../../utilities/membership_helper.dart';

class MembershipPurchasePage extends StatefulWidget {
  const MembershipPurchasePage({super.key});

  @override
  State<MembershipPurchasePage> createState() =>
      _MembershipPurchasePageState();
}

class _MembershipPurchasePageState extends State<MembershipPurchasePage> {
  // ── Pricing ──────────────────────────────────────────────
  // NOTE: confirm these percentages with backend — assumed:
  // GST = 18% of base, transaction fee = 2% of (base + GST).
  static const double basePrice = 499;
  static const double gstRate = 0.18;
  static const double transactionFeeRate = 0.02;

  // NOTE: Razorpay key_id is safe to embed client-side (it's the
  // publishable key, not the secret). Replace with your actual
  // live/test key_id — since create_order.php is no longer called,
  // there's no backend response to pull this from anymore.
  String? _razorpayKeyId;
  bool _keyLoading = true;
  double get gstAmount => basePrice * gstRate;
  double get subtotal => basePrice + gstAmount;
  double get transactionFee => subtotal * transactionFeeRate;
  double get totalPayable => subtotal + transactionFee;

  // ── Family data (collected here, not at visit-booking time) ─
  String? selectedFamilyStructure;
  final familyMemberController = TextEditingController();

  final List<String> familyStructureOptions = const [
    "Nuclear",
    "Joint",
    "LiveIn",
    "Single",
    "Extended Family",
    "Other",
  ];

  late Razorpay _razorpay;
  bool paymentLoading = false;

  String? _userMobile;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadUserContact();
    _fetchRazorpayKey();
  }

  Future<void> _loadUserContact() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userMobile = prefs.getString('number');
      _userEmail = prefs.getString('email');
    });
  }

  Future<void> _fetchRazorpayKey() async {
    setState(() => _keyLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          "https://verifyrealestateandservices.in/Second%20PHP%20FILE/book_shedual/verify_key_id.php",
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"] == true && json["key_id"] != null) {
          setState(() {
            _razorpayKeyId = json["key_id"];
            _keyLoading = false;
          });
          return;
        }
      }

      setState(() => _keyLoading = false);
      _showMessage("Unable to initialize payment. Please try again.");
    } catch (e) {
      setState(() => _keyLoading = false);
      _showMessage("Unable to initialize payment. Please try again.");
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    familyMemberController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (selectedFamilyStructure == null) {
      _showMessage("Please select family structure.");
      return false;
    }
    if (familyMemberController.text.trim().isEmpty) {
      _showMessage("Please enter number of family members.");
      return false;
    }
    return true;
  }

  // ── Checkout ─────────────────────────────────────────────
  // create_membership_order.php removed — Razorpay checkout now
  // opens directly with a client-computed amount, no backend order
  // step. Verification (and membership activation) happens entirely
  // in _verifyPayment() after payment success.
  void _openCheckout() {
    if (!_validateForm()) return;

    if (_razorpayKeyId == null) {
      _showMessage("Payment not ready yet. Please try again in a moment.");
      _fetchRazorpayKey(); // retry fetching
      return;
    }

    final amountInPaise = (totalPayable * 100).round();

    var options = {
      "key": _razorpayKeyId,
      "amount": amountInPaise,
      "currency": "INR",
      "name": "Verify Real Estate",
      "description": "Yearly Membership",
      "prefill": {
        "contact": _userMobile ?? '',
        "email": _userEmail ?? '',
      },
      "theme": {"color": "#001234"},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _verifyPayment({required String paymentId}) async {
    setState(() => paymentLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("id") ?? 0;

      // Membership is valid for 1 year from today.
      final expiryDate = DateTime.now().add(const Duration(days: 365));
      final expiryDateStr = DateFormat("yyyy-MM-dd").format(expiryDate);

      final response = await http.post(
        Uri.parse(
          "https://verifyrealestateandservices.in/Second%20PHP%20FILE/book_shedual/update_membership.php",
        ),
        body: {
          "id": userId.toString(),
          "membership_status": MembershipHelper.statusActive,
          "membership_expiry_date": expiryDateStr,
          "family_structure": selectedFamilyStructure ?? "",
          "family_member": familyMemberController.text,
        },
      );

      setState(() => paymentLoading = false);

      if (response.statusCode != 200) {
        _showMessage("Server Error");
        return;
      }

      final json = jsonDecode(response.body);

      if (json["status"] == true) {
        await MembershipHelper.save(
          status: json["membership_status"] ?? MembershipHelper.statusActive,
          expiryDate: json["membership_expiry_date"] ?? expiryDateStr,
        );
        _showSuccessDialog();
      } else {
        _showMessage(json["message"] ?? "Verification failed.");
      }
    } catch (e) {
      setState(() => paymentLoading = false);
      _showMessage(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (response.paymentId == null) {
      _showMessage("Invalid Payment Response");
      return;
    }
    _verifyPayment(paymentId: response.paymentId!);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showMessage(response.message ?? "Payment Failed");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showMessage("External Wallet : ${response.walletName}");
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessDialog() {
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
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(.10),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 50,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Membership Activated",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: "#001234".toColor(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "You can now book property visits for free for the next year.",
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, fontSize: 14.5),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: "#001234".toColor(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context, true); // close page, signal success
                  },
                  child: const Text(
                    "Continue",
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
          "Yearly Membership",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(),
            const SizedBox(height: 20),
            _benefitsCard(),
            const SizedBox(height: 20),
            _familyDetailsCard(),
            const SizedBox(height: 20),
            _priceCard(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: ["#001234".toColor(), "#173B74".toColor()],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Unlock Free Property Visits",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Get a full year of membership and book property visits at no extra cost.",
            style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _benefitsCard() {
    final benefits = [
      "Unlimited free property visit bookings for 1 year",
      "No visit fee on every booking after this",
      "Priority scheduling with our field advisors",
    ];

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
              Icon(Icons.workspace_premium_outlined, color: "#001234".toColor()),
              const SizedBox(width: 10),
              const Text(
                "Membership Benefits",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...benefits.map(
                (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(b, style: const TextStyle(height: 1.4, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _familyDetailsCard() {
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
            "Family Details",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: selectedFamilyStructure,
            items: familyStructureOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => selectedFamilyStructure = v),
            decoration: InputDecoration(
              labelText: "Family Structure",
              filled: true,
              fillColor: "#EEF5FF".toColor(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
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
        ],
      ),
    );
  }

  Widget _priceCard() {
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
            "Price Breakdown",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _priceTile("Membership Fee", "₹ ${basePrice.toStringAsFixed(0)}"),
          _priceTile("GST (18%)", "₹ ${gstAmount.toStringAsFixed(2)}"),
          _priceTile(
            "Transaction Fee (2%)",
            "₹ ${transactionFee.toStringAsFixed(2)}",
          ),
          const Divider(height: 28),
          _priceTile(
            "Total Payable",
            "₹ ${totalPayable.toStringAsFixed(2)}",
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _priceTile(String title, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: bold ? 17 : 15,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
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

  Widget _bottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Total", style: TextStyle(color: Colors.grey)),
                  Text(
                    "₹ ${totalPayable.toStringAsFixed(2)}",
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
                    backgroundColor: "#001234".toColor(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: (paymentLoading || _keyLoading) ? null : _openCheckout,
                  child: (paymentLoading || _keyLoading)
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Buy Membership",
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
}
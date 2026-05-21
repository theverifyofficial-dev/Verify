import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Verify/utilities/hex_color.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../custom_widget/Paths.dart';
import '../../custom_widget/back_button.dart';

class ServiceBookingPage extends StatefulWidget {
  final String serviceID;
  final String serviceName;

  const ServiceBookingPage({
    super.key,
    required this.serviceName,
    required this.serviceID,
  });


  @override
  State<ServiceBookingPage> createState() => _ServiceBookingPageState();
}

class _ServiceBookingPageState extends State<ServiceBookingPage> {
  String? selectedDate;
  String? selectedTime;
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isLoading = false;
  final String googleApiKey = "AIzaSyBukKQrrZmGS1KOh2Kyc_G_nHhIzse6gPE";
  List<String> placeSuggestions = [];
  Timer? _debounce;
  double? latitude;
  double? longitude;
  String full_address = '';
  final TextEditingController _Longitude = TextEditingController();
  final TextEditingController _Latitude = TextEditingController();

  List<File> issueImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> timeSlots = [
    '09:00 AM - 12:00 PM',
    '12:00 PM - 03:00 PM',
    '03:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM',
  ];

  final int visitingCharge = 100;

  Future<File> compressImage(File file) async {
    final dir = await Directory.systemTemp.createTemp();
    final targetPath =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60,
      minWidth: 800,
      minHeight: 800,
    );

    return result != null ? File(result.path) : file;
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.length > 5) {
      showSnack("Max 5 images allowed", error: true);
      return;
    }

    if (pickedFiles.isNotEmpty) {
      List<File> temp = [];

      for (var img in pickedFiles) {
        File file = File(img.path);

        /// 🔥 COMPRESS HERE
        File compressed = await compressImage(file);

        temp.add(compressed);
      }

      setState(() {
        issueImages = temp;
      });
    }
  }

  void showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green.shade700,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      _Latitude.text = latitude.toString();
      _Longitude.text = longitude.toString();
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showSnack("Location services are disabled.", error: true);
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showSnack("Location permission denied", error: true);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showSnack("Location permanently denied", error: true);
      return false;
    }

    return true;
  }

  void fetchPlaceSuggestions(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (input.isEmpty) {
        setState(() => placeSuggestions = []);
        return;
      }

      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=geocode&language=en&components=country:in&key=$googleApiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {

        final data = json.decode(response.body);
        final predictions = data['predictions'] as List;
        setState(() {
          placeSuggestions = predictions.map((p) => p['description'] as String).toList();
        });
      } else {
        setState(() => placeSuggestions = []);
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  color: "#001234".toColor(), size: 60),

              const SizedBox(height: 16),

              const Text(
                "Service Booked!",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                    color: Colors.black54
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Our agent will contact you soon.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: "#001234".toColor(),
                ),
                child: const Text("OK"),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    locationController.dispose();
    super.dispose();
  }

  Future<void> bookService() async {

    if (isLoading) return;

    if (selectedDate == null) {
      showSnack("Select date", error: true);
      return;
    }

    if (selectedTime == null) {
      showSnack("Select time slot", error: true);
      return;
    }

    if (locationController.text.trim().length < 5) {
      showSnack("Enter valid address", error: true);
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userID = prefs.getInt('id')?.toString() ?? '';
    final userName = prefs.getString('name') ?? '';
    final userNumber = prefs.getString('number') ?? '';
    final email = prefs.getString('email') ?? '';

    final Uri url = Uri.parse('https://verifyrealestateandservices.in/Second%20PHP%20FILE/service_api/service_api.php');
    final request = http.MultipartRequest('POST', url);

    request.fields.addAll({
      'user_ids': userID,
      'user_names': userName,
      'email': email,
      'user_number': userNumber,
      'services_id': widget.serviceID,
      'service_names': widget.serviceName,
      'suitable_day': selectedDate!,
      'suitable_time': selectedTime!,
      'address_for_services': locationController.text.trim(),
      'description': descriptionController.text.trim(),


    }

    );
    for (int i = 0; i < issueImages.length; i++) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'issue_images[]', // 👈 backend must match this
          issueImages[i].path,
        ),
      );
    }
    setState(() => isLoading = true);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 && response.body.contains("success")) {
        _showSuccessDialog();
      } else {
        showSnack("❌ Booking failed", error: true,);
      }
    } catch (e) {
      showSnack("⚠️ Error: $e", error: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title:
        Image.asset(AppImages.logo2, height: 70),
        centerTitle: true,
        backgroundColor: "#001234".toColor(),
        surfaceTintColor: "#001234".toColor(),
        leading: CustomBackButton(),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Padding(
                  padding: const EdgeInsets.all(0),
                  child: Row(
                    children: [
                      Text(
                        "Book ${widget.serviceName}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.info_outline, color: "#001234".toColor(),),
                        onPressed: _showFormGuide,
                      )
                    ],
                  ),
                ),


                const SizedBox(height: 24),

                // Date Picker
                buildDatePicker(Colors.black, Colors.white),

                const SizedBox(height: 16),

                // Time Picker
                buildTimeDropdown(Colors.black, Colors.white),

                const SizedBox(height: 16),

                buildLocationField(Colors.black),

                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(width: 1, color: Colors.grey.shade600),
                  ),
                  child: Text.rich(
                      TextSpan(
                          text: 'Note :',
                          style: TextStyle(fontSize: 14,fontWeight: FontWeight.w600,color: Colors.black,fontFamily: 'Poppins',letterSpacing: 0),
                          children: <InlineSpan>[
                            TextSpan(
                              text: ' Enter Address manually or get your current Address from one tap on location icon.',
                              style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Colors.grey.shade900,fontFamily: 'Poppins',letterSpacing: 0),
                            )
                          ]
                      )),
                ),

                SizedBox(height: 20),
                InkWell(

                  onTap: () async {
                    setState(() => isLoading = true); // 👈 show loader

                    await _getCurrentLocation();

                    if (latitude != null && longitude != null) {
                      try {
                        List<Placemark> placemarks =
                        await placemarkFromCoordinates(latitude!, longitude!);

                        if (placemarks.isNotEmpty) {
                          Placemark place = placemarks.first;

                          String output =
                              "${place.street}, ${place.locality}, ${place.subLocality}, "
                              "${place.administrativeArea}, ${place.country}, ${place.postalCode}";

                          setState(() {
                            full_address = output;
                            locationController.text = full_address;
                          });
                        }
                      } catch (e) {
                        showSnack("Error fetching address", error: true);
                      }
                    } else {
                      showSnack("⚠️ Location not available", error: true);
                    }

                    setState(() => isLoading = false); // 👈 stop loader
                  },

                  child: Container(

                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(topRight: Radius.circular(0),topLeft: Radius.circular(0),bottomRight: Radius.circular(10),bottomLeft: Radius.circular(10)),
                        border: Border.all(width: 1, color: Colors.blue),
                        color: Colors.blue.shade600
                    ),
                    child: Center(child: Text('Get Current Location',style: TextStyle(fontSize: 13,fontWeight: FontWeight.w400,color: Colors.white,fontFamily: 'Poppins',letterSpacing: 1),)),
                  ),
                ),
                const SizedBox(height: 24),


                _imageUploadSection(),

                const SizedBox(height: 16),

                _descriptionField(),

                SizedBox(height: 20),

                buildPriceSummary(Colors.white, Colors.black),

                const SizedBox(height: 40),

                Center(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : bookService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: isLoading
                    ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                        : Text(
                      "Book Now",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildDatePicker(Color textColor, Color cardColor) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: selectedDate ?? ""),

      style: TextStyle(color: textColor),
      decoration: buildInputDecoration("Select Date", textColor),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.blue.shade900,
                  onPrimary: Colors.white,
                  surface: cardColor,
                  onSurface: textColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            selectedDate = DateFormat('yyyy-MM-dd').format(picked);
          });
        }
      },
    );
  }

  Widget buildTimeDropdown(Color textColor, Color cardColor) {
    return DropdownButtonFormField<String>(
      decoration: buildInputDecoration("Select Time Slot", textColor),
      dropdownColor: cardColor,
      iconEnabledColor: textColor,
      style: TextStyle(color: textColor, fontFamily: 'Poppins'),
      value: selectedTime,
      items: timeSlots.map((slot) {
        return DropdownMenuItem(
          value: slot,
          child: Text(slot),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedTime = value),
    );
  }

  Widget _imageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        Row(
          children: [
            Icon(Icons.image_outlined, color: "#001234".toColor()),
            const SizedBox(width: 8),
            Text(
              "Upload Issue Images (Optional)",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: "#001234".toColor(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        GestureDetector(
          onTap: isLoading ? null : _pickImages,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: "#EEF5FF".toColor(),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: "#001234".toColor().withOpacity(0.2),
              ),
            ),
            child: issueImages.isEmpty
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo,
                    color: "#001234".toColor()),
                const SizedBox(height: 6),
                Text(
                  "Tap to add images",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),

              ],
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: issueImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [

                    Container(
                      margin: const EdgeInsets.all(6),
                      width: 80,
                      height: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          issueImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    /// ❌ remove button
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            issueImages.removeAt(index);
                          });
                        },
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    )

                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _descriptionField() {
    return TextFormField(
      controller: descriptionController,
      maxLines: 3,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: Colors.black,
      ),
      decoration: InputDecoration(
        labelText: "Describe your issue (Optional)",
        hintText: "e.g. AC not cooling, water leakage...",

        /// TEXT COLORS
        labelStyle: TextStyle(
          color: "#001234".toColor(),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade600,
        ),

        /// ICON
        prefixIcon: Icon(
          Icons.notes,
          color: "#001234".toColor(),
        ),

        /// BACKGROUND
        filled: true,
        fillColor: "#EEF5FF".toColor(),

        /// BORDERS (IMPORTANT 🔥)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: "#001234".toColor().withOpacity(0.25),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: "#001234".toColor(),
            width: 1.5,
          ),
        ),

        /// ERROR (future safe)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget buildLocationField(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: locationController,
          onChanged: fetchPlaceSuggestions,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: "Enter Location",
            /// TEXT
            labelStyle: const TextStyle(color: Colors.black54),
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.6)),

            /// 👇 FORCE BLACK BORDER IN ALL STATES
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black54),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black54, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black54),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),

            /// OPTIONAL (removes white feel)
            filled: true,
            fillColor: Colors.transparent,

            prefixIcon: const Icon(Icons.location_on, color: Colors.black),
          ),
        ),
        ...placeSuggestions.map((suggestion) => ListTile(
          title: Text(suggestion, style: TextStyle(color: textColor)),
          onTap: () {
            locationController.text = suggestion;
            setState(() => placeSuggestions = []);
          },
        )),
        if (placeSuggestions.isEmpty && locationController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "No suggestions found.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }

  void _showFormGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _formGuideSheet(),
    );
  }

  Widget _formGuideSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.55,
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
                "How to Fill This Form",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: "#001234".toColor(),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Follow these steps to book your service correctly.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 20),

              /// STEPS
              _formStep(
                Icons.calendar_month,
                "Select Date",
                "Choose your preferred visiting day.",
              ),

              _formStep(
                Icons.access_time,
                "Select Time Slot",
                "Pick a suitable time for service.",
              ),

              _formStep(
                Icons.location_on,
                "Enter Location",
                "Type your address or use 'Get Current Location'.",
              ),

              _formStep(
                Icons.image_outlined,
                "Upload Images (Optional)",
                "Add photos of the issue for faster understanding.",
              ),

              _formStep(
                Icons.notes,
                "Write Description (Optional)",
                "Explain your problem briefly for better service.",
              ),

              _formStep(
                Icons.check_circle,
                "Book Service",
                "Tap 'Book Now' to confirm your request.",
              ),

              const SizedBox(height: 20),

              /// SMART TIP 🔥
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: "#EEF5FF".toColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: "#001234".toColor()),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Adding images & description helps us assign the right expert faster.",
                        style: const TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: "#001234".toColor(),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Got it",style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _formStep(IconData icon, String title, String desc) {
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

  Widget buildPriceSummary(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: "#EEF5FF".toColor(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          summaryRow("Visiting Charges", "₹$visitingCharge", textColor),
          summaryRow("Service Charges", "According to Work", textColor),
          const Divider(color: Colors.black,),
          summaryRow("Total", "₹$visitingCharge +", textColor, bold: true),
        ],
      ),
    );
  }

  InputDecoration buildInputDecoration(String label, Color textColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textColor),
      hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textColor),
      ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54),
        ),
    );
  }

  Widget summaryRow(String label, String amount, Color textColor, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

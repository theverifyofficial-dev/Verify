import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Verify/utilities/theme-helper.dart';
import 'package:Verify/utilities/hex_color.dart';
import '../../../custom_widget/Paths.dart';
import '../../../custom_widget/Preview.dart';
import '../../../custom_widget/Youtube_video.dart';
import '../../../custom_widget/back_button.dart';
import '../../../model/detailed_property_model.dart';
import '../../../model/image_model.dart';

class Full_Property extends StatefulWidget {
  const Full_Property({super.key});

  @override
  State<Full_Property> createState() => _Full_PropertyState();
}

class _Full_PropertyState extends State<Full_Property> {

  Future<List<DetailedPropertyModel>>_propertyFuture = Future.value([]);
  late Future<List<RealEstateSlider>> _sliderFuture;
  final bookingDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  bool isBooked = false;
  Map? bookingData;

  @override
  void initState() {
    super.initState();
    _loadAllData();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  Future<void> _loadAllData() async {
    final id = await getPropertyID();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("id")?.toString() ?? "0";

    setState(() {
      _propertyFuture = fetchProperty(id);
      _sliderFuture = fetchSlider(id);
    });

    if (id != null) {
      await checkIfBooked(id, userId);
    }
  }

  Future<String?> getPropertyID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id_Building')?.toString();
  }

  Future<List<DetailedPropertyModel>> fetchProperty(String? id) async {
    final response = await http.get(Uri.parse(
        "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/details_page.php?P_id=$id"));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is Map<String, dynamic> && decoded['success'] == true) {
        final data = decoded['data'];
        if (data is List) {
          return data
              .map<DetailedPropertyModel>((e) => DetailedPropertyModel.fromJson(e))
              .toList();
        } else {
          throw Exception("Unexpected 'data' format: ${data.runtimeType}");
        }
      } else {
        throw Exception("API returned failure or invalid format");
      }
    } else {
      throw Exception('Failed to load property');
    }
  }

  Future<List<RealEstateSlider>> fetchSlider(String? id) async {
    final response = await http.get(Uri.parse(
        "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_realestate_for_website/show_multiple_image_in_main_realestate.php?subid=$id"));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse['success'] == true) {
        final List data = jsonResponse['data'];
        return data.map((e) => RealEstateSlider.fromJson(e)).toList();
      } else {
        throw Exception('API returned success = false');
      }
    } else {
      throw Exception('Failed to load images');
    }
  }

  Future<void> checkIfBooked(String propertyId, String userId) async {
    final url = Uri.parse(
        "https://verifyrealestateandservices.in/Second%20PHP%20FILE/book_shedual/show_api_for_property_id_and_user_id.php?property_id=$propertyId&user_ids=$userId"
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data["status"] == true) {
        setState(() {
          isBooked = true;
          bookingData = data["data"][0]; // 🔥 IMPORTANT
        });
      } else {
        setState(() {
          isBooked = false;
        });
      }
    }
  }

  Future<void> bookSchedule({
    required String id,
    required String location,
    required String info,
    required String furnished,
    required String bhk,
    required String type,
    required String userId,
    required String userName,
    required String phoneNumber,
    required String address, // user’s address or property address
    required String fieldworkerName, // user’s address or property address
    required String fieldworkerNumber, // user’s address or property address
    required String visitingDate,
    required String visitingTime,
  })
  async {
    final url = Uri.parse(
        'https://verifyrealestateandservices.in/Second%20PHP%20FILE/book_shedual/book_shedual.php');

    final body = {
      'user_ids': userId,
      'user_names': userName,
      'property_id': id,
      'locations': location,
      'booking_date': bookingDate,
      'visiting_date': visitingDate,
      'visiting_time': visitingTime,
      'descriptions': info,
      'furnished': furnished,
      'addresss': address,
      'BHK': bhk,
      'type_of_property': type,
      'phone_number': phoneNumber,
      'fieldworkar_name': fieldworkerName,
      'fieldworkar_number': fieldworkerNumber,
    };

    final response = await http.post(url, body: body);

    if (response.statusCode == 200 && response.body.contains('success')) {

      setState(() {
        isBooked = true;
      });

      _showSuccessDialog(
        date: visitingDate,
        time: visitingTime,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking Failed: ${response.body}')),
      );
    }
  }

  void _showSuccessDialog({String? date, String? time}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // 🔥 Success Circle with subtle glow
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: "#001234".toColor().withOpacity(0.08),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: "#001234".toColor(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

               Text(
                "Visit Scheduled!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: "#001234".toColor(),
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 Subtitle
              const Text(
                "Your visit has been successfully booked.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Booking Summary Card
              if (date != null || time != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: "#EEF5FF".toColor(),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [

                      if (date != null)
                        _dialogInfoRow(Icons.calendar_today, "Date", date),

                      if (time != null) ...[
                        const SizedBox(height: 8),
                        _dialogInfoRow(Icons.access_time, "Time Slot", time),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // 🔹 Info Message
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: "#001234".toColor().withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18,
                        color: "#001234".toColor()),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Our property advisor will contact you shortly to confirm your visit.",
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // 🔹 Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: "#001234".toColor(),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
      backgroundColor: const Color(0xFFF4F7FB),
      //"#EEF5FF".toColor(),
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Image.asset(AppImages.logo2, height: 70),
        centerTitle: true,
        backgroundColor: "#001234".toColor(),
        surfaceTintColor: "#001234".toColor(),

      ),
      body: SafeArea(
        child: FutureBuilder<List<DetailedPropertyModel>>(
          future: _propertyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Row(
                children: [
                  Text("Error: ${snapshot.error}",style: TextStyle(    fontFamily: 'Poppins',color: AppColors.bgColor(context),fontSize: 13),),
                ],
              ));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No property data found"));
            }

            final data = snapshot.data!.first; // safe now

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [

                      VideoPlayerWidget(
                        videoUrl: data.videoLink,
                        fallbackImageUrl:
                        'https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_realestate/${data.propertyPhoto}',
                      ),

                      FutureBuilder<List<RealEstateSlider>>(
                        future: _sliderFuture,
                        builder: (context, sliderSnap) {
                          if (sliderSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (sliderSnap.hasError) {
                            return Center(child: Text("Error loading images"));
                          }
                          final sliders = sliderSnap.data ?? [];
                          if (sliders.isEmpty) {
                            return const SizedBox(); // completely hide if no images

                          }
                          return buildImageCarousel(sliders);
                        },
                      ),

                      const SizedBox(height: 5),
                      buildTitleLocation(data),
                      const SizedBox(height: 10),
                      buildChips(data),
                      const SizedBox(height: 20),
                      buildDetailsGrid(data),
                      const SizedBox(height: 20),
                      buildStaticInfoSection(data.floor,data.ageOfProperty,data.totalFloor,"${data.metroDistance} Metro",data.highwayDistance,data.roadSize,data.mainMarketDistance,data.id.toString()),
                      //metro dist = name and highway dis = metro dis.
                      const SizedBox(height: 20),
                      Text(
                        "Available Facilities",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Divider(color: Colors.black),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          data.facility,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Divider(color: Colors.black),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: FutureBuilder<List<DetailedPropertyModel>>(
          future: _propertyFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(); // nothing to show
            }
            final data = snapshot.data!.first;
            return Material(
              elevation: 10,
              color: "#EEF5FF".toColor(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹ ${data.showPrice}',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            color: "#001234".toColor(),
                            fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: () async {
                        if (isBooked) {
                          if (bookingData != null) {
                            showVisitDetails(bookingData!);
                          }
                          return;
                        }

                        final bookingDataSheet = await _showBookingBottomSheet();

                        if (bookingDataSheet == null) return;

                        final propertyList = await _propertyFuture;
                        if (propertyList.isEmpty) return;

                        final property = propertyList.first;

                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getInt("id") ?? 0;
                        final name = prefs.getString("name") ?? "";
                        final number = prefs.getString("number") ?? "";

                        await bookSchedule(
                          userId: userId.toString(),
                          userName: name,
                          phoneNumber: number,
                          address: property.apartmentAddress,
                          id: property.id.toString(),
                          location: property.location,
                          info: property.facility,
                          furnished: property.furnished,
                          bhk: property.bhk,
                          type: property.typeOfProperty,
                          fieldworkerName: property.fieldworkerName,
                          fieldworkerNumber: property.fieldworkerNumber,
                          visitingDate: bookingDataSheet["date"]!,
                          visitingTime: bookingDataSheet["time"]!,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBooked
                          ? "#E3EFFF".toColor()
                            : "#001234".toColor(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: Text(
                        isBooked ? "View Details" : "Book Schedule",
                        style: TextStyle(
                          color: isBooked ?  "#001234".toColor() :   Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );

          }),
    );
  }

  Future<Map<String, String>?> _showBookingBottomSheet() async {
    DateTime? selectedDate;
    String? selectedSlot;
    List<String> timeSlots = [
      "09:00 AM - 11:00 AM",
      "11:00 AM - 01:00 PM",
      "02:00 PM - 04:00 PM",
      "04:00 PM - 06:00 PM",
      "06:00 PM - 08:00 PM",
    ];

    bool isSlotExpired(String slot) {
      final now = DateTime.now();

      // Only apply for today
      if (selectedDate == null ||
          DateFormat('yyyy-MM-dd').format(selectedDate!) !=
              DateFormat('yyyy-MM-dd').format(now)) {
        return false;
      }

      // Extract slot start time
      final startTime = slot.split('-')[0].trim(); // "09:00 AM"

      final parsedTime = DateFormat("hh:mm a").parse(startTime);

      final slotDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      return slotDateTime.isBefore(now);
    }

    return await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Drag handle
                  Container(
                    height: 5,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Schedule Property Visit",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: "#001234".toColor(),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // DATE CARD
                  _selectCard(
                    icon: Icons.calendar_today,
                    title: selectedDate == null
                        ? "Select Visiting Date"
                        : DateFormat('dd MMM yyyy').format(selectedDate!),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: "#001234".toColor(), // header background
                                onPrimary: Colors.white,      // header text
                                onSurface: Colors.black87,    // calendar text
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: "#001234".toColor(),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Time Slot",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: "#001234".toColor(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: timeSlots.map((slot) {
                          final isSelected = selectedSlot == slot;

                          final isExpired = isSlotExpired(slot);

                          return GestureDetector(
                            onTap: isExpired
                                ? null
                                : () {
                              setModalState(() {
                                selectedSlot = slot;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isExpired
                                    ? Colors.grey.shade300
                                    : isSelected
                                    ? "#001234".toColor()
                                    : "#EEF5FF".toColor(),

                                borderRadius: BorderRadius.circular(20),
                              ),
                              child:
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time,
                                      size: 16,
                                      color: isSelected ? Colors.white : Colors.black54),
                                  const SizedBox(width: 6),
                                  Text(
                                    slot,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w500,
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

                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: "#001234".toColor(),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      if (selectedDate == null || selectedSlot  == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please select date and time")),
                        );
                        return;
                      }

                      Navigator.pop(context, {
                        "date":
                        DateFormat('yyyy-MM-dd').format(selectedDate!),
                        "time": selectedSlot!,
                      });
                    },
                    child: const Text(
                      "Confirm Booking",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 15),
                ],
              ),
            );
          },
        );
      },
    );

  }

  void showVisitDetails(Map bookingData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // 🔹 Drag Handle
              Container(
                height: 5,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Title
              Row(
                children: [
                  Icon(Icons.event_available, color: "#001234".toColor()),
                  const SizedBox(width: 8),
                  Text(
                    "Visit Scheduled",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: "#001234".toColor(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔹 Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: "#EEF5FF".toColor(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [

                    _infoRow(Icons.calendar_today, "Date",
                        bookingData['visiting_date'] ?? "Pending"),

                    const SizedBox(height: 10),

                    _infoRow(Icons.access_time, "Time",
                        bookingData['visiting_time'] ?? "Pending"),

                    const SizedBox(height: 10),

                    _infoRow(Icons.location_on, "Location",
                        bookingData['locations'] ?? "-"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Agent Name (optional)
              if (bookingData['fieldworkar_name'] != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: _infoRow(
                    Icons.person,
                    "Agent",
                    bookingData['fieldworkar_name'],
                  ),
                ),

              const SizedBox(height: 20),

              // 🔹 Message Box (IMPORTANT UX)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: "#001234".toColor().withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: "#001234".toColor()),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Our property advisor will contact you shortly to confirm your visit.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: "#001234".toColor()),
        const SizedBox(width: 10),
        Text(
          "$title:",
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildImageCarousel(List<RealEstateSlider> sliders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sliders.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final img = sliders[index].image!;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImagePreviewScreen(
                      imageUrls: sliders.map((e) => e.image!).toList(),
                      initialIndex: index,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_realestate/$img',
                    width: 80,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children:[
            Text(
              "Total Images: ${sliders.length}",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildStaticInfoSection(String floor,String Age,String total_floor,metro,metro_distance,road,market_distance,id) {
    final List<Map<String, dynamic>> infoList = [
      // {
      //   'icon': Icons.add_card,
      //   'title': 'ID',
      //   'value': id,
      // },
      {
        'icon': Icons.train,
        'title': 'Nearest Metro',
        'value': metro,
      },
      {
        'icon': Icons.directions_walk,
        'title': 'Metro Distance',
        'value': metro_distance,
      },
      {
        'icon': Icons.location_city,
        'title': 'Market Distance',
        'value': market_distance,
      },
      {
        'icon': Icons.double_arrow,
        'title': 'Road Size',
        'value': road,
      },
      {
        'icon': Icons.home_work_outlined,
        'title': 'Property Age',
        'value': Age,
      },
      {
        'icon': Icons.stairs,
        'title': 'Total Floors',
        'value': total_floor,
      },
      {
        'icon': Icons.store_mall_directory,
        'title': 'On Floor',
        'value': floor,
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Electricity Status',
        'value': '24x7',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "Additional Information",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        ...infoList.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Icon(item['icon'], color: "#001234".toColor(), size: 20),
              const SizedBox(width: 10),
              Text(
                "${item['title']}: ",
                style: TextStyle(    fontFamily: 'Poppins', fontWeight: FontWeight.w500,color: Colors.black,
                ),
              ),
              Expanded(
                child: Text(
                  item['value'],
                  style: TextStyle(    fontFamily: 'Poppins', color: Colors.black87),
                ),
              )
            ],
          ),
        )),
      ],
    );
  }

  Widget buildTitleLocation(DetailedPropertyModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 5,),
        Row(
          children: [
            Text("${data.bhk} ${data.typeOfProperty} For ${data.buyRent} in ",
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20, fontWeight: FontWeight.w400,color: Colors.black87)),
          ],
        ),
        SizedBox(height: 2,),
        Text(data.location,
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                fontSize: 20, color: Colors.blue.shade900)),
      ],
    );
  }

  Widget buildChips(DetailedPropertyModel data) {
    return Wrap(
      spacing: 10,
      children: [
        chip(Icons.check_circle, data.furnished),
        chip(Icons.balcony, data.balcony),
        chip(Icons.local_parking, data.parking),
        chip(Icons.account_balance_wallet, 'Budget friendly'),
      ],
    );
  }

  Widget chip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.black54),
      label: Text(label, style: TextStyle(fontFamily: 'Poppins', color: Colors.black)),
      backgroundColor: "#E3EFFF".toColor(),
      shape: const StadiumBorder(side: BorderSide(color: Colors.black12)),
    );
  }

  Widget buildDetailsGrid(DetailedPropertyModel data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        statTile(Icons.bed, data.bhk, 'Bed'),
        statTile(Icons.bathtub, data.bathroom, 'Bath'),
        statTile(Icons.house, data.residenceCommercial, 'Property'),
        statTile(
          Icons.flip_to_front_outlined,
          (data.squarefit != null && data.squarefit.isNotEmpty) ? "${data.squarefit} Sqft" : "Comm. Space",
          'Sqft',
        ),


      ],
    );
  }

  Widget _selectCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: "#EEF5FF".toColor(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: "#001234".toColor().withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: "#001234".toColor().withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: "#001234".toColor(),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget statTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.black),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold, fontSize: 14,color: Colors.black)),
        Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

}

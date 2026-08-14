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
import '../../../model/Calculate_model.dart';
import '../../../model/detailed_property_model.dart';
import '../../../model/image_model.dart';
import '../Visit Property/Visit Book.dart';

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
        "https://verifyrealestateandservices.in/Second%20PHP%20FILE/book_shedual/show_api_for_property_id_and_user_id.php?property_id=$propertyId&user_id=$userId"
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

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) => PropertyVisitBookingPage(

                              propertyId: data.id.toString(),

                              bhk: data.bhk,

                              propertyType: data.typeOfProperty,

                              location: data.location,

                              name: data.fieldworkerName,

                            ),

                          ),

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
                          isBooked
                              ? "View Details"
                              : "Book Property Visit",
                          style: TextStyle(
                            color: isBooked
                                ? "#001234".toColor()
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                    )
                  ],
                ),
              ),
            );

          }),
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

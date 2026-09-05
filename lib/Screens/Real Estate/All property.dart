import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Verify/Screens/Real%20Estate/filter.dart';
import 'package:Verify/custom_widget/back_button.dart';
import '../../utilities/theme-helper.dart';
import '../../custom_widget/FilterBar.dart';
import '../../custom_widget/Paths.dart';
import '../../custom_widget/property_card.dart';
import '../../model/All_model.dart';
import 'Sub_Srceen/PropertyBylist.dart';
import 'Sub_Srceen/Types/flat/Rent_flat.dart';
import 'Sub_Srceen/Types/property_type_page.dart';
import 'Sub_Srceen/full property.dart';

class AllProperty extends StatefulWidget {
  const AllProperty({super.key});

  @override
  State<AllProperty> createState() => _AllPropertyState();
}

class _AllPropertyState extends State<AllProperty> {
  String _number = '';
  Future<List<AllModel>>? _futureData;
  List<AllModel> allProperties = [];
  List<AllModel> filteredProperties = [];
  bool isLoading = false;
  bool hasTyped = false;
  TextEditingController searchController = TextEditingController();


  final List<Map<String, dynamic>> propertyTypes = [
    {'label': 'Flat', 'icon': Icons.apartment, 'selected': false},
    {'label': 'Farmhouse', 'icon': Icons.cottage, 'selected': false},
    {'label': 'Office', 'icon': Icons.location_city, 'selected': false},
    {'label': 'Shop', 'icon': Icons.warehouse_outlined, 'selected': false},
    {'label': 'Godown', 'icon': Icons.warehouse, 'selected': false},
  ];


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String number = prefs.getString('number') ?? '';
    setState(() {
      _number = number;
      _futureData = fetchData();
    });
  }

  Future<List<AllModel>> fetchData() async {
    final userId = await getUserId();
    final url = Uri.parse(
      "https://verifyrealestateandservices.in/PHP_Files/show_all_category_website_data/show_all_category_data.php?user_id=$userId",
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      //data.sort((a, b) => b['PVR_id'].compareTo(a['PVR_id']));
      return data.map((item) => AllModel.FromJson(item)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  void handleTap(int index) async {
    setState(() {
      propertyTypes[index]['selected'] = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      propertyTypes[index]['selected'] = false;
    });

    final selectedType = propertyTypes[index]['label'];

    if (selectedType == 'Office') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PropertyTypeListPage(
            typeLabel: 'Office',
            endpoint:
                'https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/office.php',
            wrapsDataKey: true,
          )));
    }
    else if (selectedType == 'Godown') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PropertyTypeListPage(
            typeLabel: 'Godown',
            endpoint:
                'https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/Godown.php',
            wrapsDataKey: false,
          )));
    }
    else if (selectedType == 'Shop') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PropertyTypeListPage(
            typeLabel: 'Shop',
            endpoint:
                'https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/Shop.php',
            wrapsDataKey: true,
          )));
    }

    else if (selectedType == 'Farmhouse') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PropertyTypeListPage(
            typeLabel: 'Farmhouse',
            endpoint:
                'https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/farm.php',
            wrapsDataKey: false,
          )));
    }
    else if (selectedType == 'Flat') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const FlatPropertyPage()));
    }
    else {
      // Fallback
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertyListByType(type: selectedType),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.bgColor(context),
          appBar: AppBar(
            leading: CustomBackButton(),
            title: Image.asset(AppImages.appbar, height: 70),
            centerTitle: true,
            backgroundColor: Colors.black,
    bottom: PreferredSize(
    preferredSize: Size.fromHeight(100), // height of bottom
    child: Container(
      margin: const EdgeInsets.all(20.0),
      child: NeumorphicFilterBar(
        icon: Icons.search,
        navigateTo: FilterProperty(),
      ),
    ),
          ),
          ),
          body: _futureData == null
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<List<AllModel>>(
            future: _futureData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "No Data Found!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                );
              }

              final data = snapshot.data!;

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(height: 10,),
                  SizedBox(
                    height: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: List.generate(propertyTypes.length, (index) {
                          final type = propertyTypes[index];
                          final isSelected = type['selected'];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: InkWell(
                              onTap: () => handleTap(index),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 100,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue.shade50 : AppColors.bgColor(context),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4))]
                                      : [],
                                  border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade500),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      type['icon'],
                                      color: isSelected ? Colors.blue : AppColors.textColor(context),
                                      size: 30,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      type['label'],
                                      style: TextStyle(
                                        color: isSelected ? Colors.blue : AppColors.textColor(context),
                                        fontFamily: 'Poppins',
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Featured Property",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                        ),
                        Text(
                          "See all",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Poppins',
                            color: Theme.of(context).textTheme.bodyMedium!.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Property List
                  ...data.map((item) => propertyCard(item)).toList(),
                ],
              );
            },
          ),

        ));
  }

  Widget propertyCard(AllModel item) {
    return GestureDetector(
      onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setInt('id_Building', int.parse(item.id));
        prefs.setString('id_Longitude', item.Longitude);
        prefs.setString('id_Latitude', item.Latitude);
        Navigator.push(context, MaterialPageRoute(builder: (context)
        => Full_Property(),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                "https://verifyrealestateandservices.in/${item.Building_image}",
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child:
                        Text(
                          item.buy_Rent,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "₹${item.Rent} - ${item.Verify_price}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Theme.of(context).textTheme.bodyMedium!.color,),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.Building_Location,
                          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium!.color,),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Features Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      featureIcon(Icons.bed, "${item.BHK}"),
                      featureIcon(Icons.bathtub_outlined, "${item.Baathroom} Baths"),
                      featureIcon(Icons.square_foot, ""
                          "1000 Sqft"),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Rating + Distance (Static)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      const Text("4.8 (112)", style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 12),
                      const Icon(Icons.directions_walk, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      const Text("780m (12 min)", style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget featureIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).textTheme.bodyMedium!.color,),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium!.color,)),
      ],
    );
  }
}

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Verify/utilities/hex_color.dart';
import '../../custom_widget/Searchbar.dart';
import '../../model/Home_model.dart';
import '../Insurace/Health.dart';
import '../Services/Service_Page.dart';
import '../Vehicle/Dashboard.dart';
import 'Sub_Srceen/PropertyBylist.dart';
import 'Sub_Srceen/Types/Godown.dart';
import 'Sub_Srceen/Types/Office.dart';
import 'Sub_Srceen/Types/farmhouse.dart';
import 'Sub_Srceen/Types/flat/flat tab.dart';
import 'Sub_Srceen/Types/shop.dart';
import 'Visit Property/Visit Book.dart';

Future<int?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('id');
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  String selectedType = 'Flat';
  String _number = '';
  Future<List<Catid>>? _futureData;
  late TabController _tabController;
  late AnimationController _bookVisitController;

  List<Map<String, dynamic>> propertyTypes = [
    {'label': 'Flat', 'icon': Icons.apartment},
    {'label': 'Farmhouse', 'icon': Icons.cottage},
    {'label': 'Commercial', 'icon': Icons.location_city},
    {'label': 'Shop', 'icon': Icons.storefront_outlined},
    {'label': 'Godown', 'icon': Icons.warehouse},
  ];

  final List<Map<String, dynamic>> categories = [
    {'title': 'Services', 'image': 'assets/Icons/mechanic.png', 'page': ServicePage()},
    {'title': 'Insurance', 'image': 'assets/Icons/cardiogram.png', 'page': HealthPage()},
    {'title': 'Vehicle Alert', 'image': 'assets/Icons/car.png', 'page': Motor()},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: propertyTypes.length, vsync: this);
    _bookVisitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();   // reverse hataya — ek direction mein continuous sweep
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

  Future<List<Catid>> fetchData() async {
    final url = Uri.parse(
      "https://verifyrealestateandservices.in/WebService4.asmx/show_RealEstate_by_fieldworkarnumber?fieldworkarnumber=9711775300&looking=Flat",
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      data.sort((a, b) => b['PVR_id'].compareTo(a['PVR_id']));
      return data.take(10).map((item) => Catid.FromJson(item)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _futureData = fetchData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bookVisitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: propertyTypes.length,
        child: Scaffold(
          backgroundColor: "#EEF5FF".toColor(),
          body: NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: ClipPath(
                  clipper: BottomLeftCurveClipper(),
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    color: "#001234".toColor(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,   // ← add this

                      children: [
                        Container(
                          margin: const EdgeInsets.all(5),
                          child: NeumorphicSearchBar(HintText: 'Search Here'),
                        ),
                        SizedBox(
                          height: 110,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final itemWidth = constraints.maxWidth / 3; // divide screen width into 3
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: categories.map((item) {
                                  return SizedBox(
                                    width: itemWidth - 20, // small spacing adjustment
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => item['page']),
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.all(6.0),
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: "#E3EFFF".toColor(),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            child: Image.asset(item['image'], height: 40, width: 40),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.all(6.0),
                                            child: Text(
                                              item['title'],
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: "#E3EFFF".toColor(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                        _bookMyVisitCard(),          // ← add

                      ],
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  _tabController,
                  propertyTypes,
                      (index) {
                    setState(() {
                      selectedType = propertyTypes[index]['label'];
                    });
                  },
                ),
              ),

            ],
            body: RefreshIndicator(
              onRefresh: _onRefresh,
              child: TabBarView(

                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: propertyTypes.map((item) {
                  final label = item['label'];
                  switch (label) {
                    case 'Flat':
                      return const FlatPropertyTabs();
                    case 'Godown':
                      return const GodownPropertyPage();
                    case 'Shop':
                      return const ShopPropertyPage();
                    case 'Farmhouse':
                      return const FarmhousePropertyPage();
                    case 'Commercial':
                      return const OfficePropertyPage();
                    default:
                      return PropertyListByType(type: label);
                  }
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookMyVisitCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PropertyVisitBookingPage(
              bhk: '1 BHK',
              propertyType: 'Flat',
              location: 'Sultanpur',
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                "#173B74".toColor(),
                "#001234".toColor(),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: "#E3EFFF".toColor().withOpacity(0.35),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _bookVisitController,
                      builder: (context, child) {
                        final t = _bookVisitController.value;
                        final offsetY = math.sin(t * 2 * math.pi) * 2.5;
                        return Transform.translate(
                          offset: Offset(0, offsetY),
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: "#E3EFFF".toColor().withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Book My Visit",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22.5,
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Pulsing live indicator dot
                              AnimatedBuilder(
                                animation: _bookVisitController,
                                builder: (context, child) {
                                  final t = _bookVisitController.value;
                                  final scale = 0.7 + (math.sin(t * 2 * math.pi) * 0.5 + 0.5) * 0.6;
                                  final opacity = 0.4 + (math.sin(t * 2 * math.pi) * 0.5 + 0.5) * 0.6;
                                  return Opacity(
                                    opacity: opacity,
                                    child: Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Colors.cyanAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Get a guided property visit arranged for you",
                            style: TextStyle(
                              color: "#E3EFFF".toColor().withOpacity(0.8),
                              fontFamily: 'Poppins',
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // "Book Now" pill instead of plain arrow
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: "#E3EFFF".toColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Book",
                            style: TextStyle(
                              color: "#001234".toColor(),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: "#001234".toColor(),
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final height = constraints.maxHeight;
                        return AnimatedBuilder(
                          animation: _bookVisitController,
                          builder: (context, child) {
                            final dx = (_bookVisitController.value * 1.6 - 0.4) * width;
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: Transform.rotate(
                                angle: -0.4,
                                child: Container(
                                  width: width * 0.18,
                                  height: height * 2.2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white.withOpacity(0.0),
                                        Colors.white.withOpacity(0.10),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
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
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  final List<Map<String, dynamic>> propertyTypes;
  final Function(int) onTap;

  _TabBarDelegate(this.controller, this.propertyTypes, this.onTap);

  @override
  double get minExtent => kToolbarHeight;
  @override
  double get maxExtent => kToolbarHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.grey.shade100,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600; // landscape / tablet
          return
            TabBar(
            controller: controller,
            isScrollable: !isWide, // ✅ if wide, spread equally
            indicatorColor: Colors.blue.shade800,
              dividerColor: Colors.white, // border line color
              indicatorWeight: 3,
            labelColor: Colors.blue.shade800,
            unselectedLabelColor: Colors.black,
            labelStyle: TextStyle(
              fontSize: isWide ? 11 : 13, // ✅ smaller font on wide screens
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
            labelPadding: EdgeInsets.only(right: isWide ? 0 : 36),
            tabs: propertyTypes.map((item) {
              return Tab(
                icon: Icon(
                  item['icon'],
                  size: isWide ? 16 : 18,
                ),
                text: item['label'],
              );
            }).toList(),
            onTap: onTap,
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => true;
}

class BottomLeftCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(0, size.height, 50, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

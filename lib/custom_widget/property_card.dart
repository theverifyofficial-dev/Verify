import 'package:Verify/custom_widget/wish_button.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Verify/model/Office_model.dart';
import 'package:intl/intl.dart';
import 'package:Verify/utilities/hex_color.dart';
import '../Screens/Real Estate/Sub_Srceen/full property.dart';

Future<int?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('id');
}

class PropertyCard extends StatelessWidget {
  final OfficePropertyModel item;
  final Widget? wishlistButton; // 👈 NEW


  const PropertyCard({super.key, required this.item,this.wishlistButton,});

  @override
  Widget build(BuildContext context) {
    String displayPrice = item.showPrice.trim();

    String? numericOnly = displayPrice.replaceAll(RegExp(r'[^\d]'), '');
    bool isPureNumber = RegExp(r'^\d+$').hasMatch(displayPrice);

    if (isPureNumber && numericOnly.isNotEmpty) {
      final formatted = NumberFormat('#,##,###').format(int.parse(numericOnly));
      displayPrice = "$formatted";
    }

    return GestureDetector(
      onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setInt('id_Building', int.parse(item.pId));
        prefs.setString('id_Longitude', item.longitude);
        prefs.setString('id_Latitude', item.latitude);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const Full_Property()));
      },
      child:
      Card(
        color: "#F5F8FF".toColor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Card(
                elevation: 4,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      child: Image.network(
                        "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_realestate/${item.propertyPhoto}",
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: wishlistButton ??
                          WishlistButton(
                            pId: int.parse(item.pId),
                            initialState: item.isWishListed,
                          ),
                    ),
                    Positioned(top: 10, left: 10, child: _badge(item.buyRent, Colors.blue.shade800)),
                    Positioned(top: 10, right: 10, child: _badge(item.typeOfProperty, Colors.black.withOpacity(0.7))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(child: _nestedSpecCard(Icons.bed, item.bhk)),
                  const SizedBox(width: 6),
                  Expanded(child: _nestedSpecCard(Icons.train, item.highwayDistance)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _nestedSpecCard(
                      Icons.layers,
                      item.floor.isNotEmpty ? item.floor : "N/A",

                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                elevation: 4,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Text(
                          "₹ $displayPrice",
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Flexible(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.locations.isNotEmpty ? item.locations : "Unknown",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "New Delhi",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _nestedSpecCard(IconData icon, String label) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.black87),
            const SizedBox(width: 13),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
    );
  }
}

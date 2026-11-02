import 'package:flutter/material.dart';
import 'package:Verify/Screens/Real%20Estate/Home.dart';
import 'package:Verify/Screens/Real%20Estate/filter.dart';
import 'package:Verify/Screens/profile.dart';
import 'package:Verify/utilities/hex_color.dart';
import 'package:flutter/services.dart';
import '../custom_widget/Paths.dart';
import 'PropertyManagement/pm_root_screen.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int selectedIndex = 0;
  final PageController pageController = PageController();

  final List<Widget> pages = const [
    Home(),
    PmRootScreen(),
    Profile(),
  ];

  bool hasUnread = false;

  void onTabTapped(int index) {
    setState(() => selectedIndex = index);
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (selectedIndex != 0) {
            // 👈 Profile → Home
            onTabTapped(0);
            return false;
          }

          // 👈 Home → Ask confirmation
          final shouldExit = await _showExitDialog(context);
          return shouldExit;
        },
        child: SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: "#001234".toColor(),
          automaticallyImplyLeading: false,

          flexibleSpace: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 🔥 Perfectly centered logo
                Center(
                  child: Image.asset(
                    AppImages.logo2,
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ),

                // 👉 Actions stay on the right
                Positioned(
                  right: 0,
                  child:
                      IconButton(
                        icon: const Icon(
                          Icons.tune_sharp,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FilterProperty(),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
        body: PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() => selectedIndex = index);
          },
          children: pages,
        ),
        bottomNavigationBar:
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor.withOpacity(0.3), // subtle
        ),

        BottomNavigationBar(

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apartment_outlined),
              label: 'Property Management',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded),
              label: 'Profile',
            ),
          ],
          currentIndex: selectedIndex,
          onTap: onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          backgroundColor:
          //Colors.black,
          "#001234".toColor(),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
          elevation: 20,
        ),
          ]
      ),
    )));
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔵 Soft brand icon
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: "#001234".toColor().withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.exit_to_app_rounded,
                  color: "#001234".toColor(),
                  size: 28,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Exit Verify?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Are you sure you want to close the app?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () { Navigator.pop(context, false);
                        HapticFeedback.selectionClick(); //vibration
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: "#001234".toColor().withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        "Stay",
                        style: TextStyle(
                          color: "#001234".toColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () { Navigator.pop(context, true);
                      HapticFeedback.selectionClick(); //vibration
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: "#001234".toColor(),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Exit",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;
  }

}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Verify/Screens/Loginpage.dart';
import 'package:Verify/custom_widget/Paths.dart';

import 'Real Estate/wishlist.dart';

class SocialLink {
  final String title;
  final String assetPath;
  final String url;

  SocialLink({
    required this.title,
    required this.assetPath,
    required this.url,
  });
}

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  String name = '';
  String email = '';
  String number = '';
  int id = 0;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String? _profileImageUrl;
  bool showMoreSocialLinks = false;

  final List<SocialLink> primarySocialLinks = [
    SocialLink(
      title: "Instagram",
      assetPath: AppImages.instagram,
      url: "https://www.instagram.com/verify_realestate_",
    ),

    SocialLink(
      title: "Facebook",
      assetPath: AppImages.facebook,
      url: "https://www.facebook.com/profile.php?id=61573465167534",
    ),

    SocialLink(
      title: "YouTube",
      assetPath: AppImages.youtube,

      url: "https://www.youtube.com/@Verify_Real_Estate",
    ),
  ];

  final List<SocialLink> moreSocialLinks = [

    SocialLink(
      title: "WhatsApp",
      assetPath: AppImages.whatsapp,
      url: "https://wa.me/919711773800",
    ),
    SocialLink(
      title: "Twitter",
      assetPath: AppImages.x,
      url: "https://x.com/swavenrealty",
    ),
    SocialLink(
      title: "Snapchat",
      assetPath: AppImages.snapchat,
      url: "https://www.snapchat.com/@verify_real",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      await uploadProfileImageToServer(imageFile);
    }
  }

  Future<void> uploadProfileImageToServer(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getInt('id')?.toString();

      if (userId == null) {
        return;
      }

      var uri = Uri.parse(
          'https://verifyrealestateandservices.in/Second%20PHP%20FILE/profie_image_update_main_realestate/profile_image_update.php');

      var request = http.MultipartRequest('POST', uri);
      request.fields['id'] = userId;
      request.files
          .add(await http.MultipartFile.fromPath('profile_image', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final respJson = jsonDecode(respStr);

        if (respJson['status'] == 'success') {
          String imagePath = respJson['image_path'];
          String fullUrl =
              'https://verifyrealestateandservices.in/Second%20PHP%20FILE/profie_image_update_main_realestate/$imagePath';

          await prefs.setString('profile_image_url', fullUrl);

          setState(() {
            _profileImage = imageFile; // still shows instantly
            _profileImageUrl = fullUrl; // persistent
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(respJson['message'] ?? 'Upload successful')),
          );
        } else {
        }
      } else {
      }
    } catch (e) {
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  Future<void> _loadUserData() async {
    final sharedPref = await SharedPreferences.getInstance();

    final imageUrl = sharedPref.getString('profile_image_url');


    setState(() {
      name = sharedPref.getString('name') ?? '';
      email = sharedPref.getString('email') ?? '';
      number = sharedPref.getString('number') ?? '';
      id = sharedPref.getInt('id') ?? 0;
      _profileImageUrl = imageUrl;
    });
  }
  Future<void> _logout() async {
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout Successful')),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  Widget _infoTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ),
    );
  }

  Widget _optionTile(
      String title,
      IconData icon,
      VoidCallback onTap, {
        String? subtitle,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.black38,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid user")),
      );
      return;
    }

    try {
      final url = Uri.parse(
        "https://verifyrealestateandservices.in/PHP_Files/delete_ragister_table/delete_ragister.php",
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode != 200) {
        throw Exception("Server error (${response.statusCode})");
      }

      final decoded = jsonDecode(response.body);

      if (decoded['status'] != 'success') {
        throw Exception(decoded['message'] ?? 'Delete failed');
      }

      // ✅ Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // ⚠️ Only deletes local cached image (OK)
      if (_profileImage != null && await _profileImage!.exists()) {
        await _profileImage!.delete();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully")),
      );

      await Future.delayed(const Duration(milliseconds: 400));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception:', '').trim(),
          ),
        ),
      );
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                "Delete Account?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "This will permanently delete your account and associated data from our servers.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteAccount();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Delete"),
                    ),
                  ),
                ],
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
      backgroundColor: Colors.blue.shade50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_profileImage != null) {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(_profileImage!, fit: BoxFit.cover),
                                  ),
                                ),
                              );
                            }
                          },
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: (_profileImage != null)
                                  ? Image.file(_profileImage!, fit: BoxFit.cover, width: 100, height: 100)
                                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                                  ? Image.network(
                                _profileImageUrl!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (_, __, ___) => Image.asset(AppImages.profile),
                              )
                                  : Image.asset(AppImages.profile),
                            ),
                          )
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.grey.shade500,
                              child: const Icon(Icons.add_a_photo, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text("ID: $id",
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _infoTile("Email", email, Icons.email),
              _infoTile("Phone", number, Icons.phone),
              const SizedBox(height: 10),
              _optionTile(
                "Wishlist",
                Icons.favorite_border,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistPage()),
                  );
                },
              ),
              const SizedBox(height: 20),

              const Divider(color: Colors.black12),
              const SizedBox(height: 10),
              _sectionTitle("Legal & Support"),

              _optionTile(
                "Privacy Policy",
                Icons.shield_outlined,
                    () {
                  _launchURL("https://theverify.in/Privacy_Policy.html");
                },
                subtitle: "How we collect & use your data",
              ),

              _optionTile(
                "Terms & Conditions",
                Icons.description_outlined,
                    () {
                  _launchURL("https://theverify.in/Terms_and_condition.html");
                },
                subtitle: "Rules for using Verify",
              ),

              _optionTile(
                "About Verify",
                Icons.info_outline,
                    () {
                  _launchURL("https://theverify.in/about_us.html");
                },
                subtitle: "Who we are & what we do",
              ),

              _optionTile(
                "Help & Support",
                Icons.support_agent_outlined,
                    () {
                  _launchURL("https://theverify.in/contact_us.html");
                },
                subtitle: "Get help or contact us",
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.black12),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Connect with us",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showMoreSocialLinks = !showMoreSocialLinks;
                      });
                    },
                    child: Center(
                      child: Text(
                        showMoreSocialLinks ? "Show less ▲" : "Show more ▼",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _socialGrid(primarySocialLinks),

              if (showMoreSocialLinks) ...[
                const SizedBox(height: 12),
                _socialGrid(moreSocialLinks),
              ],


              const SizedBox(height: 30),
              const Center(
                child: Text(
                  "App version 1.0.0",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete Account"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _socialGrid(List<SocialLink> links) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: links.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final link = links[index];
        return GestureDetector(
          onTap: () => _launchURL(link.url),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50, // fixed tap area
                height: 50,
                child: Center(
                  child: Image.asset(
                    link.assetPath,
                    width: _iconSizeFor(link.title),
                    height: _iconSizeFor(link.title),
                    fit: _iconFitFor(link.title),
                  ),
                ),
              ),

              const SizedBox(height: 4),
              Text(
                link.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _iconSizeFor(String title) {
    switch (title) {
      case 'Twitter':
        return 32;
      case 'Facebook':
        return 36;
      default:
        return 48;
    }
  }

  BoxFit _iconFitFor(String title) {
    switch (title) {
      case 'Twitter':
        return BoxFit.cover; // removes extra padding
      case 'Facebook':
        return BoxFit.cover;
      default:
        return BoxFit.contain;
    }
  }

}

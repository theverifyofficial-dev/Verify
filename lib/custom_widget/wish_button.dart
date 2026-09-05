import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> toggleWishlist({
  required int pId,
  required bool isWishlisted,
})
async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('id');

  if (userId == null) {
    return false;
  }

  final Uri url = Uri.parse(
    isWishlisted
        ? "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/wishlist_remove.php"
        : "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/wishlist_add.php",
  );

  final response = await http.post(url, body: {
    "user_id": userId.toString(),
    "property_id": pId.toString(),
  });

  return response.statusCode == 200;
}

class WishlistButton extends StatefulWidget {
  final int pId;
  final bool initialState;

  const WishlistButton({
    super.key,
    required this.pId,
    required this.initialState,
  });

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> {
  late bool isWishlisted;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    isWishlisted = widget.initialState;
  }

  Future<void> _toggle() async {
    if (loading) return;

    setState(() => loading = true);

    final success = await toggleWishlist(
      pId: widget.pId,
      isWishlisted: isWishlisted,
    );

    if (success) {
      setState(() => isWishlisted = !isWishlisted);
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Icon(
        isWishlisted ? Icons.favorite : Icons.favorite_border,
        color: isWishlisted ? Colors.redAccent : Colors.white,
        size: 30,
      ),
    );
  }
}

class WishlistRemoveButton extends StatefulWidget {
  final int pId;
  final VoidCallback onRemoved;

  const WishlistRemoveButton({
    super.key,
    required this.pId,
    required this.onRemoved,
  });

  @override
  State<WishlistRemoveButton> createState() => _WishlistRemoveButtonState();
}

class _WishlistRemoveButtonState extends State<WishlistRemoveButton> {
  bool loading = false;

  Future<void> _remove() async {
    if (loading) return;
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id');

    if (userId == null) return;

    final url = Uri.parse(
      "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/wishlist_remove.php",
    );

    final res = await http.post(url, body: {
      "user_id": userId.toString(),
      "property_id": widget.pId.toString(),
    });

    if (res.statusCode == 200) {
      widget.onRemoved(); // 🔥 remove from UI
    }

    setState(() => loading = false);
  }

  Future<void> _confirmRemove(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 14),
              const Text(
                "Remove from wishlist?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "This property will be removed from your wishlist.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _remove();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Remove"),
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
    return GestureDetector(
      onTap: () => _confirmRemove(context),
      child: const Icon(
        Icons.favorite,
        color: Colors.redAccent,
        size: 30,
      ),
    );
  }

}
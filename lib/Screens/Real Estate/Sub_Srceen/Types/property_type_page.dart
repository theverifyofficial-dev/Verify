import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Verify/utilities/hex_color.dart';
import '../../../../custom_widget/property_card.dart';
import '../../../../model/Office_model.dart';

/// Shared list screen for the simple, single-endpoint property types
/// (Office, Shop, Godown, Farmhouse). These four used to be near-identical
/// copy-pasted files; the only real differences between them are the
/// backend endpoint, the label shown in the empty state, and whether that
/// endpoint wraps its list in a `"data"` key or returns the list directly
/// — both of which are genuine per-type backend inconsistencies, not
/// cosmetic ones, so they're kept as explicit parameters rather than
/// papered over.
class PropertyTypeListPage extends StatefulWidget {
  /// Human-readable type name, used only for the "No X properties found."
  /// empty state.
  final String typeLabel;

  /// Base endpoint URL, without the `?user_id=` query string — that's
  /// appended automatically once the logged-in user id is available.
  final String endpoint;

  /// Whether this endpoint returns `{"data": [...]}` (true) or a bare
  /// `[...]` list (false). Office/Shop use the former, Godown/Farmhouse
  /// use the latter — this mirrors the actual backend behavior for each,
  /// it isn't a stylistic choice.
  final bool wrapsDataKey;

  const PropertyTypeListPage({
    super.key,
    required this.typeLabel,
    required this.endpoint,
    required this.wrapsDataKey,
  });

  @override
  State<PropertyTypeListPage> createState() => _PropertyTypeListPageState();
}

class _PropertyTypeListPageState extends State<PropertyTypeListPage> {
  late Future<List<OfficePropertyModel>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchProperties();
  }

  Future<List<OfficePropertyModel>> _fetchProperties() async {
    final userId = await getUserId();
    final url = Uri.parse('${widget.endpoint}?user_id=$userId');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load ${widget.typeLabel} properties');
    }

    final decoded = json.decode(response.body);

    final List<dynamic> data;
    if (widget.wrapsDataKey) {
      data = (decoded is Map<String, dynamic> ? decoded['data'] : null) ?? [];
    } else {
      data = decoded is List ? decoded : [];
    }

    // Sort descending by P_id. Compared as strings (matching what most of
    // these endpoints already assumed) rather than int.parse, so a
    // non-numeric or missing P_id can't crash this screen.
    data.sort((a, b) =>
        (b['P_id']?.toString() ?? '0').compareTo(a['P_id']?.toString() ?? '0'));

    return data
        .map((item) => OfficePropertyModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: "#E3EFFF".toColor(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          FutureBuilder<List<OfficePropertyModel>>(
            future: _futureData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 200),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }

              final data = snapshot.data;

              if (data == null || data.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 100),
                      Text(
                        "No ${widget.typeLabel} properties found.",
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // outer ListView handles scrolling
                scrollDirection: Axis.vertical,
                itemCount: data.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final item = data[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: PropertyCard(item: item),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

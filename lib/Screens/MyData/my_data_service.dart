import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Verify/model/my_data_models.dart';

/// Thrown when SharedPreferences has no stored owner/user number to
/// query these endpoints with. Kept distinct from a generic network/server
/// exception so the UI can show "please log in again" instead of
/// "couldn't load this data / retry".
class MissingOwnerNumberException implements Exception {
  @override
  String toString() => 'No owner number found on this device.';
}

/// Repository/service layer for the "My Data" API categories reached
/// from Owner Dashboard Quick Actions - My Buildings, Agreement,
/// Insurance (see pm_live_list_screens.dart). Originally written for a
/// standalone Profile -> My Data screen, then briefly a dashboard
/// section group - both were removed in favor of the current Quick
/// Actions entry points; this service is unchanged, only its caller has
/// moved each time.
///
/// Reads the logged-in user's stored mobile number (SharedPreferences key
/// `'number'` - the same key already used everywhere else in this app,
/// e.g. Home.dart, All property.dart, Vehicle_form.dart, Loginpage.dart)
/// and uses it as the owner-number query parameter for all 5 endpoints.
/// Nothing here is hardcoded.
class MyDataService {
  static const Duration _timeout = Duration(seconds: 20);

  /// Page-level check so the UI can show one clear "please log in again"
  /// state instead of 5 separate identical failures when there's no
  /// number on file at all.
  Future<bool> hasOwnerNumber() async => (await _ownerNumber()) != null;

  /// Reads the stored owner/user mobile number. Never hardcoded.
  /// Returns null (rather than '') when nothing is stored, so callers can
  /// tell "logged out / no number on file" apart from "number is blank".
  Future<String?> _ownerNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('number');
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<http.Response> _get(String url) {
    return http.get(Uri.parse(url)).timeout(
          _timeout,
          onTimeout: () => throw TimeoutException('Request timed out'),
        );
  }

  void _assertOk(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('Server error (${response.statusCode})');
    }
  }

  /// Tolerates the range of shapes these PHP endpoints are known (from the
  /// rest of this app) to return: a bare JSON array, an object wrapping
  /// the array under a common key, or a single bare object. An EMPTY body
  /// is treated as "no records" (several endpoints elsewhere in this app,
  /// e.g. All property.dart, already return a bare empty body for that
  /// case) rather than as an error. A non-empty body that fails to parse
  /// as JSON (e.g. an HTML/PHP error page) is treated as a real error.
  List<dynamic> _parseList(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return const [];

    dynamic decoded;
    try {
      decoded = json.decode(trimmed);
    } catch (_) {
      throw Exception('Unexpected response from server');
    }

    if (decoded is List) return decoded;

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      for (final key in ['data', 'result', 'records', 'response', 'list']) {
        final value = map[key];
        if (value is List) return value;
      }
      final status = map['status']?.toString().toLowerCase();
      if (status == 'error' || status == 'false' || status == '0') {
        return const [];
      }
      if (map.isNotEmpty) return [map];
    }

    return const [];
  }

  Future<List<T>> _fetchAndParse<T extends DataRecord>(
    String urlTemplate,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final number = await _ownerNumber();
    if (number == null) throw MissingOwnerNumberException();

    // URL-encode the stored number before substitution - it's expected to
    // be plain digits, but this stays correct even if a '+' country-code
    // prefix or stray whitespace ever ends up in SharedPreferences.
    final encoded = Uri.encodeQueryComponent(number);
    final url = urlTemplate.replaceFirst('NUMBER', encoded);

    final response = await _get(url);
    _assertOk(response);
    final items = _parseList(response.body);
    return items
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<FuturePropertyRecord>> fetchFutureProperties() {
    return _fetchAndParse(
      "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/future_property_show_by_owner_name.php?ownernumber=NUMBER",
      FuturePropertyRecord.fromJson,
    );
  }

  Future<List<UnderFuturePropertyFlatRecord>> fetchUnderFutureFlats() {
    return _fetchAndParse(
      "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/show_under_future_property_flat_by_owner_number.php?owner_number=NUMBER",
      UnderFuturePropertyFlatRecord.fromJson,
    );
  }

  Future<List<LiveFlatRecord>> fetchLiveFlats() {
    return _fetchAndParse(
      "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/live_flat_by_owner_number.php?owner_number=NUMBER",
      LiveFlatRecord.fromJson,
    );
  }

  Future<List<AgreementRecord>> fetchAgreements() {
    return _fetchAndParse(
      "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/show_agreement_by_owner_number.php?owner_mobile_no=NUMBER",
      AgreementRecord.fromJson,
    );
  }

  Future<List<InsuranceRecord>> fetchInsurance() {
    return _fetchAndParse(
      "https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/insurance_details.php?number=NUMBER",
      InsuranceRecord.fromJson,
    );
  }
}

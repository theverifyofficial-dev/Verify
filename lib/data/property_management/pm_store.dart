import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/property_management/pm_models.dart';
import 'pm_reference_data.dart';

/// In-memory, session-only state for the Property Management module.
///
/// There is NO backend behind this store. Every add/update method below
/// mutates `pmReferencePortfolio` directly, in RAM, for as long as the app
/// process stays alive - nothing is written to disk or any server, and a
/// fresh app launch starts again from the owner's original reference data
/// (pm_reference_data.dart). This is the "statically front end based"
/// implementation the owner asked for. When a real Property Management
/// API exists, these methods are the exact places to swap in real network
/// calls (each is small and single-purpose for that reason).
///
/// The role - Owner or Tenant - is now resolved from the real
/// check_owner_tenant_api.php endpoint (see _refreshRoleFromServer()
/// below), called once per app session from ensureRoleLoaded(), and
/// persisted via SharedPreferences so the next launch has an answer
/// immediately while the fresh server check runs in the background.
/// There is no more manual owner/tenant toggle in the UI - the server
/// is the source of truth.
class PmStore extends ChangeNotifier {
  PmStore._internal();
  static final PmStore instance = PmStore._internal();

  final PmPortfolio portfolio = pmReferencePortfolio;

  PmRole role = PmRole.owner;
  bool isDark = true; // Property Management module's own theme - default dark.
  bool _roleLoaded = false;

  static const _roleKey = 'pm_role';
  static const _numberKey = 'number'; // same SharedPreferences key MyDataService reads.
  static const _themeKey = 'pm_theme_dark';
  static const _tenantBuildingKey = 'pm_active_building_index';
  static const _tenantFlatKey = 'pm_active_flat_index';

  // "Which flat am I viewing as a tenant" - defaults to the first rented
  // flat in the portfolio. There is no tenant login/auth in this app yet,
  // so this picker is itself a temporary, clearly-labelled stand-in (see
  // the "Switch flat (demo)" action in the tenant dashboard).
  int activeBuildingIndex = 0;
  int activeFlatIndex = 1; // Building 1, flat "101" (Akshay) by default

  PmBuilding get activeTenantBuilding => portfolio.buildings[activeBuildingIndex];

  PmFlat get activeTenantFlat => activeTenantBuilding.flats[activeFlatIndex];

  Future<void> ensureRoleLoaded() async {
    if (_roleLoaded) return;
    _roleLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString(_roleKey);
      if (savedRole == 'tenant') role = PmRole.tenant;
      final savedTheme = prefs.getBool(_themeKey);
      if (savedTheme != null) isDark = savedTheme;
      final b = prefs.getInt(_tenantBuildingKey);
      final f = prefs.getInt(_tenantFlatKey);
      if (b != null && b >= 0 && b < portfolio.buildings.length) {
        activeBuildingIndex = b;
        final flats = portfolio.buildings[b].flats;
        if (f != null && f >= 0 && f < flats.length) activeFlatIndex = f;
      }
    } catch (_) {
      // SharedPreferences unavailable - fall back to defaults silently.
    }
    notifyListeners();
    // Fire-and-forget: refreshes `role` from the real backend once this
    // session, without making the UI wait on a network round-trip for
    // its very first frame.
    // ignore: unawaited_futures
    _refreshRoleFromServer();
  }

  bool _roleRefreshStarted = false;

  /// Calls the real role-check API
  /// (check_owner_tenant_api.php?mobile=<number>, e.g.
  /// {"status":true,"message":"Owner found","role":"owner"}) once per
  /// app session - fired from [ensureRoleLoaded], which itself runs once
  /// when the Property Management tab is first built (i.e. once when the
  /// user logs in and lands on the home screen). On success, the
  /// server's answer becomes [role] and is persisted the same way the
  /// old manual toggle used to persist it, via [setRole] - so the next
  /// app launch's [ensureRoleLoaded] picks it straight up with no extra
  /// wiring. Any failure (no stored number yet, no network, a malformed
  /// response) is swallowed and the locally-saved role from the last
  /// successful check - or the PmRole.owner default - stays in effect.
  Future<void> _refreshRoleFromServer() async {
    if (_roleRefreshStarted) return;
    _roleRefreshStarted = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final number = prefs.getString(_numberKey)?.trim();
      if (number == null || number.isEmpty) return;

      final uri = Uri.parse(
        'https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/check_owner_tenant_api.php',
      ).replace(queryParameters: {'mobile': number});
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;

      final decoded = json.decode(response.body);
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);
      if (map['status'] != true) return;

      final serverRole = map['role']?.toString().toLowerCase();
      if (serverRole != 'owner' && serverRole != 'tenant') return;

      await setRole(serverRole == 'tenant' ? PmRole.tenant : PmRole.owner);
    } catch (_) {
      // Network/parse failure - keep whatever role was already loaded.
    }
  }

  Future<void> setRole(PmRole newRole) async {
    role = newRole;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleKey, newRole == PmRole.tenant ? 'tenant' : 'owner');
    } catch (_) {}
  }

  Future<void> setDark(bool value) async {
    isDark = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, value);
    } catch (_) {}
  }

  Future<void> toggleTheme() => setDark(!isDark);

  Future<void> setActiveTenantFlat(int buildingIndex, int flatIndex) async {
    activeBuildingIndex = buildingIndex;
    activeFlatIndex = flatIndex;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_tenantBuildingKey, buildingIndex);
      await prefs.setInt(_tenantFlatKey, flatIndex);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // Payments
  // ---------------------------------------------------------------------
  void addPayment(PmFlat flat, PmPayment payment) {
    flat.payments.add(payment);
    notifyListeners();
  }

  void confirmPayment(PmFlat flat, PmPayment payment) {
    payment.status = PaymentStatus.confirmed;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Family members
  // ---------------------------------------------------------------------
  void addFamilyMember(PmFlat flat, FamilyMember member) {
    flat.familyMembers.add(member);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Vehicles
  // ---------------------------------------------------------------------
  void addVehicle(PmFlat flat, PmVehicle vehicle) {
    flat.vehicles.add(vehicle);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Documents
  // ---------------------------------------------------------------------
  void addDocument(PmFlat flat, PmDocument document) {
    flat.documents.add(document);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Maintenance
  // ---------------------------------------------------------------------
  void addMaintenanceRequest(PmFlat flat, PmMaintenanceRequest request) {
    flat.maintenanceRequests.add(request);
    notifyListeners();
  }

  void updateMaintenanceStatus(PmMaintenanceRequest request, MaintenanceStatus status) {
    request.status = status;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Notice / move-out
  // ---------------------------------------------------------------------
  void setNotice(PmFlat flat, PmNotice notice) {
    flat.notice = notice;
    notifyListeners();
  }

  void updateNoticeStatus(PmFlat flat, NoticeStatus status) {
    if (flat.notice != null) {
      flat.notice!.status = status;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------
  // Tenant / flat details
  // ---------------------------------------------------------------------
  void updateTenantName(PmFlat flat, String? name) {
    flat.tenantName = name;
    notifyListeners();
  }

  void updateTenantPhone(PmFlat flat, String? phone) {
    flat.tenantPhone = phone;
    notifyListeners();
  }

  void updateRent(PmFlat flat, int? rent) {
    flat.monthlyRent = rent;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Buildings / flats (structure)
  // ---------------------------------------------------------------------
  void addBuilding(PmBuilding building) {
    portfolio.buildings.add(building);
    notifyListeners();
  }

  void addFlat(PmBuilding building, PmFlat flat) {
    building.flats.add(flat);
    notifyListeners();
  }

  void addExpense(PmBuilding building, PmExpense expense) {
    building.expenses.add(expense);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Agreement / Police Verification / Insurance / Utility bills
  // (new static sections - owner manages Agreement/Verification/Insurance,
  // both owner and tenant can log a utility reading/bill, both can add or
  // edit vehicle details - same in-memory-only rule as everything above)
  // ---------------------------------------------------------------------
  void setAgreement(PmFlat flat, PmAgreement agreement) {
    flat.agreement = agreement;
    notifyListeners();
  }

  void setPoliceVerification(PmFlat flat, PmPoliceVerification verification) {
    flat.policeVerification = verification;
    notifyListeners();
  }

  void setInsurance(PmFlat flat, PmInsurancePolicy insurance) {
    flat.insurance = insurance;
    notifyListeners();
  }

  void addUtilityRecord(PmFlat flat, PmUtilityRecord record) {
    flat.utilityRecords.add(record);
    notifyListeners();
  }

  void updateVehicleDetails(PmVehicle vehicle, {String? regNumber, String? color, String? note}) {
    vehicle.regNumber = regNumber;
    vehicle.color = color;
    vehicle.note = note;
    notifyListeners();
  }
}

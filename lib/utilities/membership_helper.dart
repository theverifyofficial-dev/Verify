import 'package:shared_preferences/shared_preferences.dart';

/// Reads/writes the user's membership status from SharedPreferences.
/// Backend sends one of three raw status strings:
///   - "membership_active"   → valid, paid membership
///   - "membership_expiry"   → membership existed but has expired
///   - "no_membership"       → default, never purchased (new accounts)
///
/// Set once at login (from the login API response), and again after a
/// successful membership purchase.
class MembershipHelper {
  static const _kStatus = 'membership_status';
  static const _kExpiry = 'membership_expiry_date'; // stored as yyyy-MM-dd

  static const statusActive = 'membership_active';
  static const statusExpired = 'membership_expiry';
  static const statusNone = 'no_membership';

  /// True only when backend explicitly says the membership is active.
  static Future<bool> isActive() async {
    final status = await currentStatus();
    return status == statusActive;
  }

  static Future<bool> isExpired() async {
    final status = await currentStatus();
    return status == statusExpired;
  }

  /// Raw status string as sent by backend, defaults to "no_membership"
  /// if nothing has been saved yet (e.g. before first login).
  static Future<String> currentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kStatus) ?? statusNone;
  }

  /// Present for both active and expired memberships (so the UI can
  /// still show "expired on <date>" even after expiry).
  static Future<DateTime?> expiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_kExpiry);
    if (expiryStr == null || expiryStr.isEmpty) return null;
    return DateTime.tryParse(expiryStr);
  }

  /// Call this right after login API response is parsed, and again
  /// right after a successful membership payment verification.
  static Future<void> save({
    required String status, // one of statusActive / statusExpired / statusNone
    String? expiryDate, // "yyyy-MM-dd", optional for statusNone
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStatus, status);
    if (expiryDate != null && expiryDate.isNotEmpty) {
      await prefs.setString(_kExpiry, expiryDate);
    } else {
      await prefs.remove(_kExpiry);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStatus);
    await prefs.remove(_kExpiry);
  }
}
/// Models for the 5 owner-scoped data endpoints reached from Quick
/// Actions on the Property Management Owner Dashboard ("My Buildings",
/// "Agreement", "Insurance" - see pm_live_list_screens.dart) rather than
/// shown wholesale on the dashboard itself. These used to back a
/// standalone "My Data" screen reached from Profile, then briefly a
/// dashboard section group - both were removed in favor of the current
/// Quick-Actions entry points; nothing in this file's parsing logic
/// changed either time, only its callers.
///
/// IMPORTANT CONTEXT FOR WHOEVER TOUCHES THIS NEXT:
/// Direct curl/network probes of these 5 endpoints are blocked by this
/// environment's egress policy (both the cloud sandbox and the linked
/// Mac's shell), so no live sample response has been confirmed from
/// here. Rather than guess at field names (and risk every card silently
/// showing blanks the first time a guess is wrong), each record keeps
/// the raw JSON map and surfaces every key/value pair the API actually
/// returned, via a small per-endpoint "which field is probably the
/// title/subtitle/image" heuristic, plus a key-substring
/// [PmFieldClassifier] (pm_shared_widgets.dart) that buckets any
/// remaining field into a semantic kind (money/date/phone/status/
/// location/measurement/count) for icon/color purposes without needing
/// the exact name. The UI-facing shape is shared (see DataRecord), but
/// the heuristics are tuned per endpoint to that endpoint's domain,
/// which is what the task asked for (typed models, not one generic blob
/// reused blindly).
///
/// Once you have one real sample response per endpoint (e.g. from the
/// field app's own Dart models for these same fields, or a direct
/// network probe from somewhere unrestricted), tighten
/// `title`/`subtitle`/`imageUrl`/`fields` on the relevant class below to
/// read named fields directly (e.g. `raw['building_name']`) instead of
/// scanning - everything else (service layer, list/detail screens)
/// stays the same.
library my_data_models;

/// Common shape the UI (PmSmartRecordCard, PmApiRecordDetailScreen in
/// pm_shared_widgets.dart, and the screens in pm_live_list_screens.dart)
/// renders against. Every concrete record below is backed by its own
/// [raw] JSON map.
abstract class DataRecord {
  final Map<String, dynamic> raw;

  const DataRecord(this.raw);

  /// Best-effort headline for the card.
  String get title;

  /// Best-effort secondary line under the title (address/date/status/...),
  /// or null if nothing suitable was found.
  String? get subtitle;

  /// Best-effort network image URL for the card's image (the API's own
  /// photo for this record), or null if no image-like field was found -
  /// in which case the card falls back to the bundled static placeholder.
  String? get imageUrl;

  /// Confirmed static base URL(s) to resolve [imageUrl] against when it's
  /// a bare relative path rather than a full http(s) URL, tried in order
  /// until one of them actually loads. Confirmed by reading the sibling
  /// "field app" codebase (The_verify_field), which already renders
  /// these same image fields successfully - see each subclass override
  /// below for exactly which screen/file its base path(s) came from. An
  /// EMPTY list (the default here) means no base has been confirmed yet
  /// for this record type, so a relative path is left unresolved - this
  /// falls back to the placeholder icon instead of guessing a base and
  /// silently showing a broken/wrong image.
  List<String> get imageBaseUrls => const [];

  /// Every absolute URL worth trying for this record's image, in order:
  /// [imageUrl] itself if it's already absolute, otherwise [imageUrl]
  /// resolved against each of [imageBaseUrls] in turn. The UI
  /// (_PmApiRecordImage in pm_shared_widgets.dart) tries these in order
  /// and falls back to an icon once the list is exhausted.
  List<String> get resolvedImageUrls {
    final raw = imageUrl;
    if (raw == null || raw.isEmpty) return const [];
    if (raw.startsWith('http://') || raw.startsWith('https://')) return [raw];
    final trimmed = raw.startsWith('/') ? raw.substring(1) : raw;
    return [for (final base in imageBaseUrls) '$base$trimmed'];
  }

  /// Every other field as prettified (label, value) pairs, used to build
  /// the horizontally-scrolling chip row inside the card. Null/empty
  /// values are skipped, as is whichever field was already used above.
  List<MapEntry<String, String>> get fields;
}

// ---------------------------------------------------------------------
// Shared helpers (parsing utilities, not a shared schema - every class
// below still decides its own candidate keys).
// ---------------------------------------------------------------------

const List<String> _imageKeyHints = [
  'image',
  'img',
  'photo',
  'picture',
  'thumbnail',
  'thumb',
];

String _prettifyKey(String key) {
  final spaced = key
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .trim();
  if (spaced.isEmpty) return key;
  return spaced
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'null') return null;
  return s;
}

/// Scans [raw] for the first key containing any of [candidates]
/// (case-insensitive) with a non-empty value.
String? _pickByKeyHint(Map<String, dynamic> raw, List<String> candidates) {
  for (final hint in candidates) {
    for (final key in raw.keys) {
      if (key.toLowerCase().contains(hint)) {
        final value = _stringOrNull(raw[key]);
        if (value != null) return value;
      }
    }
  }
  return null;
}

/// Same scan as [_pickByKeyHint], but also returns which key matched, so
/// callers can exclude that exact key from the generic "other fields"
/// chip row instead of excluding every key that merely contains a hint.
MapEntry<String, String>? _pickEntryByKeyHint(
    Map<String, dynamic> raw, List<String> candidates) {
  for (final hint in candidates) {
    for (final key in raw.keys) {
      if (key.toLowerCase().contains(hint)) {
        final value = _stringOrNull(raw[key]);
        if (value != null) return MapEntry(key, value);
      }
    }
  }
  return null;
}

/// Falls back to the first non-empty string-ish field in the map, in
/// insertion order, skipping obviously internal id/key fields.
String? _firstPresentableField(Map<String, dynamic> raw,
    {Set<String> excludeKeys = const {}}) {
  for (final entry in raw.entries) {
    if (excludeKeys.contains(entry.key)) continue;
    final value = _stringOrNull(entry.value);
    if (value != null) return value;
  }
  return null;
}

/// A value that merely looks like a URL/path is treated as an image only
/// if it also looks like an image (common extension, or an http(s) URL -
/// several PHP APIs in this app return a bare relative path rather than a
/// full URL, see All_model.dart's Building_image/Realstate_image, so this
/// intentionally accepts both and the card widget resolves relative paths
/// against the same image host the rest of the app already uses).
bool _looksLikeImage(String value) {
  final lower = value.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return true;
  }
  return RegExp(r'\.(png|jpe?g|gif|webp|bmp)(\?|$)').hasMatch(lower);
}

String? _pickImageUrl(Map<String, dynamic> raw) {
  final entry = _pickEntryByKeyHint(raw, _imageKeyHints);
  if (entry == null) return null;
  return _looksLikeImage(entry.value) ? entry.value : null;
}

List<MapEntry<String, String>> _allFieldsExcept(
    Map<String, dynamic> raw, Set<String> usedKeys) {
  final out = <MapEntry<String, String>>[];
  raw.forEach((key, value) {
    if (usedKeys.contains(key)) return;
    final display = _stringOrNull(value);
    if (display == null) return;
    out.add(MapEntry(_prettifyKey(key), display));
  });
  return out;
}

/// Shared "which keys matched title/subtitle/image" bookkeeping, so each
/// class's `fields` getter doesn't re-scan with slightly different logic.
Set<String> _usedKeys(
  Map<String, dynamic> raw, {
  required List<String> titleHints,
  required List<String> subtitleHints,
}) {
  final used = <String>{};
  final imageEntry = _pickEntryByKeyHint(raw, _imageKeyHints);
  if (imageEntry != null) used.add(imageEntry.key);
  final hints = [...titleHints, ...subtitleHints];
  for (final key in raw.keys) {
    if (hints.any((h) => key.toLowerCase().contains(h))) used.add(key);
  }
  return used;
}

// ---------------------------------------------------------------------
// 1. Future Property by Owner Name
// future_property_show_by_owner_name.php?ownernumber=NUMBER
// ---------------------------------------------------------------------
class FuturePropertyRecord extends DataRecord {
  const FuturePropertyRecord(super.raw);

  factory FuturePropertyRecord.fromJson(Map<String, dynamic> json) =>
      FuturePropertyRecord(json);

  static const _titleHints = ['building', 'property_name', 'name', 'title'];
  static const _subtitleHints = ['address', 'location', 'place', 'city'];

  @override
  String get title =>
      _pickByKeyHint(raw, _titleHints) ??
      _firstPresentableField(raw) ??
      'Future Property';

  @override
  String? get subtitle => _pickByKeyHint(raw, _subtitleHints);

  @override
  String? get imageUrl => _pickImageUrl(raw);

  // Confirmed from the field app: Future_property_details.dart,
  // Plot_detail.dart, Commercial_detail.dart and Duplicate_Property.dart
  // all build building photo URLs against main_realestate/. The second
  // base is a fallback for the listing screen (Future_Property.dart)/
  // upload form (Add_FutureProperty_Images.dart), which use a different
  // folder that was never consolidated with the first in the field app.
  @override
  List<String> get imageBaseUrls => const [
        'https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_realestate/',
        'https://verifyrealestateandservices.in/Second%20PHP%20FILE/new_future_property_api_with_multile_images_store/',
      ];

  @override
  List<MapEntry<String, String>> get fields => _allFieldsExcept(
      raw, _usedKeys(raw, titleHints: _titleHints, subtitleHints: _subtitleHints));
}

// ---------------------------------------------------------------------
// 2. Under Future Property Flat by Owner Number
// show_under_future_property_flat_by_owner_number.php?owner_number=NUMBER
// ---------------------------------------------------------------------
class UnderFuturePropertyFlatRecord extends DataRecord {
  const UnderFuturePropertyFlatRecord(super.raw);

  factory UnderFuturePropertyFlatRecord.fromJson(Map<String, dynamic> json) =>
      UnderFuturePropertyFlatRecord(json);

  static const _titleHints = ['flat', 'building', 'property_name', 'name'];
  static const _subtitleHints = ['status', 'stage', 'progress', 'address'];

  @override
  String get title =>
      _pickByKeyHint(raw, _titleHints) ??
      _firstPresentableField(raw) ??
      'Under-Construction Flat';

  @override
  String? get subtitle => _pickByKeyHint(raw, _subtitleHints);

  @override
  String? get imageUrl => _pickImageUrl(raw);

  // Confirmed from the field app's Flat Detail page for this same
  // future-property flow, under_flats_infutureproperty.dart, which
  // builds flat photo URLs against main_realestate/ - same fallback
  // reasoning as FuturePropertyRecord above.
  @override
  List<String> get imageBaseUrls => const [
        'https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_realestate/',
        'https://verifyrealestateandservices.in/Second%20PHP%20FILE/new_future_property_api_with_multile_images_store/',
      ];

  @override
  List<MapEntry<String, String>> get fields => _allFieldsExcept(
      raw, _usedKeys(raw, titleHints: _titleHints, subtitleHints: _subtitleHints));
}

// ---------------------------------------------------------------------
// 3. Live Flat by Owner Number
// live_flat_by_owner_number.php?owner_number=NUMBER
// ---------------------------------------------------------------------
class LiveFlatRecord extends DataRecord {
  const LiveFlatRecord(super.raw);

  factory LiveFlatRecord.fromJson(Map<String, dynamic> json) =>
      LiveFlatRecord(json);

  static const _titleHints = ['flat', 'building', 'property_name', 'name'];
  static const _subtitleHints = ['price', 'rent', 'address', 'location'];

  @override
  String get title =>
      _pickByKeyHint(raw, _titleHints) ??
      _firstPresentableField(raw) ??
      'Live Flat';

  @override
  String? get subtitle => _pickByKeyHint(raw, _subtitleHints);

  @override
  String? get imageUrl => _pickImageUrl(raw);

  // No confirmed static image base path for this endpoint yet - the
  // field-app investigation covered Future Property/Under-Construction
  // Flats, Agreements and Insurance, but not live/rented Flats
  // specifically. imageBaseUrls intentionally stays at the DataRecord
  // default (empty) rather than guessing, so a relative imageUrl here
  // falls back to the placeholder icon instead of silently showing a
  // wrong photo. Once confirmed, add an override here exactly like
  // FuturePropertyRecord's above.

  @override
  List<MapEntry<String, String>> get fields => _allFieldsExcept(
      raw, _usedKeys(raw, titleHints: _titleHints, subtitleHints: _subtitleHints));
}

// ---------------------------------------------------------------------
// 4. Agreement by Owner Number
// show_agreement_by_owner_number.php?owner_mobile_no=NUMBER
// ---------------------------------------------------------------------
class AgreementRecord extends DataRecord {
  const AgreementRecord(super.raw);

  factory AgreementRecord.fromJson(Map<String, dynamic> json) =>
      AgreementRecord(json);

  static const _titleHints = [
    'agreement_no',
    'agreement_name',
    'tenant',
    'name',
    'title',
  ];
  static const _subtitleHints = ['date', 'status', 'address'];

  @override
  String get title =>
      _pickByKeyHint(raw, _titleHints) ??
      _firstPresentableField(raw) ??
      'Agreement';

  @override
  String? get subtitle => _pickByKeyHint(raw, _subtitleHints);

  @override
  String? get imageUrl => _pickImageUrl(raw);

  // Confirmed from the field app's Agreement_Form.dart/
  // Verification_form.dart (Aadhaar/owner/tenant photo fields).
  @override
  List<String> get imageBaseUrls => const [
        'https://verifyrealestateandservices.in/Second%20PHP%20FILE/main_application/agreement/',
      ];

  @override
  List<MapEntry<String, String>> get fields => _allFieldsExcept(
      raw, _usedKeys(raw, titleHints: _titleHints, subtitleHints: _subtitleHints));
}

// ---------------------------------------------------------------------
// 5. Insurance Details
// insurance_details.php?number=NUMBER
// ---------------------------------------------------------------------
class InsuranceRecord extends DataRecord {
  const InsuranceRecord(super.raw);

  factory InsuranceRecord.fromJson(Map<String, dynamic> json) =>
      InsuranceRecord(json);

  static const _titleHints = [
    'policy_name',
    'policy_no',
    'insurance_name',
    'name',
    'type',
  ];
  static const _subtitleHints = ['provider', 'company', 'status', 'expiry', 'date'];

  @override
  String get title =>
      _pickByKeyHint(raw, _titleHints) ??
      _firstPresentableField(raw) ??
      'Insurance Policy';

  @override
  String? get subtitle => _pickByKeyHint(raw, _subtitleHints);

  @override
  String? get imageUrl => _pickImageUrl(raw);

  // Confirmed from the field app's insurance_ui_kit.dart/
  // InsuranceShowListPage.dart (car/RC/Aadhaar/PAN/policy photo fields).
  @override
  List<String> get imageBaseUrls => const [
        'https://verifyrealestateandservices.in/Second%20PHP%20FILE/insurance/',
      ];

  @override
  List<MapEntry<String, String>> get fields => _allFieldsExcept(
      raw, _usedKeys(raw, titleHints: _titleHints, subtitleHints: _subtitleHints));
}

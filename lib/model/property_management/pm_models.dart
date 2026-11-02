import 'package:flutter/material.dart';

/// Property Management models - Owner + Tenant static-frontend build.
///
/// IMPORTANT: there is still NO backend/API behind any of this. Everything
/// here lives only in memory for the lifetime of the running app (held by
/// `PmStore`, see pm_store.dart) - closing/restarting the app resets all
/// added payments/tenants/vehicles/documents/maintenance requests/notices
/// back to the owner's original reference dataset. This is a deliberate,
/// temporary choice (per the "statically front end based" request) - when
/// a real Property Management API exists, PmStore's add/update methods
/// should be re-pointed at it instead of mutating these in-memory lists,
/// and this comment should be removed.
///
/// Every "unknown" value stays nullable and must never be defaulted to
/// 0/false - except figures that are genuinely a count of records added
/// in this demo session (e.g. "payments logged so far"), which legitimately
/// start at 0 and are always labeled "(demo)" in the UI to avoid being
/// mistaken for real accounting.

enum PmRole { owner, tenant }

enum FlatStatus { rented, vacant, selfUse }

enum MeterType { individualSubMeter, governmentMeter, unknown }

enum AttentionSeverity { info, warning, critical }

enum PaymentMethod { cash, bankTransfer, upi, other }

enum PaymentStatus { pending, confirmed }

enum MaintenanceStatus { open, inProgress, resolved }

enum NoticeStatus { pending, accepted, rejected }

enum NoticeRaisedBy { tenant, owner }

// --- New static sections: Agreement / Police Verification / Insurance /
// Utility bills - added per explicit owner request. Same rule as
// everywhere else in this model file: every field stays nullable and
// "not provided" until someone actually fills it in via a form - never
// defaulted/guessed.
enum AgreementStatus { notCreated, active, expired }

enum VerificationStatus { notSubmitted, pending, verified, rejected }

enum InsuranceStatus { none, active, expired }

enum UtilityType { electricity, water, gas, other }

class PmVehicle {
  final String type; // "Car", "Scooter", "Bike"
  final String? model; // null = not provided/guessed
  String? note;
  String? regNumber; // registration number - optional, filled via the Vehicle section
  String? color;

  PmVehicle({required this.type, this.model, this.note, this.regNumber, this.color});
}

class FamilyMember {
  final String name;
  final String relation; // e.g. "Spouse", "Son", "Daughter"
  final String? phone;

  FamilyMember({required this.name, required this.relation, this.phone});
}

class PmPayment {
  final int amount;
  final DateTime date;
  final PaymentMethod method;
  PaymentStatus status;
  final String? note;
  final bool reportedByTenant; // true = tenant self-reported, awaiting owner confirm

  PmPayment({
    required this.amount,
    required this.date,
    required this.method,
    this.status = PaymentStatus.confirmed,
    this.note,
    this.reportedByTenant = false,
  });
}

class PmExpense {
  final String title;
  final int amount;
  final DateTime date;

  PmExpense({required this.title, required this.amount, required this.date});
}

class PmDocument {
  final String title;
  final String type; // e.g. "Agreement", "Police Verification", "Insurance", "Other"
  final DateTime addedOn;
  final bool sharedWithTenant;

  PmDocument({
    required this.title,
    required this.type,
    required this.addedOn,
    this.sharedWithTenant = false,
  });
}

class PmMaintenanceRequest {
  final String title;
  final String description;
  final DateTime raisedOn;
  MaintenanceStatus status;
  final bool raisedByTenant;

  PmMaintenanceRequest({
    required this.title,
    required this.description,
    required this.raisedOn,
    this.status = MaintenanceStatus.open,
    this.raisedByTenant = false,
  });
}

class PmNotice {
  final DateTime proposedVacateDate;
  final String? reason;
  final NoticeRaisedBy raisedBy;
  final DateTime raisedOn;
  NoticeStatus status;

  PmNotice({
    required this.proposedVacateDate,
    this.reason,
    required this.raisedBy,
    required this.raisedOn,
    this.status = NoticeStatus.pending,
  });
}

class PmAgreement {
  DateTime? startDate;
  DateTime? endDate;
  int? securityDeposit;
  int? noticePeriodDays;
  String? terms;
  AgreementStatus status;

  PmAgreement({
    this.startDate,
    this.endDate,
    this.securityDeposit,
    this.noticePeriodDays,
    this.terms,
    this.status = AgreementStatus.notCreated,
  });
}

/// Manual tracking only - this does NOT call any real government/police
/// verification API (there is no backend yet). It is a static record the
/// owner fills in by hand to keep a note of where verification stands.
class PmPoliceVerification {
  String? idType; // e.g. Aadhaar, Passport, Voter ID, Driving Licence
  String? idNumber; // free text, never validated against any real registry
  DateTime? submittedOn;
  DateTime? verifiedOn;
  VerificationStatus status;
  String? remarks;

  PmPoliceVerification({
    this.idType,
    this.idNumber,
    this.submittedOn,
    this.verifiedOn,
    this.status = VerificationStatus.notSubmitted,
    this.remarks,
  });
}

class PmInsurancePolicy {
  String? provider;
  String? policyNumber;
  DateTime? validTill;
  InsuranceStatus status;
  String? note;

  PmInsurancePolicy({
    this.provider,
    this.policyNumber,
    this.validTill,
    this.status = InsuranceStatus.none,
    this.note,
  });
}

/// One meter-reading / bill log entry. Either owner or tenant can add one
/// (reportedByTenant flags which) - this is a shared log, not a
/// confirm/dispute flow like rent payments.
class PmUtilityRecord {
  final UtilityType type;
  final DateTime date;
  final double? meterReading;
  final int? billAmount;
  final String? note;
  final bool reportedByTenant;

  PmUtilityRecord({
    required this.type,
    required this.date,
    this.meterReading,
    this.billAmount,
    this.note,
    this.reportedByTenant = false,
  });
}

class PmFlat {
  final String flatNo;
  final String floorLabel;
  final String? bhk;
  String? tenantName; // mutable - owner/tenant can update
  String? tenantPhone; // mutable - owner/tenant can update; null until provided, never guessed
  int? monthlyRent; // null = unknown; NOT 0. null for vacant flats.
  FlatStatus status;
  final List<PmVehicle> vehicles;
  int? askingRent; // only meaningful when status == vacant
  final bool? furnished;
  final List<FamilyMember> familyMembers;
  final List<PmPayment> payments;
  final List<PmDocument> documents;
  final List<PmMaintenanceRequest> maintenanceRequests;
  PmNotice? notice;
  PmAgreement? agreement;
  PmPoliceVerification? policeVerification;
  PmInsurancePolicy? insurance;
  final List<PmUtilityRecord> utilityRecords;

  PmFlat({
    required this.flatNo,
    required this.floorLabel,
    this.bhk,
    this.tenantName,
    this.tenantPhone,
    this.monthlyRent,
    required this.status,
    List<PmVehicle>? vehicles,
    this.askingRent,
    this.furnished,
    List<FamilyMember>? familyMembers,
    List<PmPayment>? payments,
    List<PmDocument>? documents,
    List<PmMaintenanceRequest>? maintenanceRequests,
    this.notice,
    this.agreement,
    this.policeVerification,
    this.insurance,
    List<PmUtilityRecord>? utilityRecords,
  })  : vehicles = vehicles ?? <PmVehicle>[],
        familyMembers = familyMembers ?? <FamilyMember>[],
        payments = payments ?? <PmPayment>[],
        documents = documents ?? <PmDocument>[],
        maintenanceRequests = maintenanceRequests ?? <PmMaintenanceRequest>[],
        utilityRecords = utilityRecords ?? <PmUtilityRecord>[];

  /// Sum of CONFIRMED payments logged against this flat in this demo
  /// session. Starts at 0 (a true "nothing logged yet" count, not a
  /// guessed amount) and only grows as payments are added/confirmed.
  int get recordedReceived => payments
      .where((p) => p.status == PaymentStatus.confirmed)
      .fold<int>(0, (sum, p) => sum + p.amount);

  int get pendingConfirmation => payments
      .where((p) => p.status == PaymentStatus.pending)
      .fold<int>(0, (sum, p) => sum + p.amount);
}

class PmBuilding {
  final String name;
  String? caretaker;
  bool? hasLift;
  MeterType meterType;
  double? subMeterRatePerUnit;
  int? parkingCapacity;
  final List<PmFlat> flats;
  final List<PmExpense> expenses;

  PmBuilding({
    required this.name,
    this.caretaker,
    this.hasLift,
    this.meterType = MeterType.unknown,
    this.subMeterRatePerUnit,
    this.parkingCapacity,
    List<PmFlat>? flats,
    List<PmExpense>? expenses,
  })  : flats = flats ?? <PmFlat>[],
        expenses = expenses ?? <PmExpense>[];

  int get unitCount => flats.length;

  int get rentedCount =>
      flats.where((f) => f.status == FlatStatus.rented).length;

  int get vacantCount =>
      flats.where((f) => f.status == FlatStatus.vacant).length;

  int get selfUseCount =>
      flats.where((f) => f.status == FlatStatus.selfUse).length;

  /// Sum of monthly rent for RENTED flats only. Self-use flats never
  /// contribute (a self-use property must never generate a rent charge).
  int get scheduledRent => flats
      .where((f) => f.status == FlatStatus.rented)
      .fold<int>(0, (sum, f) => sum + (f.monthlyRent ?? 0));

  int get vacantAskingRentTotal => flats
      .where((f) => f.status == FlatStatus.vacant)
      .fold<int>(0, (sum, f) => sum + (f.askingRent ?? 0));

  int get vehicleCount =>
      flats.fold<int>(0, (sum, f) => sum + f.vehicles.length);

  int get recordedReceived =>
      flats.fold<int>(0, (sum, f) => sum + f.recordedReceived);

  int get pendingConfirmation =>
      flats.fold<int>(0, (sum, f) => sum + f.pendingConfirmation);

  int get expenseTotal =>
      expenses.fold<int>(0, (sum, e) => sum + e.amount);
}

class PmAttentionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final AttentionSeverity severity;

  const PmAttentionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.severity = AttentionSeverity.info,
  });
}

class PmPortfolio {
  final String ownerName;
  final List<PmBuilding> buildings;

  PmPortfolio({required this.ownerName, List<PmBuilding>? buildings})
      : buildings = buildings ?? <PmBuilding>[];

  int get buildingCount => buildings.length;

  int get unitCount => buildings.fold<int>(0, (sum, b) => sum + b.unitCount);

  int get rentedCount =>
      buildings.fold<int>(0, (sum, b) => sum + b.rentedCount);

  int get vacantCount =>
      buildings.fold<int>(0, (sum, b) => sum + b.vacantCount);

  int get selfUseCount =>
      buildings.fold<int>(0, (sum, b) => sum + b.selfUseCount);

  int get scheduledRentTotal =>
      buildings.fold<int>(0, (sum, b) => sum + b.scheduledRent);

  int get vacantAskingRentTotal =>
      buildings.fold<int>(0, (sum, b) => sum + b.vacantAskingRentTotal);

  int get vehicleCount =>
      buildings.fold<int>(0, (sum, b) => sum + b.vehicleCount);

  int get recordedReceived =>
      buildings.fold<int>(0, (sum, b) => sum + b.recordedReceived);

  int get pendingConfirmation =>
      buildings.fold<int>(0, (sum, b) => sum + b.pendingConfirmation);

  /// All vacant flats across the portfolio, paired with their building,
  /// used to build honest Attention-Needed items (never fabricated).
  List<MapEntry<PmBuilding, PmFlat>> get vacantFlats {
    final out = <MapEntry<PmBuilding, PmFlat>>[];
    for (final b in buildings) {
      for (final f in b.flats) {
        if (f.status == FlatStatus.vacant) out.add(MapEntry(b, f));
      }
    }
    return out;
  }

  List<MapEntry<PmBuilding, PmFlat>> get openMaintenanceRequests {
    final out = <MapEntry<PmBuilding, PmFlat>>[];
    for (final b in buildings) {
      for (final f in b.flats) {
        if (f.maintenanceRequests.any((r) => r.status != MaintenanceStatus.resolved)) {
          out.add(MapEntry(b, f));
        }
      }
    }
    return out;
  }

  List<MapEntry<PmBuilding, PmFlat>> get pendingNotices {
    final out = <MapEntry<PmBuilding, PmFlat>>[];
    for (final b in buildings) {
      for (final f in b.flats) {
        if (f.notice != null && f.notice!.status == NoticeStatus.pending) {
          out.add(MapEntry(b, f));
        }
      }
    }
    return out;
  }
}

/// Small helpers shared across Property Management screens.
String pmFormatInr(int value) {
  final isNegative = value < 0;
  final s = value.abs().toString();
  String grouped;
  if (s.length <= 3) {
    grouped = s;
  } else {
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    var i = rest.length;
    while (i > 2) {
      parts.insert(0, rest.substring(i - 2, i));
      i -= 2;
    }
    if (i > 0) parts.insert(0, rest.substring(0, i));
    grouped = '${parts.join(',')},$last3';
  }
  return '${isNegative ? '-' : ''}₹$grouped';
}

String pmPaymentMethodLabel(PaymentMethod m) {
  switch (m) {
    case PaymentMethod.cash:
      return 'Cash';
    case PaymentMethod.bankTransfer:
      return 'Bank Transfer';
    case PaymentMethod.upi:
      return 'UPI';
    case PaymentMethod.other:
      return 'Other';
  }
}

String pmMeterLabel(MeterType type) {
  switch (type) {
    case MeterType.individualSubMeter:
      return 'Individual sub-meter';
    case MeterType.governmentMeter:
      return 'Government/discom meter';
    case MeterType.unknown:
      return 'Meter type not provided';
  }
}

String pmDateLabel(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

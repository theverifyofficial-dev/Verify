import 'package:flutter/material.dart';
import '../../model/property_management/pm_models.dart';

/// User-provided reference data - NOT synced to any backend.
/// For local UI preview/testing only (Property Management - Milestone 1).
///
/// Source: the owner (Pankaj Khari) gave this data directly in chat as his
/// real portfolio, explicitly to be used as mock/sample fixture data while
/// the Property Management screens are being previewed. It has been
/// cross-checked for internal arithmetic consistency (each building's
/// per-flat rent sums match the owner's stated building/portfolio totals;
/// vehicle counts match the owner's stated combined totals) but it has NOT
/// been entered into, or verified against, any backend, and must never be
/// auto-imported into a real account/production database.
///
/// Anything the owner did not state is left `null` / "not provided" below
/// - it is never guessed or defaulted to zero or false. Known gaps across
/// both buildings: no payment receipts, due dates, arrears, deposits,
/// agreement dates, PV records, CA numbers, meter readings, tenant phone
/// numbers, vehicle registration numbers, or insurance dates were provided.

final pmReferencePortfolio = PmPortfolio(
  ownerName: 'Pankaj Khari',
  buildings: [
    // -----------------------------------------------------------------
    // Building 1 - Numberdar Apartments (9 flats, 9/9 occupied)
    // Scheduled rent: 8,000+19,000+8,000+9,000+11,000+14,000+8,500+8,500
    //                +16,000 = 1,02,000 (matches owner's stated total)
    // -----------------------------------------------------------------
    PmBuilding(
      name: 'Numberdar Apartments',
      caretaker: 'Chhotu',
      hasLift: false,
      meterType: MeterType.individualSubMeter,
      subMeterRatePerUnit: 8,
      flats: [
        PmFlat(
          flatNo: '1',
          floorLabel: 'Ground',
          bhk: '1BHK',
          tenantName: 'Pankaj',
          monthlyRent: 8000,
          status: FlatStatus.rented,
        ),
        PmFlat(
          flatNo: '101',
          floorLabel: 'First',
          bhk: '2BHK',
          tenantName: 'Akshay',
          monthlyRent: 19000,
          status: FlatStatus.rented,
          vehicles: [
            PmVehicle(type: 'Scooter'),
            PmVehicle(type: 'Car', model: 'Kia'),
          ],
        ),
        PmFlat(
          flatNo: '102',
          floorLabel: 'First',
          bhk: '1BHK',
          tenantName: 'Sujeet',
          monthlyRent: 8000,
          status: FlatStatus.rented,
        ),
        PmFlat(
          flatNo: '103',
          floorLabel: 'First',
          bhk: '1BHK',
          tenantName: 'Mukesh',
          monthlyRent: 9000,
          status: FlatStatus.rented,
          vehicles: [PmVehicle(type: 'Scooter')],
        ),
        PmFlat(
          flatNo: '104',
          floorLabel: 'First',
          bhk: '1BHK',
          tenantName: null, // tenant name not provided by owner
          monthlyRent: 11000,
          status: FlatStatus.rented,
        ),
        PmFlat(
          flatNo: '401',
          floorLabel: 'Fourth',
          bhk: '2BHK',
          tenantName: 'Akhilesh',
          monthlyRent: 14000,
          status: FlatStatus.rented,
          vehicles: [PmVehicle(type: 'Car', model: 'Brezza')],
        ),
        PmFlat(
          flatNo: '402',
          floorLabel: 'Fourth',
          bhk: '1BHK',
          tenantName: 'Ankita',
          monthlyRent: 8500,
          status: FlatStatus.rented,
        ),
        PmFlat(
          flatNo: '403',
          floorLabel: 'Fourth',
          bhk: '1BHK',
          tenantName: 'Mukesh & Manoj',
          monthlyRent: 8500,
          status: FlatStatus.rented,
          vehicles: [PmVehicle(type: 'Bike', model: 'Avenger')],
        ),
        PmFlat(
          flatNo: '404',
          floorLabel: 'Fourth',
          bhk: '1BHK',
          tenantName: 'Sunita',
          monthlyRent: 16000,
          status: FlatStatus.rented,
          furnished: true,
          // No bike; car info not provided by owner - left empty, never guessed.
        ),
      ],
    ),

    // -----------------------------------------------------------------
    // Building 2 - Numberdar Apartments 2 (10 flats, 9/10 occupied)
    // Scheduled rent: 23,000+20,000+23,000+23,000+20,000+22,000+23,500
    //                +23,500+26,000 = 2,04,000 (matches owner's stated
    //                total). Flat 404 is vacant (asking 26,000) and is
    //                excluded from this figure - see vacantAskingRentTotal.
    // -----------------------------------------------------------------
    PmBuilding(
      name: 'Numberdar Apartments 2',
      caretaker: 'Arif',
      hasLift: true,
      meterType: MeterType.governmentMeter,
      // Parking is "available" per the owner but exact capacity was not
      // provided - left null rather than guessed.
      flats: [
        PmFlat(
          flatNo: '101',
          floorLabel: 'First',
          bhk: '2BHK',
          tenantName: 'Shruti',
          monthlyRent: 23000,
          status: FlatStatus.rented,
          vehicles: [PmVehicle(type: 'Car', model: 'Innova')],
        ),
        PmFlat(
          flatNo: '102',
          floorLabel: 'First',
          bhk: '2BHK',
          tenantName: 'Vikas Saxena',
          monthlyRent: 20000,
          status: FlatStatus.rented,
          vehicles: [PmVehicle(type: 'Car', model: 'Alto')],
        ),
        PmFlat(
          flatNo: '103',
          floorLabel: 'First',
          bhk: '2BHK',
          tenantName: 'Amrita',
          monthlyRent: 23000,
          status: FlatStatus.rented,
        ),
        PmFlat(
          flatNo: '104',
          floorLabel: 'First',
          bhk: '2BHK',
          tenantName: 'Vinay',
          monthlyRent: 23000,
          status: FlatStatus.rented,
          vehicles: [
            PmVehicle(
              type: 'Car',
              model: 'Maruti Vitara',
              note: 'exact variant pending',
            ),
          ],
        ),
        PmFlat(
          flatNo: '105',
          floorLabel: 'First',
          bhk: '2BHK',
          tenantName: 'Shanky',
          monthlyRent: 20000,
          status: FlatStatus.rented,
          vehicles: [PmVehicle(type: 'Car', model: 'Nexon')],
        ),
        PmFlat(
          flatNo: '401',
          floorLabel: 'Fourth',
          bhk: '2BHK',
          tenantName: 'Saxena',
          monthlyRent: 22000,
          status: FlatStatus.rented,
          vehicles: [
            PmVehicle(type: 'Car', note: 'Honda - exact model not provided'),
            PmVehicle(type: 'Bike', model: 'Bullet'),
          ],
        ),
        PmFlat(
          flatNo: '402',
          floorLabel: 'Fourth',
          bhk: '2BHK',
          tenantName: 'Anoop',
          monthlyRent: 23500,
          status: FlatStatus.rented,
        ),
        PmFlat(
          flatNo: '403',
          floorLabel: 'Fourth',
          bhk: '2BHK',
          tenantName: 'Tomar',
          monthlyRent: 23500,
          status: FlatStatus.rented,
        ),
        PmFlat(
          flatNo: '404',
          floorLabel: 'Fourth',
          bhk: '2BHK',
          tenantName: null,
          monthlyRent: null, // vacant - must never generate a rent charge
          status: FlatStatus.vacant,
          askingRent: 26000,
        ),
        PmFlat(
          flatNo: '405',
          floorLabel: 'Fourth',
          bhk: '2BHK',
          tenantName: 'Samim',
          monthlyRent: 26000,
          status: FlatStatus.rented,
          furnished: true,
        ),
      ],
    ),
  ],
);

/// Attention Needed items for Milestone 1 - limited strictly to facts the
/// owner actually stated. Nothing here is derived from an unknown date
/// (working rule: never fabricate an alert from a missing date).
final List<PmAttentionItem> pmReferenceAttentionItems = [
  const PmAttentionItem(
    icon: Icons.meeting_room_outlined,
    title: '1 flat is vacant',
    subtitle: 'Numberdar Apartments 2 - Flat 404 - Asking ₹26,000/mo',
    actionLabel: 'View flat',
    severity: AttentionSeverity.warning,
  ),
  const PmAttentionItem(
    icon: Icons.receipt_long_outlined,
    title: 'Payment records not added yet',
    subtitle: 'Received / Pending / Overdue amounts will show here once '
        'payment records are added - not calculated yet.',
    actionLabel: 'Add payment',
    severity: AttentionSeverity.info,
  ),
];
